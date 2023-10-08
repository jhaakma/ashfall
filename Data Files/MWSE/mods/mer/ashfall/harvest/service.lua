local common = require("mer.ashfall.common.common")
local skillsConfig = require("mer.ashfall.config.skillConfigs")
local logger = common.createLogger("harvestService")
local config = require("mer.ashfall.config").config
local harvestConfigs = require("mer.ashfall.harvest.config")
local ReferenceController = require("mer.ashfall.referenceController")
local ActivatorController = require("mer.ashfall.activators.activatorController")

---@class Ashfall.HarvestService
local HarvestService = {}

HarvestService.destroyedHarvestables = ReferenceController.registerReferenceController{
    id = "destroyedHarvestable",
    ---@param self any
    ---@param ref tes3reference
    requirements = function(self, ref)
        return (ref.data and ref.data.ashfallDestroyedHarvestable)
    end
}


local MAX_WEAPON_DAMAGE = 50

function HarvestService.checkIllegalToHarvest()
    return config.illegalHarvest
        and tes3.player.cell.restingIsIllegal
end

function HarvestService.checkHarvested(reference)
    return reference.data.ashfallDestroyedHarvestable == true
end

---@param harvestConfig Ashfall.Harvest.Config
function HarvestService.showIllegalToHarvestMessage(harvestConfig)
    tes3.messageBox("You must be in the wilderness to harvest.")
end

---@class Ashfall.HarvestService.getCurrentHarvestData.params
---@field ignoreAttackDirection? boolean If true, will ignore the attack direction check
---@field showIllegalToHarvestMessage? boolean If true, will show a message if it's illegal to harvest

--Get the config for the current harvestable
---@return Ashfall.Harvest.CurrentHarvestData|nil
---@param e Ashfall.HarvestService.getCurrentHarvestData.params|nil
function HarvestService.getCurrentHarvestData(e)
    e = e or {}
    --Get player target Activator
    local activator = ActivatorController.getCurrentActivator()
    if not activator then
        logger:trace("Harvest: No activator")
        return
    end
    --Get activator Ref
    local reference = ActivatorController.getCurrentActivatorReference()
    if not reference then
        logger:debug("Harvest: No reference")
        return
    end
    --Get harvest config from activator
    ---@type Ashfall.Harvest.Config
    local harvestConfig = harvestConfigs.activatorHarvestData[activator.type]
    if not harvestConfig then
        logger:trace("Harvest: No harvest config")
        return
    end
    --Get player Weapon
    local weapon = tes3.player.mobile.readiedWeapon
    if not weapon then
        logger:debug("Harvest: No weapon")
        return
    end
    --Get harvest data from weapon
    local weaponData = HarvestService.getWeaponHarvestData(weapon, harvestConfig)
    if not weaponData then
        logger:debug("Harvest: No weapon data")
        return
    end
    --Check if Activator is active
    local activatorActive = config[activator.mcmSetting] ~= false
    if not activatorActive then
        logger:debug("Harvest: Activator not active")
        return
    end
    --Return if illegal to harvest
    if HarvestService.checkIllegalToHarvest() then
        if e.showIllegalToHarvestMessage then
            HarvestService.showIllegalToHarvestMessage(harvestConfig)
        end
        logger:debug("Harvest: Illegal to harvest")
        return
    end
    if not e.ignoreAttackDirection then
        --Check attack direction
        if not HarvestService.validAttackDirection(harvestConfig) then
            logger:debug("Harvest: Invalid attack direction")
            return
        end
    end
    --Check if activator is already harvested
    if HarvestService.checkHarvested(reference) then
        logger:debug("Harvest: Can't harvest, already harvested")
        return
    end
    --All checks pass, return the harvest data
    local currentHarvestData = {
        reference = reference,
        activator = activator,
        harvestConfig = harvestConfig,
        weapon = weapon,
        weaponData = weaponData
    }
    return currentHarvestData
end


