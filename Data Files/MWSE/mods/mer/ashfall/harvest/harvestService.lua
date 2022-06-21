local common = require("mer.ashfall.common.common")
local logger = common.createLogger("harvestService")
local config = require("mer.ashfall.config").config
local harvestConfigs = require("mer.ashfall.harvest.config")
local ReferenceController = require("mer.ashfall.referenceController")
local destroyedHarvestables = ReferenceController.registerReferenceController{
    id = "destroyedHarvestable",
    ---@param self any
    ---@param ref tes3reference
    requirements = function(self, ref)
        return ref.disabled
            and (ref.data and ref.data.ashfallDestroyedHarvestable)
    end
}


local HarvestService = {}

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
    logger:debug("maxDamage: %s", maxDamage)
    local cappedDamage = math.min(maxDamage, MAX_WEAPON_DAMAGE)
    logger:debug("cappedDamage: %s", cappedDamage)
    return 1 + (cappedDamage / MAX_WEAPON_DAMAGE)
end

---@param weapon tes3equipmentStack
---@param weaponData AshfallHarvestWeaponData
---@return number
function HarvestService.getSwingStrength(weapon, weaponData)
    local attackSwing = tes3.player.mobile.actionData.attackSwing
    logger:debug("attackSwing: %s", attackSwing)
    local effectiveness = weaponData.effectiveness or 1.0
    logger:debug("effectiveness: %s", effectiveness)
    local damageEffect = HarvestService.getDamageEffect(weapon)
    logger:debug("damageEffect: %s", damageEffect)
    --Calculate Swing Strength
    local swingStrength = attackSwing * effectiveness * damageEffect
    logger:debug("swingStrength: %s", swingStrength)
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
    logger:debug("swings before: %s", reference.tempData.ashfallHarvestSwings)
    logger:debug("swingStrength: %s", swingStrength)
    logger:debug("swings after: %s", swings)
    reference.tempData.ashfallHarvestSwings = swings
    local isHarvested = swings > swingsNeeded
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
---@param weaponData AshfallHarvestWeaponData
function HarvestService.degradeWeapon(weapon, swingStrength, weaponData)
    local degradeMulti = weaponData.degradeMulti or 1.0
    logger:debug("degrade multiplier: %s", degradeMulti)
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
    logger:debug("Roll: %s", roll)
    for _, harvestable in ipairs(harvestConfig.items) do
        local chance = harvestable.chance
        logger:debug("Chance: %s", chance)
        if roll <= chance then
            logger:debug("Adding %s", harvestable.id)
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
end

function HarvestService.getTotalHarvested(reference)
    return reference.data.ashfallTotalHarvested or 0
end

function HarvestService.getSetDestructionLimit(reference, destructionLimit)
    if not reference.data.ashfallDestructionLimit then
        local limit = math.random(destructionLimit.min, destructionLimit.max)
        reference.data.ashfallDestructionLimit = limit
    end
    return reference.data.ashfallDestructionLimit
end

---@param reference tes3reference
---@param harvestConfig AshfallHarvestConfig
function HarvestService.disableExhaustedHarvestable(reference, harvestConfig)
    local destructionLimit = harvestConfig.destructionLimit
    if not destructionLimit then return end
    local totalHarvested = HarvestService.getTotalHarvested(reference)
    local destructionLimit = HarvestService.getSetDestructionLimit(reference, destructionLimit)
    if totalHarvested >= destructionLimit then
        HarvestService.disableHarvestable(reference, harvestConfig, true)
    end
end

function HarvestService.updateDisabledHarvestables()
    destroyedHarvestables:iterate(function(ref)
        if ref.position:distance(tes3.player.position) > (8192/2) then
            logger:debug("Enabling Disabled Harvestable: %s", ref.id)
            ref:enable()
            ref.hasNoCollision = false
            ref.data.ashfallDestroyedHarvestable = nil
        end
    end)
end

function HarvestService.disableNearbyRefs(harvestableRef, harvestConfig)
    logger:debug("disabling nearby refs")
    for ref in harvestableRef.cell:iterateReferences{tes3.objectType.container, tes3.objectType.static} do
        if harvestConfig.clutter and harvestConfig.clutter[ref.baseObject.id:lower()] then
            logger:trace("%s", ref.id)
            if common.helper.getCloseEnough({ref1 = ref, ref2 = harvestableRef, distHorizontal = 400, distVertical = 1000}) then
                logger:debug("close enough, disabling")
                HarvestService.disableHarvestable(ref, harvestConfig, false)
            end
        end
    end
end

function HarvestService.disableHarvestable(reference, harvestConfig, doNearbyRefs)
    logger:debug("Disabling harvestable %s", reference)
    reference.data.ashfallTotalHarvested = nil
    reference.data.ashfallDestructionLimit = nil
    HarvestService.demolish(reference)
    reference.data.ashfallDestroyedHarvestable = true
    if doNearbyRefs then
        if harvestConfig.fallSound then
            tes3.playSound{ reference = reference, sound = harvestConfig.fallSound}
        end
        if harvestConfig.clutter then
            HarvestService.disableNearbyRefs(reference, harvestConfig)
        end
    end
end

function HarvestService.demolish(reference)
    --remove collision
    reference.hasNoCollision = true
    --move ref down on a timer then disable
    local safeRef = tes3.makeSafeObjectHandle(reference)
    local distance = 500
    local iterations = 1000
    local duration = 1.4
    local originalLocation = reference.position:copy()
    timer.start{
        duration = duration/iterations,
        iterations = iterations,
        type = timer.simulate,
        callback = function()
            if safeRef:valid() then
                local ref = safeRef:getObject()
                tes3.positionCell{
                    reference = ref,
                    cell = ref.cell,
                    position = {
                        ref.position.x,
                        ref.position.y,
                        ref.position.z - (distance/iterations)
                    },
                    orientation = ref.orientation
                }
            end
        end
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
                    position = originalLocation,
                    orientation = ref.orientation
                }
                destroyedHarvestables:addReference(reference)
            end
        end
    }
end

return HarvestService