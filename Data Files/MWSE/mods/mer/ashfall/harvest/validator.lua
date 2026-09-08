---@class Ashfall.HarvestValidator
---Handles validation checks for harvest operations
local HarvestValidator = {}

local common = require("mer.ashfall.common.common")
local logger = common.createLogger("harvestValidator")
local config = require("mer.ashfall.config").config

---Checks if harvesting is illegal in the current location
---@return boolean isIllegal True if harvesting is not allowed
function HarvestValidator.checkIllegalToHarvest()
    return config.illegalHarvest
        and tes3.player.cell.restingIsIllegal
end

---Checks if a reference has already been harvested/destroyed
---@param reference tes3reference
---@return boolean isHarvested True if already harvested
function HarvestValidator.checkHarvested(reference)
    return reference.data.ashfallDestroyedHarvestable == true
end

---Shows message when harvesting is illegal
---@param harvestConfig Ashfall.Harvest.Config
function HarvestValidator.showIllegalToHarvestMessage(harvestConfig)
    tes3.messageBox("You must be in the wilderness to harvest.")
end

---Gets the current attack direction from player
---@return number attackDirection tes3.physicalAttackType value
function HarvestValidator.getAttackDirection()
    return tes3.mobilePlayer.actionData.attackDirection ---@diagnostic disable-line
end

---Checks if the current attack direction is valid for this harvest config
---@param harvestConfig Ashfall.Harvest.Config
---@return boolean isValid True if attack direction is allowed
function HarvestValidator.validAttackDirection(harvestConfig)
    local attackDirection = HarvestValidator.getAttackDirection()
    return harvestConfig.attackDirections[attackDirection]
end

---Validates that attack direction is allowed for this harvest config
---@param harvestConfig Ashfall.Harvest.Config
---@param ignoreCheck boolean If true, skip the validation
---@return boolean isValid True if validation passes
function HarvestValidator.validateAttackDirection(harvestConfig, ignoreCheck)
    if ignoreCheck then
        return true
    end
    if not HarvestValidator.validAttackDirection(harvestConfig) then
        logger:debug("Harvest: Invalid attack direction")
        return false
    end
    return true
end

---Validates that harvesting is legal in current location
---@param harvestConfig Ashfall.Harvest.Config
---@param showMessage boolean If true, show message when illegal
---@return boolean isValid True if validation passes
function HarvestValidator.validateHarvestLegality(harvestConfig, showMessage)
    if HarvestValidator.checkIllegalToHarvest() then
        if showMessage then
            HarvestValidator.showIllegalToHarvestMessage(harvestConfig)
        end
        logger:debug("Harvest: Illegal to harvest")
        return false
    end
    return true
end

---Validates that the reference hasn't been exhausted
---@param reference tes3reference
---@return boolean isValid True if not yet harvested
function HarvestValidator.validateNotHarvested(reference)
    if HarvestValidator.checkHarvested(reference) then
        logger:debug("Harvest: Can't harvest, already harvested")
        return false
    end
    return true
end

---Validates that the activator type is enabled in MCM settings
---@param activator Ashfall.Activator
---@return boolean isValid True if enabled
function HarvestValidator.validateActivatorEnabled(activator)
    local isEnabled = config[activator.mcmSetting] ~= false
    if not isEnabled then
        logger:debug("Harvest: Activator not active")
    end
    return isEnabled
end

return HarvestValidator