---@param weapon tes3equipmentStack
---@param harvestConfig Ashfall.Harvest.Config
---@return Ashfall.Harvest.WeaponData | nil
function HarvestService.getWeaponHarvestData(weapon, harvestConfig)

    --check requirements
    if harvestConfig.requirements then
        if not harvestConfig.requirements(weapon) then
            return
        end
    end

    --Exact IDs
    local weaponDataFromId = harvestConfig.weaponIds
        and harvestConfig.weaponIds[weapon.object.id:lower()]
    if weaponDataFromId then
        return weaponDataFromId
    end

    --Pattern match on name
    local weaponDataFromName
    if harvestConfig.weaponNamePatterns then
        for pattern, data in pairs(harvestConfig.weaponNamePatterns) do
            if string.match(weapon.object.name:lower(), pattern) then
                weaponDataFromName = data
                --cache this weapon
                harvestConfig.weaponIds[weapon.object.id:lower()] = data
                break
            end
        end
    end
    if weaponDataFromName then
        return weaponDataFromName
    end

    --Weapon Type
    local weaponTypeData = harvestConfig.weaponTypes
        and harvestConfig.weaponTypes[weapon.object.type]
    if weaponTypeData then
        return weaponTypeData
    end
end

function HarvestService.getAttackDirection()
    return tes3.mobilePlayer.actionData.attackDirection ---@diagnostic disable-line
end

function HarvestService.validAttackDirection(harvestConfig)
    local attackDirection = HarvestService.getAttackDirection()
    return harvestConfig.attackDirections[attackDirection]
end

---@param weapon tes3equipmentStack
---@return number damageEffect
function HarvestService.getDamageEffect(weapon)
    local attackDirection = HarvestService.getAttackDirection()
    local maxField = harvestConfigs.attackDirectionMapping[attackDirection].max
    local maxDamage = weapon.object[maxField]
    logger:trace("maxDamage: %s", maxDamage)
    local cappedDamage = math.min(maxDamage, MAX_WEAPON_DAMAGE)
    logger:trace("cappedDamage: %s", cappedDamage)
    return 1 + (cappedDamage / MAX_WEAPON_DAMAGE)
end

---@param weapon tes3equipmentStack
---@param weaponData Ashfall.Harvest.WeaponData
---@return number
function HarvestService.getSwingStrength(weapon, weaponData)
    local attackSwing = tes3.player.mobile.actionData.attackSwing
    logger:trace("attackSwing: %s", attackSwing)
    local effectiveness = weaponData.effectiveness or 1.0
    logger:trace("effectiveness: %s", effectiveness)
    local damageEffect = HarvestService.getDamageEffect(weapon)
    logger:trace("damageEffect: %s", damageEffect)
    --Calculate Swing Strength
    local swingStrength = attackSwing * effectiveness * damageEffect
    logger:trace("swingStrength: %s", swingStrength)
    return swingStrength
end

function HarvestService.getCurrentSwings(reference)
    return reference.tempData.ashfallHarvestSwings or 0
end

function HarvestService.getSwingsNeeded(reference, harvestSwingsNeeded)
    local swingsNeeded = reference.tempData.ashfallSwingsNeeded
    if harvestSwingsNeeded and not swingsNeeded then
        HarvestService.setSwingsNeeded(reference, harvestSwingsNeeded)
        swingsNeeded = reference.tempData.ashfallSwingsNeeded
    end
    return swingsNeeded
end

function HarvestService.setSwingsNeeded(reference, harvestSwingsNeeded)
    reference.tempData.ashfallSwingsNeeded = math.random(harvestSwingsNeeded, harvestSwingsNeeded + 2)
end

---@param swingStrength number
---@param reference tes3reference
---@param swingsNeeded number
---@return boolean isHarvested
function HarvestService.attemptSwing(swingStrength, reference, swingsNeeded)
    local swingsNeeded = HarvestService.getSwingsNeeded(reference, swingsNeeded)
    reference.tempData.ashfallHarvestSwings = HarvestService.getCurrentSwings(reference)
    local swings = reference.tempData.ashfallHarvestSwings + swingStrength
    logger:debug("swings before: %s", reference.tempData.ashfallHarvestSwings)
    logger:debug("swingStrength: %s", swingStrength)
    logger:debug("swings after: %s", swings)
    logger:debug("swingsNeeded: %s", swingsNeeded)
    local isHarvested = swings >= swingsNeeded
    reference.tempData.ashfallHarvestSwings = swings
    logger:debug("isHarvested: %s", isHarvested)
    return isHarvested
