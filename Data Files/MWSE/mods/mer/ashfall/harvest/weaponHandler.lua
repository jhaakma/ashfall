---@class Ashfall.WeaponHandler
---Handles weapon validation, swing strength calculation, and weapon degradation
local WeaponHandler = {}

local common = require("mer.ashfall.common.common")
local logger = common.createLogger("weaponHandler")
local harvestConfigs = require("mer.ashfall.harvest.config")
local HarvestValidator = require("mer.ashfall.harvest.validator")

-- Constants for weapon mechanics
local CONSTANTS = {
    MAX_WEAPON_DAMAGE = 50,           -- Cap for weapon damage in strength calculations
    BASE_DEGRADATION_RATE = 3,        -- Base condition loss per swing
    SWING_VARIANCE_MIN = 0,           -- Minimum extra threshold (added to base config)
    SWING_VARIANCE_MAX = 0,           -- Maximum extra threshold (no variance for predictability)
}

-- ============================================================================
-- WEAPON LOOKUP FUNCTIONS
-- ============================================================================

---Checks if weapon passes config's requirements function
---@param weapon tes3equipmentStack
---@param harvestConfig Ashfall.Harvest.Config
---@return boolean
local function weaponMeetsRequirements(weapon, harvestConfig)
    if not harvestConfig.requirements then
        return true  -- No requirements = always passes
    end
    return harvestConfig.requirements(weapon)
end

---Looks up weapon data by exact weapon ID
---@param weapon tes3equipmentStack
---@param harvestConfig Ashfall.Harvest.Config
---@return Ashfall.Harvest.WeaponData | nil
local function getWeaponDataById(weapon, harvestConfig)
    if not harvestConfig.weaponIds then
        return nil
    end
    return harvestConfig.weaponIds[weapon.object.id:lower()]
end

---Looks up weapon data by name pattern matching
---@param weapon tes3equipmentStack
---@param harvestConfig Ashfall.Harvest.Config
---@return Ashfall.Harvest.WeaponData | nil
local function getWeaponDataByNamePattern(weapon, harvestConfig)
    if not harvestConfig.weaponNamePatterns then
        return nil
    end

    local weaponName = weapon.object.name:lower()
    for pattern, data in pairs(harvestConfig.weaponNamePatterns) do
        if string.match(weaponName, pattern) then
            -- Cache this weapon ID for future lookups
            harvestConfig.weaponIds = harvestConfig.weaponIds or {}
            harvestConfig.weaponIds[weapon.object.id:lower()] = data
            return data
        end
    end
    return nil
end

---Looks up weapon data by weapon type
---@param weapon tes3equipmentStack
---@param harvestConfig Ashfall.Harvest.Config
---@return Ashfall.Harvest.WeaponData | nil
local function getWeaponDataByType(weapon, harvestConfig)
    if not harvestConfig.weaponTypes then
        return nil
    end
    return harvestConfig.weaponTypes[weapon.object.type]
end

---Gets weapon harvest data by checking requirements then looking up in priority order:
---1. Exact weapon ID, 2. Name pattern, 3. Weapon type
---@param weapon tes3equipmentStack
---@param harvestConfig Ashfall.Harvest.Config
---@return Ashfall.Harvest.WeaponData | nil
function WeaponHandler.getWeaponHarvestData(weapon, harvestConfig)
    -- First check if weapon meets basic requirements
    if not weaponMeetsRequirements(weapon, harvestConfig) then
        return nil
    end

    -- Try lookup strategies in order of specificity
    return getWeaponDataById(weapon, harvestConfig)
        or getWeaponDataByNamePattern(weapon, harvestConfig)
        or getWeaponDataByType(weapon, harvestConfig)
end

-- ============================================================================
-- SWING STRENGTH CALCULATION
-- ============================================================================

---Calculates damage effect multiplier based on weapon damage and attack direction
---@param weapon tes3equipmentStack
---@return number damageEffect Value from 1.0 to 2.0
function WeaponHandler.getDamageEffect(weapon)
    local attackDirection = HarvestValidator.getAttackDirection()
    local maxField = harvestConfigs.attackDirectionMapping[attackDirection].max
    local maxDamage = weapon.object[maxField]
    logger:trace("maxDamage: %s", maxDamage)
    local cappedDamage = math.min(maxDamage, CONSTANTS.MAX_WEAPON_DAMAGE)
    logger:trace("cappedDamage: %s", cappedDamage)
    return 1 + (cappedDamage / CONSTANTS.MAX_WEAPON_DAMAGE)
