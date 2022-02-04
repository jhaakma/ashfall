local activatorController = require("mer.ashfall.activators.activatorController")
local harvestConfigs = require("mer.ashfall.harvest.config")
local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local service = require("mer.ashfall.harvest.harvestService")

---@param e attackEventData
local function harvestOnAttack(e)
    common.log:debug("harvestOnAttack")
    --Get the necessary objects and check conditions--

    --Filter to player
    if not e.mobile.reference == tes3.player then
        common.log:debug("Harvest: Not player")
        return
    end

    --Get player target Activator
    local activator = activatorController.getCurrentActivator()
    if not activator then
        common.log:debug("Harvest: No activator")
        return
    end

    --Get activator Ref
    local reference = activatorController.getCurrentActivatorReference()
    if not reference then
        common.log:debug("Harvest: No reference")
        return
    end

    --Get harvest config from activator
    ---@type AshfallHarvestConfig
    local harvestConfig = harvestConfigs.activatorHarvestData[activator.type]
    if not harvestConfig then
        common.log:debug("Harvest: No harvest config")
        common.log:debug("activatorType: %s", activator.type)
        return
    end

    --Get Player Weapon
    local weapon = tes3.player.mobile.readiedWeapon
    if not weapon then
        common.log:debug("Harvest: No weapon")
        return
    end

    --Get harvest data from weapon
    local weaponData = service.getWeaponHarvestData(weapon, harvestConfig)
    if not weaponData then
        common.log:debug("Harvest: No weapon data")
        return
    end

    --Check if Activator is active
    local activatorActive = config[activator.mcmSetting] ~= false
    if not activatorActive then
        common.log:debug("Harvest: Activator not active")
        return
    end

    --Return if illegal to harvest
    if service.checkIllegalToHarvest() then
        service.showIllegalToHarvestMessage(harvestConfig)
        common.log:debug("Harvest: Illegal to harvest")
        return
    end

    --CHECKS PASS, we are swinging at something
    service.playSound(harvestConfig)

    --Get strength of swing
    local swingStrength = service.getSwingStrength(weapon, weaponData)

    --Degrade weapon and exit if it breaks
    local weaponBroke = service.degradeWeapon(weapon, swingStrength, weaponData)
    if weaponBroke then return end

    --Accumulate swings and check if it's enough to harvest
    local didHarvest = service.attemptSwing(swingStrength, reference, harvestConfig)
    if not didHarvest then return end

    --Harvest the resources
    service.harvest(reference, harvestConfig)
end

event.register("attack", harvestOnAttack )