end

---@param reference tes3reference
function HarvestService.resetSwings(reference)
    reference.tempData.ashfallHarvestSwings = 0
    reference.tempData.ashfallSwingsNeeded = nil
end

---@param weapon tes3equipmentStack
---@param swingStrength number
---@param degradeMulti number default: 1
function HarvestService.degradeWeapon(weapon, swingStrength, degradeMulti)
    degradeMulti = degradeMulti or 1.0
    logger:trace("degrade multiplier: %s", degradeMulti)
    --Weapon degradation
    weapon.itemData.condition = weapon.itemData.condition - (4 * swingStrength * degradeMulti)
    --weapon is broken, unequip
    if weapon.itemData.condition <= 0 then
        weapon.itemData.condition = 0
        tes3.mobilePlayer:unequip{ type = tes3.objectType.weapon }
        return true
    end
    return false
end

function HarvestService.playSound(harvestConfig)
    tes3.playSound({reference=tes3.player, soundPath = harvestConfig.sound})
end


function HarvestService.calcNumHarvested(harvestable)
    --if skills are implemented, use Survival Skill
    local survivalSkill = math.clamp(common.skills.survival.current, 0, 100)
    local survivalMulti = math.remap(survivalSkill, 10, 100, 0.25, 1)
    local min = 1
    local max = math.ceil(harvestable.count * survivalMulti)
    local numHarvested = math.random(min, max)
    return numHarvested
end

---@param numHarvested number
---@param harvestName string
function HarvestService.showHarvestedMessage(numHarvested, harvestName)
    local message = string.format("You harvest %s %s of %s", numHarvested, numHarvested > 1 and "pieces" or "piece", harvestName)
    tes3.messageBox(message)
end

---@param harvestConfig Ashfall.Harvest.Config
---@return number numHarvested The number of items that were harvested from the reference
function HarvestService.addItems(harvestConfig)
    local roll = math.random()
    logger:trace("Roll: %s", roll)
    ---@param harvestable Ashfall.Harvest.Config.Harvestable
    for _, harvestable in ipairs(harvestConfig.items) do
        local chance = harvestable.chance
        logger:trace("Chance: %s", chance)
        if roll <= chance then
            logger:trace("Adding %s", harvestable.id)
            tes3.playSound({reference=tes3.player, sound="Item Misc Up"})
            local numHarvested = HarvestService.calcNumHarvested(harvestable)
            tes3.addItem{reference=tes3.player, item= harvestable.id, count=numHarvested, playSound = false}
            HarvestService.showHarvestedMessage(numHarvested, tes3.getObject(harvestable.id).name)
            event.trigger("Ashfall:triggerPackUpdate")
            return numHarvested
        end
        roll = roll - harvestable.chance
    end
    return 0
end



---@param reference tes3reference
---@param harvestConfig Ashfall.Harvest.Config
---@return number numHarvested The number of items that were harvested from the reference
function HarvestService.harvest(reference, harvestConfig)
    HarvestService.resetSwings(reference)
    common.skills.survival:exercise(harvestConfig.swingsNeeded * skillsConfig.survival.harvest.gainPerSwing)
    local numHarvested = HarvestService.addItems(harvestConfig)
    tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
    HarvestService.updateTotalHarvested(reference, numHarvested)
    return numHarvested
end

function HarvestService.updateTotalHarvested(reference, numHarvested)
    reference.data.ashfallTotalHarvested = reference.data.ashfallTotalHarvested or 0
    reference.data.ashfallTotalHarvested = reference.data.ashfallTotalHarvested + numHarvested
    logger:trace("Added %s to total harvested, new total: %s", numHarvested, reference.data.ashfallTotalHarvested)
