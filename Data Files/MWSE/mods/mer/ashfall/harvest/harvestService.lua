local common = require("mer.ashfall.common.common")
local logger = common.createLogger("harvestService")
local config = require("mer.ashfall.config").config
local harvestConfigs = require("mer.ashfall.harvest.config")
local ReferenceController = require("mer.ashfall.referenceController")
local ActivatorController = require("mer.ashfall.activators.activatorController")

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

---@param harvestConfig AshfallHarvestConfig
function HarvestService.showIllegalToHarvestMessage(harvestConfig)
    tes3.messageBox("You must be in the wilderness to harvest.")
end

---@param weapon tes3equipmentStack
---@param harvestConfig AshfallHarvestConfig
---@return AshfallHarvestWeaponData | nil
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

function HarvestService.validAttackDirection(harvestConfig)
    local attackDirection = tes3.mobilePlayer.actionData.attackDirection
    return harvestConfig.attackDirections[attackDirection]
end

---@param weapon tes3equipmentStack
---@return number damageEffect
function HarvestService.getDamageEffect(weapon)
    local attackDirection = tes3.mobilePlayer.actionData.attackDirection
    local maxField = harvestConfigs.attackDirectionMapping[attackDirection].max
    local maxDamage = weapon.object[maxField]
    logger:trace("maxDamage: %s", maxDamage)
    local cappedDamage = math.min(maxDamage, MAX_WEAPON_DAMAGE)
    logger:trace("cappedDamage: %s", cappedDamage)
    return 1 + (cappedDamage / MAX_WEAPON_DAMAGE)
end

---@param weapon tes3equipmentStack
---@param weaponData AshfallHarvestWeaponData
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

function HarvestService.getSwingsNeeded(reference, harvestConfig)
    local swingsNeeded = reference.tempData.ashfallSwingsNeeded
    if harvestConfig and not swingsNeeded then
        HarvestService.setSwingsNeeded(reference, harvestConfig)
        swingsNeeded = reference.tempData.ashfallSwingsNeeded
    end
    return swingsNeeded
end

function HarvestService.setSwingsNeeded(reference, harvestConfig)
    reference.tempData.ashfallSwingsNeeded = math.random(harvestConfig.swingsNeeded, harvestConfig.swingsNeeded + 2)
end

---@param swingStrength number
---@param reference tes3reference
---@param harvestConfig AshfallHarvestConfig
---@return boolean isHarvested
function HarvestService.attemptSwing(swingStrength, reference, harvestConfig)
    local swingsNeeded = HarvestService.getSwingsNeeded(reference, harvestConfig)
    reference.tempData.ashfallHarvestSwings = reference.tempData.ashfallHarvestSwings or 0
    local swings = reference.tempData.ashfallHarvestSwings + swingStrength
    logger:trace("swings before: %s", reference.tempData.ashfallHarvestSwings)
    logger:trace("swingStrength: %s", swingStrength)
    logger:trace("swings after: %s", swings)
    reference.tempData.ashfallHarvestSwings = swings
    local isHarvested = swings > swingsNeeded
    logger:trace("isHarvested: %s", isHarvested)
    return isHarvested
end

---@param reference tes3reference
function HarvestService.resetSwings(reference)
    reference.tempData.ashfallHarvestSwings = 0
    reference.tempData.ashfallSwingsNeeded = nil
end

---@param weapon tes3equipmentStack
---@param swingStrength number
---@param weaponData AshfallHarvestWeaponData
function HarvestService.degradeWeapon(weapon, swingStrength, weaponData)
    local degradeMulti = weaponData.degradeMulti or 1.0
    logger:trace("degrade multiplier: %s", degradeMulti)
    --Weapon degradation
    weapon.variables.condition = weapon.variables.condition - (4 * swingStrength * degradeMulti)
    --weapon is broken, unequip
    if weapon.variables.condition <= 0 then
        weapon.variables.condition = 0
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
    local survivalSkill = math.clamp(common.skills.survival.value or 30, 0, 100)
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

---@param harvestConfig AshfallHarvestConfig
---@return number numHarvested The number of items that were harvested from the reference
function HarvestService.addItems(harvestConfig)
    local roll = math.random()
    logger:trace("Roll: %s", roll)
    ---@param harvestable AshfallHarvestConfigHarvestable
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
end



---@param reference tes3reference
---@param harvestConfig AshfallHarvestConfig
---@return number numHarvested The number of items that were harvested from the reference
function HarvestService.harvest(reference, harvestConfig)
    HarvestService.resetSwings(reference)
    common.skills.survival:progressSkill(harvestConfig.swingsNeeded * 2)
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

---@param reference tes3reference
function HarvestService.getSetDestructionLimit(reference, destructionLimit)
    if not reference.data.ashfallDestructionLimit then
        local height = HarvestService.getRefHeight(reference)
        local minIn = destructionLimit.minHeight
        local maxIn = destructionLimit.maxHeight
        local minOut = destructionLimit.min
        local maxOut = destructionLimit.max
        local limit = math.remap(height, minIn, maxIn, minOut, maxOut)
        limit = math.clamp(limit, minOut, maxOut)
        limit = math.ceil(limit)
        logger:debug("Ref height: %s", height)
        logger:debug("Set destruction limit to %s", limit)
        reference.data.ashfallDestructionLimit = limit
        reference.modified = true
    end
    return reference.data.ashfallDestructionLimit
