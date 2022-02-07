local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local harvestConfigs = require("mer.ashfall.harvest.config")
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

---@param weapon tes3equipmentStack
---@return number damageEffect
function HarvestService.getDamageEffect(weapon)
    local attackDirection = tes3.mobilePlayer.actionData.attackDirection
    local maxField = harvestConfigs.attackDirectionMapping[attackDirection].max
    local maxDamage = weapon.object[maxField]
    common.log:debug("maxDamage: %s", maxDamage)
    local cappedDamage = math.min(maxDamage, MAX_WEAPON_DAMAGE)
    common.log:debug("cappedDamage: %s", cappedDamage)
    return 1 + (cappedDamage / MAX_WEAPON_DAMAGE)
end

---@param weapon tes3equipmentStack
---@param weaponData AshfallHarvestWeaponData
---@return number
function HarvestService.getSwingStrength(weapon, weaponData)
    local attackSwing = tes3.player.mobile.actionData.attackSwing
    common.log:debug("attackSwing: %s", attackSwing)
    local effectiveness = weaponData.effectiveness or 1.0
    common.log:debug("effectiveness: %s", effectiveness)
    local damageEffect = HarvestService.getDamageEffect(weapon)
    common.log:debug("damageEffect: %s", damageEffect)
    --Calculate Swing Strength
    local swingStrength = attackSwing * effectiveness * damageEffect
    common.log:debug("swingStrength: %s", swingStrength)
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
    common.log:debug("swings before: %s", reference.tempData.ashfallHarvestSwings)
    common.log:debug("swingStrength: %s", swingStrength)
    common.log:debug("swings after: %s", swings)
    reference.tempData.ashfallHarvestSwings = swings
    local isHarvested = swings > swingsNeeded
    common.log:debug("isHarvested: %s", isHarvested)
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
    common.log:debug("degrade multiplier: %s", degradeMulti)
    --Weapon degradation
    weapon.variables.condition = weapon.variables.condition - (2 * swingStrength * degradeMulti)
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
    local survivalMulti = math.remap(survivalSkill, 0, 100, 0.5, 1)
    local numHarvested = math.ceil(math.random(1, harvestable.count) * survivalMulti)
    return numHarvested
end

---@param numHarvested number
---@param harvestName string
function HarvestService.showHarvestedMessage(numHarvested, harvestName)
    local message = string.format("You harvest %s %s of %s", numHarvested, numHarvested > 1 and "pieces" or "piece", harvestName)
    tes3.messageBox(message)
end

---@param harvestConfig AshfallHarvestConfig
function HarvestService.addItems(harvestConfig)
    local roll = math.random()
    common.log:debug("Roll: %s", roll)
    for _, harvestable in ipairs(harvestConfig.items) do
        local chance = harvestable.chance
        common.log:debug("Chance: %s", chance)
        if roll <= chance then
            common.log:debug("Adding %s", harvestable.id)
            tes3.playSound({reference=tes3.player, sound="Item Misc Up"})
            local numHarvested = HarvestService.calcNumHarvested(harvestable)
            tes3.addItem{reference=tes3.player, item= harvestable.id, count=numHarvested}
            HarvestService.showHarvestedMessage(numHarvested, tes3.getObject(harvestable.id).name)
            event.trigger("Ashfall:triggerPackUpdate")
            return
        end
        roll = roll - harvestable.chance
    end
end

---@param reference tes3reference
---@param harvestConfig AshfallHarvestConfig
function HarvestService.harvest(reference, harvestConfig)
    HarvestService.resetSwings(reference)
    common.skills.survival:progressSkill(harvestConfig.swingsNeeded * 2)
    HarvestService.addItems(harvestConfig)
    tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
end

return HarvestService