end

function HarvestService.getTotalHarvested(reference)
    return reference.data.ashfallTotalHarvested or 0
end

function HarvestService.setDestructionLimit(reference, limit)
    reference.data.ashfallDestructionLimitConfig = limit
    reference.modified = true
end

function HarvestService.getDestructionLimit(reference)
    return reference.data.ashfallDestructionLimitConfig
end

---@param reference tes3reference
---@param destructionLimitConfig Ashfall.Harvest.Config.DestructionLimitConfig
function HarvestService.getSetDestructionLimit(reference, destructionLimitConfig)
    if not reference.data.ashfallDestructionLimitConfig then
        local height = HarvestService.getRefHeight(reference)
        local minIn = destructionLimitConfig.minHeight
        local maxIn = destructionLimitConfig.maxHeight
        local minOut = destructionLimitConfig.min
        local maxOut = destructionLimitConfig.max
        local limit = math.remap(height, minIn, maxIn, minOut, maxOut)
        limit = math.clamp(limit, minOut, maxOut)
        limit = math.ceil(limit)
        logger:debug("Ref height: %s", height)
        logger:debug("Set destruction limit to %s", limit)
        HarvestService.setDestructionLimit(reference, limit)
    end
    return reference.data.ashfallDestructionLimitConfig
end

---@param reference tes3reference
function HarvestService.getRefHeight(reference)
    return (reference.object.boundingBox.max.z - reference.object.boundingBox.min.z) * reference.scale
end

---@param reference tes3reference
---@param destructionLimit number
function HarvestService.isExhausted(reference, destructionLimit)
    local totalHarvested = HarvestService.getTotalHarvested(reference)
    return totalHarvested >= destructionLimit
end

---@param reference tes3reference
---@param harvestConfig Ashfall.Harvest.Config
function HarvestService.disableExhaustedHarvestable(reference, harvestConfig)
    local destructionLimitConfig = harvestConfig.destructionLimitConfig
    if not destructionLimitConfig then return end
    local destructionLimit = HarvestService.getSetDestructionLimit(reference, destructionLimitConfig)
    if HarvestService.isExhausted(reference, destructionLimit) then
        local harvestableHeight = HarvestService.getRefHeight(reference)
        HarvestService.disableHarvestable(reference, harvestableHeight, harvestConfig)
        if harvestConfig.fallSound then
            tes3.playSound{ sound = harvestConfig.fallSound}
        end
        if harvestConfig.clutter then
            HarvestService.disableNearbyRefs(reference, harvestConfig, harvestableHeight)
        end
    end
end



function HarvestService.enableHarvestable(reference)
    logger:debug("Enabling Disabled Harvestable: %s", reference.id)
    --reset nodes
    for _, nodeName in ipairs{"ASHFALL_TREEFALL", "ASHFALL_STUMP"} do
        local node = reference.sceneNode:getObjectByName(nodeName)
        if node then
            local parent = node.parent
            parent:detachChild(node)
            local originalNode = tes3.loadMesh(reference.object.mesh, false):getObjectByName(nodeName)
            parent:attachChild(originalNode)
            originalNode.appCulled = false
            parent:update()
        end
    end
    if reference.data and reference.data.ashfallHarvestOriginalLocation then
        logger:debug("Reseting location of %s", reference)
        tes3.positionCell{
            reference = reference,
            cell = reference.cell,
            position = reference.data.ashfallHarvestOriginalLocation.position,
            orientation = reference.data.ashfallHarvestOriginalLocation.orientation,
        }
    end
    reference:enable()
    --reference.hasNoCollision = false
    reference.data.ashfallDestroyedHarvestable = nil
end


function HarvestService.updateDisabledHarvestables()
    HarvestService.destroyedHarvestables:iterate(function(reference)
        if reference.position:distance(tes3.player.position) > (8192/2) then
            HarvestService.enableHarvestable(reference)
        end
    end)
end