end

---@param reference tes3reference
function HarvestService.getRefHeight(reference)
    return (reference.object.boundingBox.max.z - reference.object.boundingBox.min.z) * reference.scale
end

---@param reference tes3reference
---@param harvestConfig AshfallHarvestConfig
function HarvestService.disableExhaustedHarvestable(reference, harvestConfig)
    local destructionLimit = harvestConfig.destructionLimit
    if not destructionLimit then return end
    local totalHarvested = HarvestService.getTotalHarvested(reference)
    local destructionLimit = HarvestService.getSetDestructionLimit(reference, destructionLimit)
    if totalHarvested >= destructionLimit then
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
    ---@param ref tes3reference
    for _, cell in ipairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences() do
            local isValid = ref ~= harvestableRef
                and harvestConfig.clutter
                and harvestConfig.clutter[ref.baseObject.id:lower()]
            if isValid then
                logger:trace("%s", ref.id)
                if common.helper.getCloseEnough({ref1 = ref, ref2 = harvestableRef, distHorizontal = 500, distVertical = 2000}) then
                    logger:debug("close enough, disabling")
                    HarvestService.disableHarvestable(ref, harvestableHeight, harvestConfig)
                    table.insert(ignoreList, ref)
                end
            end
        end
    end
    ---@param ref tes3reference
    for _, cell in ipairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences() do
            local activator = ActivatorController.getRefActivator(ref)
            local isValid = ref ~= harvestableRef
                and not (harvestConfig.clutter and harvestConfig.clutter[ref.baseObject.id:lower()])
                and not (activator and activator.type == "woodSource")
            if isValid then
                --Drop nearby loot
                if common.helper.getCloseEnough({ref1 = ref, ref2 = harvestableRef, distHorizontal = 150, distVertical = 2000, rootHeight = 100}) then
                    logger:debug("Found nearby %s", ref)
                    local result = common.helper.getGroundBelowRef{doLog = false, ref = ref, ignoreList = ignoreList}
                    local refBelow = result and result.reference
                    logger:debug(result and result.reference)
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
    reference.data.ashfallDestructionLimit = nil
    HarvestService.demolish(reference, harvestableHeight, harvestConfig)
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

---@param reference tes3reference
function HarvestService.demolish(reference, harvestableHeight, harvestConfig)
    --remove collision
    --reference.hasNoCollision = true
    --move ref down on a timer then disable
    local safeRef = tes3.makeSafeObjectHandle(reference)
    local iterations = 1000
    local originalLocation = {
        position = {
            reference.position.x,
            reference.position.y,
            reference.position.z
        },
        orientation = {
            reference.orientation.x,
            reference.orientation.y,
            reference.orientation.z,
        }
    }
    local fellNode = reference.sceneNode:getObjectByName("ASHFALL_TREEFALL")
    local stumpNode = reference.sceneNode:getObjectByName("ASHFALL_STUMP")
    local playerZ = tes3.player.orientation.z
    logger:debug("Adding to destroyedHarvestables: %s", reference.id)

    reference.data.ashfallDestroyedHarvestable = true
    HarvestService.destroyedHarvestables:addReference(reference)

    local currentIteration = 0
    local function animateFellNode(e)
        if safeRef:valid() then
            if fellNode then --rotate fell node
                HarvestService.rotateNodeAwayFromPlayer(reference, currentIteration, iterations, playerZ, 10, fellNode)
            end
            if stumpNode then --lower stump node
                local a = 4
                local u = 0
                local t = currentIteration/iterations
                local v = u + a * t
                stumpNode.translation = stumpNode.translation + tes3vector3.new(0, 0, -(100/iterations)*v)
                stumpNode:update()
            end
            currentIteration = currentIteration + 1
        end
    end

    local function animateDefault()
        if safeRef:valid() then
            local ref = safeRef:getObject()
            tes3.positionCell{
                reference = ref,
                cell = ref.cell,
                position = {
                    ref.position.x,
                    ref.position.y,
                    ref.position.z - (harvestableHeight* 0.5)/iterations
                },
            }
            currentIteration = currentIteration + 1
        end
    end

    local duration = harvestConfig.fallSpeed
    timer.start{
        duration = duration/iterations,
        iterations = iterations,
        type = timer.simulate,
        callback = fellNode and animateFellNode or animateDefault,
    }
    timer.start{
        duration = duration,
        iterations = 1,
        type = timer.simulate,
        callback = function()
            if safeRef:valid() then
                local ref = safeRef:getObject()
                ref:disable()
                tes3.positionCell{
                    reference = ref,
                    cell = ref.cell,
                    position = originalLocation.position,
                    orientation = originalLocation.orientation
                }

            end
        end
    }
end

return HarvestService