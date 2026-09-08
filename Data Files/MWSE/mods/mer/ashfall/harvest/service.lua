local common = require("mer.ashfall.common.common")
local skillsConfig = require("mer.ashfall.config.skillConfigs")
local logger = common.createLogger("harvestService")
local harvestConfigs = require("mer.ashfall.harvest.config")
local Activator = require("mer.ashfall.activators.Activator")
local HarvestValidator = require("mer.ashfall.harvest.validator")
local WeaponHandler = require("mer.ashfall.harvest.weaponHandler")
local DestructionManager = require("mer.ashfall.harvest.destructionManager")

-- Constants for harvest mechanics
local CONSTANTS = {
    -- Harvest amount calculation
    BASE_HARVEST_PERCENT = 0.5,  -- Guaranteed base harvest (50% of max)
    SKILL_BONUS_PERCENT = 0.5,   -- Additional amount from skill (up to 50% more)
}

---@class Ashfall.HarvestService
local HarvestService = {}

-- Delegate destroyedHarvestables registry to DestructionManager
HarvestService.destroyedHarvestables = DestructionManager.destroyedHarvestables

function HarvestService.checkHarvested(reference)
    return HarvestValidator.checkHarvested(reference)
end


---@class Ashfall.HarvestService.getCurrentHarvestData.params
---@field ignoreAttackDirection? boolean If true, will ignore the attack direction check
---@field showIllegalToHarvestMessage? boolean If true, will show a message if it's illegal to harvest

--Get the config for the current harvestable
---@return Ashfall.Harvest.CurrentHarvestData|nil
---@param e Ashfall.HarvestService.getCurrentHarvestData.params|nil
function HarvestService.getCurrentHarvestData(e)
    e = e or {}

    -- Get player target Activator
    local activator = Activator.getCurrent()
    if not activator then
        logger:trace("Harvest: No activator")
        return
    end

    -- Get activator reference
    local reference = Activator.getCurrentReference()
    if not reference then
        logger:debug("Harvest: No reference")
        return
    end

    -- Get harvest config from activator
    ---@type Ashfall.Harvest.Config
    local harvestConfig = harvestConfigs.activatorHarvestData[activator.type]
    if not harvestConfig then
        logger:trace("Harvest: No harvest config")
        return
    end

    -- Get player weapon
    local weapon = tes3.player.mobile.readiedWeapon
    if not weapon then
        logger:debug("Harvest: No weapon")
        return
    end

    -- Get harvest data from weapon
    local weaponData = WeaponHandler.getWeaponHarvestData(weapon, harvestConfig)
    if not weaponData then
        logger:debug("Harvest: No weapon data")
        return
    end

    -- Validate all harvest conditions
    if not HarvestValidator.validateActivatorEnabled(activator) then return end
    if not HarvestValidator.validateHarvestLegality(harvestConfig, e.showIllegalToHarvestMessage) then return end
    if not HarvestValidator.validateAttackDirection(harvestConfig, e.ignoreAttackDirection) then return end
    if not HarvestValidator.validateNotHarvested(reference) then return end

    -- All checks pass, return the harvest data
    return {
        reference = reference,
        activator = activator,
        harvestConfig = harvestConfig,
        weapon = weapon,
        weaponData = weaponData
    }
end

-- ============================================================================
-- WEAPON HANDLING - Delegate to WeaponHandler module
-- ============================================================================

function HarvestService.getWeaponHarvestData(weapon, harvestConfig)
    return WeaponHandler.getWeaponHarvestData(weapon, harvestConfig)
end

function HarvestService.getDamageEffect(weapon)
    return WeaponHandler.getDamageEffect(weapon)
end

function HarvestService.getSwingStrength(weapon, weaponData)
    return WeaponHandler.getSwingStrength(weapon, weaponData)
end

function HarvestService.getAccumulatedStrength(reference)
    return WeaponHandler.getAccumulatedStrength(reference)
end

function HarvestService.getStrengthThreshold(reference, configuredThreshold)
    return WeaponHandler.getStrengthThreshold(reference, configuredThreshold)
end

function HarvestService.setStrengthThreshold(reference, configuredThreshold)
    WeaponHandler.setStrengthThreshold(reference, configuredThreshold)
end