end

---Calculates the strength value for a swing based on attack power, weapon effectiveness, and damage
---@param weapon tes3equipmentStack
---@param weaponData Ashfall.Harvest.WeaponData
---@return number swingStrength The calculated strength of this swing
function WeaponHandler.getSwingStrength(weapon, weaponData)
    local attackSwing = tes3.player.mobile.actionData.attackSwing
    logger:trace("attackSwing: %s", attackSwing)
    local effectiveness = weaponData.effectiveness or 1.0
    logger:trace("effectiveness: %s", effectiveness)
    local damageEffect = WeaponHandler.getDamageEffect(weapon)
    logger:trace("damageEffect: %s", damageEffect)
    --Calculate Swing Strength
    local swingStrength = attackSwing * effectiveness * damageEffect
    logger:trace("swingStrength: %s", swingStrength)
    return swingStrength
end

-- ============================================================================
-- WEAPON DEGRADATION
-- ============================================================================

---Degrades weapon condition based on swing strength, returns true if weapon breaks
---@param weapon tes3equipmentStack
---@param swingStrength number
---@param degradeMulti number default: 1.0
---@return boolean weaponBroke True if weapon broke and was unequipped
function WeaponHandler.degradeWeapon(weapon, swingStrength, degradeMulti)
    degradeMulti = degradeMulti or 1.0
    logger:trace("degrade multiplier: %s", degradeMulti)

    -- Apply degradation
    weapon.itemData.condition = weapon.itemData.condition - (CONSTANTS.BASE_DEGRADATION_RATE * swingStrength * degradeMulti)

    -- Check if weapon is broken
    if weapon.itemData.condition <= 0 then
        weapon.itemData.condition = 0
        tes3.mobilePlayer:unequip{ type = tes3.objectType.weapon }
        return true
    end
    return false
end

-- ============================================================================
-- STRENGTH ACCUMULATION
-- ============================================================================

---Gets the currently accumulated strength for a reference
---@param reference tes3reference
---@return number accumulatedStrength
function WeaponHandler.getAccumulatedStrength(reference)
    return reference.tempData.accumulatedStrength or 0
end

---Gets the strength threshold needed to complete harvest (with randomization applied)
---@param reference tes3reference
---@param configuredThreshold number Base threshold from config
---@return number threshold The actual threshold (base + random variance)
function WeaponHandler.getStrengthThreshold(reference, configuredThreshold)
    local threshold = reference.tempData.strengthThreshold
    if configuredThreshold and not threshold then
        WeaponHandler.setStrengthThreshold(reference, configuredThreshold)
        threshold = reference.tempData.strengthThreshold
    end
    return threshold
end

---Sets the strength threshold with random variance
---@param reference tes3reference
---@param configuredThreshold number Base threshold from config
function WeaponHandler.setStrengthThreshold(reference, configuredThreshold)
    reference.tempData.strengthThreshold = math.random(
        configuredThreshold + CONSTANTS.SWING_VARIANCE_MIN,
        configuredThreshold + CONSTANTS.SWING_VARIANCE_MAX
    )
end

---Accumulates swing strength and checks if harvest threshold is met
---@param swingStrength number The strength value of the current swing
---@param reference tes3reference The harvestable reference
---@param configuredThreshold number The base threshold from config (swingsNeeded field)
---@return boolean isHarvested True if accumulated strength meets or exceeds threshold
function WeaponHandler.accumulateStrength(swingStrength, reference, configuredThreshold)
    local threshold = WeaponHandler.getStrengthThreshold(reference, configuredThreshold)
    local currentStrength = WeaponHandler.getAccumulatedStrength(reference)
    local newStrength = currentStrength + swingStrength

    logger:debug("accumulated strength before: %s", currentStrength)
    logger:debug("swing strength: %s", swingStrength)
    logger:debug("accumulated strength after: %s", newStrength)
    logger:debug("strength threshold: %s", threshold)

    local isHarvested = newStrength >= threshold
    reference.tempData.accumulatedStrength = newStrength
    logger:debug("isHarvested: %s", isHarvested)
    return isHarvested
end

---Resets accumulated strength and threshold for a reference
---@param reference tes3reference
function WeaponHandler.resetAccumulatedStrength(reference)
    reference.tempData.accumulatedStrength = 0
    reference.tempData.strengthThreshold = nil
end

return WeaponHandler