function HarvestService.disableNearbyRefs(harvestableRef, harvestConfig, harvestableHeight)
    logger:debug("disabling nearby refs for %s", harvestableRef)
    local ignoreList = {}
    for _, cell in ipairs(tes3.getActiveCells()) do
        ---@param ref tes3reference
        for ref in cell:iterateReferences() do
            local isValid = ref ~= harvestableRef
                and harvestConfig.clutter
                and harvestConfig.clutter[ref.baseObject.id:lower()]
            if isValid then
                logger:trace("%s", ref.id)
                if common.helper.getCloseEnough({ref1 = ref, ref2 = harvestableRef, distHorizontal = 500, distVertical = 2000}) then
                    logger:debug("close enough, disabling %s", ref.id)
                    HarvestService.disableHarvestable(ref, harvestableHeight, harvestConfig)
                    table.insert(ignoreList, ref)
                end
            end
        end
    end
    for _, cell in ipairs(tes3.getActiveCells()) do
        ---@param ref tes3reference
        for ref in cell:iterateReferences() do
            local activator = ActivatorController.getRefActivator(ref)
            local isValid = ref ~= harvestableRef
                and not (harvestConfig.clutter and harvestConfig.clutter[ref.baseObject.id:lower()])
                and not (activator and activator.type == "woodSource")
                and (ref.baseObject.objectType ~= tes3.objectType.static)
            if isValid then
                --Drop nearby loot
                if common.helper.getCloseEnough({ref1 = ref, ref2 = harvestableRef, distHorizontal = 150, distVertical = 2000, rootHeight = 100}) then
                    logger:debug("Found nearby %s", ref)
                    local result = common.helper.getGroundBelowRef{
                        doLog = false,
                        ref = ref,
                        ignoreList = ignoreList,
                        maxDistance = 2000
                    }
                    local refBelow = result and result.reference
                    logger:debug("%s", result and result.reference)
                    if refBelow == harvestableRef then
                        local localIgnoreList = table.copy(ignoreList, {})
                        table.insert(localIgnoreList, harvestableRef)
                        logger:debug("Thing is indeed sitting on stump, orienting %s to ground", ref)
                        if ref.supportsLuaData and common.helper.getStackCount(ref) <= 1 then
                            logger:debug("adding to list of destroyedHarvestables")
                            ref.data.ashfallDestroyedHarvestable = true
                            ref.data.ashfallHarvestOriginalLocation = {
                                position = {
                                    ref.position.x,
                                    ref.position.y,
                                    ref.position.z
                                },
                                orientation = {
                                    ref.orientation.x,
                                    ref.orientation.y,
                                    ref.orientation.z,
                                }
                            }
                            HarvestService.destroyedHarvestables:addReference(ref)
                        end
                        common.helper.orientRefToGround{
                            ref = ref,
                            ignoreList = localIgnoreList,
                            rootHeight = 50
                        }
                    end
                end
            end
        end
    end
end

---@param reference tes3reference
---@param harvestableHeight number
function HarvestService.disableHarvestable(reference, harvestableHeight, harvestConfig)
    logger:debug("Disabling harvestable %s", reference)
    reference.data.ashfallTotalHarvested = nil
    reference.data.ashfallDestructionLimitConfig = nil
    HarvestService.demolish{
        reference = reference,
        harvestableHeight = harvestableHeight,
        fallSpeed = harvestConfig.fallSpeed,
    }
end

local m1 = tes3matrix33.new()
local m2 = tes3matrix33.new()
local m3 = tes3matrix33.new()

---@param reference tes3reference
---@param currentTime number
---@param totalTime number
---@param playerZ number
---@param acceleration number
---@param node niNode **Optional** if not provided, will rotate reference
function HarvestService.rotateNodeAwayFromPlayer(reference, currentTime, totalTime, playerZ, acceleration, node)

    local refZ = reference.orientation.z
    local rotZ = playerZ - refZ + 90
    if node then
        local u = 0
        local t = currentTime/totalTime
        local v = u + acceleration * t
        local rotation = 30 / (totalTime) * v

        local rotX = rotation * math.sin(rotZ)
        local rotY = rotation * math.cos(rotZ)
        m1:toRotationX(math.rad(rotX))
        m2:toRotationY(math.rad(rotY))
        node.rotation = node.rotation * m1:copy() * m2:copy()
        node:update()
    end