function HarvestService.accumulateStrength(swingStrength, reference, configuredThreshold)
    return WeaponHandler.accumulateStrength(swingStrength, reference, configuredThreshold)
end

function HarvestService.resetAccumulatedStrength(reference)
    WeaponHandler.resetAccumulatedStrength(reference)
end

function HarvestService.degradeWeapon(weapon, swingStrength, degradeMulti)
    return WeaponHandler.degradeWeapon(weapon, swingStrength, degradeMulti)
end

-- ============================================================================
-- HARVEST SOUND AND ITEM HANDLING
-- ============================================================================

function HarvestService.playSound(harvestConfig)
    tes3.playSound({reference=tes3.player, soundPath = harvestConfig.sound})
end


function HarvestService.calcNumHarvested(harvestable)
    -- Use base amount + skill bonus system for more predictable harvesting
    local survivalSkill = math.clamp(common.skills.survival.current, 0, 100)
    local skillMultiplier = survivalSkill / 100  -- 0.0 to 1.0

    -- Calculate base amount (guaranteed minimum)
    local baseAmount = math.ceil(harvestable.count * CONSTANTS.BASE_HARVEST_PERCENT)

    -- Calculate skill bonus (random amount based on skill)
    local maxBonus = math.ceil(harvestable.count * CONSTANTS.SKILL_BONUS_PERCENT * skillMultiplier)
    local skillBonus = math.random(0, maxBonus)

    local numHarvested = baseAmount + skillBonus

    logger:debug("Harvest calculation: base=%d, maxBonus=%d, actual=%d (skill=%d)",
        baseAmount, maxBonus, numHarvested, survivalSkill)

    return numHarvested
end

---@param numHarvested number
---@param harvestName string
function HarvestService.showHarvestedMessage(numHarvested, harvestName)
    local message = string.format("You harvest %s %s of %s", numHarvested, numHarvested > 1 and "pieces" or "piece", harvestName)
    tes3.messageBox(message)
end

---Selects which harvestable to give based on weighted chance
---@param harvestables Ashfall.Harvest.Config.Harvestable[]
---@return Ashfall.Harvest.Config.Harvestable | nil
local function selectHarvestable(harvestables)
    local roll = math.random()
    logger:trace("Harvest selection roll: %s", roll)

    for _, harvestable in ipairs(harvestables) do
        logger:trace("Checking %s (chance: %s)", harvestable.id, harvestable.chance)
        if roll <= harvestable.chance then
            logger:trace("Selected: %s", harvestable.id)
            return harvestable
        end
        roll = roll - harvestable.chance
    end

    logger:trace("No harvestable selected")
    return nil
end

---Adds a harvestable item to the player's inventory
---@param harvestable Ashfall.Harvest.Config.Harvestable
---@return number numHarvested
local function giveHarvestableToPlayer(harvestable)
    local numHarvested = HarvestService.calcNumHarvested(harvestable)
    local itemObject = tes3.getObject(harvestable.id)

    tes3.addItem{
        reference = tes3.player,
        item = harvestable.id,
        count = numHarvested,
        playSound = false
    }

    tes3.playSound({reference = tes3.player, sound = "Item Misc Up"})
    HarvestService.showHarvestedMessage(numHarvested, itemObject.name)
    event.trigger("Ashfall:triggerPackUpdate")

    return numHarvested
end

---Selects and adds items from harvest config based on weighted chance
---@param harvestConfig Ashfall.Harvest.Config
---@return number numHarvested The number of items that were harvested from the reference
function HarvestService.addItems(harvestConfig)
    local harvestable = selectHarvestable(harvestConfig.items)
    if not harvestable then
        return 0
    end
    return giveHarvestableToPlayer(harvestable)
end

---@param reference tes3reference
---@param harvestConfig Ashfall.Harvest.Config
---@return number numHarvested The number of items that were harvested from the reference
function HarvestService.harvest(reference, harvestConfig)
    HarvestService.resetAccumulatedStrength(reference)
    common.skills.survival:exercise(harvestConfig.swingsNeeded * skillsConfig.survival.harvest.gainPerSwing)
    local numHarvested = HarvestService.addItems(harvestConfig)
    tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
    DestructionManager.updateTotalHarvested(reference, numHarvested)
    return numHarvested
end

return HarvestService