end

function HarvestService.animateFellNode(e)
    if e.safeRef:valid() then
        if e.fellNode then --rotate fell node
            HarvestService.rotateNodeAwayFromPlayer(e.reference, e.currentIteration, e.iterations, e.playerZ, 10, e.fellNode)
        end
        if e.stumpNode then --lower stump node
            local a = 4
            local u = 0
            local t = e.currentIteration/e.iterations
            local v = u + a * t
           e. stumpNode.translation = e.stumpNode.translation + tes3vector3.new(0, 0, -(100/e.iterations)*v)
            e.stumpNode:update()
        end
        e.currentIteration = e.currentIteration + 1
    end
end

function HarvestService.animateDefault(e)
    if e.safeRef:valid() then
        local ref = e.safeRef:getObject()
        tes3.positionCell{
            reference = ref,
            cell = ref.cell,
            ---@diagnostic disable-next-line: missing-fields
            position = {
                ref.position.x,
                ref.position.y,
                ref.position.z - (e.harvestableHeight* 0.5)/e.iterations
            },
        }
       e.currentIteration = e.currentIteration + 1
    end
end

---@class HarvestService.demolish.params
---@field reference tes3reference
---@field harvestableHeight number
---@field fallSpeed? number **Optional** default 10
---@field callback? fun(ref: tes3reference) **Optional** called when animation is complete

---@param e HarvestService.demolish.params
function HarvestService.demolish(e)
    --remove collision
    --reference.hasNoCollision = true
    --move ref down on a timer then disable
    local safeRef = tes3.makeSafeObjectHandle(e.reference)
    if not safeRef then return end
    local iterations = 1000
    local originalLocation = {
        position = {
            e.reference.position.x,
            e.reference.position.y,
            e.reference.position.z
        },
        orientation = {
            e.reference.orientation.x,
            e.reference.orientation.y,
            e.reference.orientation.z,
        }
    }
    local fellNode = e.reference.sceneNode:getObjectByName("ASHFALL_TREEFALL")
    local stumpNode = e.reference.sceneNode:getObjectByName("ASHFALL_STUMP")
    local playerZ = tes3.player.orientation.z
    logger:debug("Adding to destroyedHarvestables: %s", e.reference.id)

    e.reference.data.ashfallDestroyedHarvestable = true
    HarvestService.destroyedHarvestables:addReference(e.reference)

    local currentIteration = 0

    local duration = e.fallSpeed
    timer.start{
        duration = duration/iterations,
        iterations = iterations,
        type = timer.simulate,
        callback = function()
            if fellNode then
                local animParams = {
                    safeRef = safeRef,
                    fellNode = fellNode,
                    stumpNode = stumpNode,
                    iterations = iterations,
                    currentIteration = currentIteration,
                    playerZ = playerZ,
                    reference = e.reference
                }
                HarvestService.animateFellNode(animParams)
                currentIteration = animParams.currentIteration
            else
                local animParams = {
                    safeRef = safeRef,
                    iterations = iterations,
                    currentIteration = currentIteration,
                    harvestableHeight = e.harvestableHeight,
                    reference = e.reference
                }
                HarvestService.animateDefault(animParams)
                currentIteration = animParams.currentIteration
            end
        end,
    }
    timer.start{
        duration = duration,
        iterations = 1,
        type = timer.simulate,
        callback = function()
            if safeRef:valid() then
                local ref = safeRef:getObject()
                tes3.positionCell{
                    reference = ref,
                    cell = ref.cell,
                    position = originalLocation.position,
                    orientation = originalLocation.orientation
                }
                ref:disable()
                if e.callback then
                    e.callback(ref)
                end
            end
        end
    }
end

return HarvestService