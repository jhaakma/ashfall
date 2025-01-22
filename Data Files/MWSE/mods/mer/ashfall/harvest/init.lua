local common = require("mer.ashfall.common.common")
local logger = common.createLogger("harvestController")
local config = require("mer.ashfall.config").config
local service = require("mer.ashfall.harvest.service")

--- Attempt a harvest on attack swing
---@param e attackEventData
local function harvestOnAttack(e)
    logger:debug("harvestOnAttack() ENTRY")
    --Filter to player
    if e.mobile.reference ~= tes3.player then
        logger:debug("Harvest: Not player")
        return
    end
    local data = service.getCurrentHarvestData{ showIllegalToHarvestMessage = true }
    if not data then
        logger:debug("Harvest: No current harvest data")
        return
    end
    logger:debug("Checks passed, swinging")
    --CHECKS PASS, we are swinging at something
    service.playSound(data.harvestConfig)
    --Get strength of swing
    local swingStrength = service.getSwingStrength(data.weapon, data.weaponData)
    --Degrade weapon and exit if it breaks
    local weaponBroke = service.degradeWeapon(data.weapon, swingStrength, data.weaponData.degradeMulti)
    if weaponBroke then
        logger:debug("Weapon broke")
        return
    end
    --Accumulate swings and check if it's enough to harvest
    local didHarvest = service.attemptSwing(swingStrength, data.reference, data.harvestConfig.swingsNeeded)
    if not didHarvest then return end
    logger:debug("Enough swings, harvesting")
    --Harvest the resources
    service.harvest(data.reference, data.harvestConfig)
    --Disable if  exhausted
    if data.harvestConfig.destructionLimitConfig and config.disableHarvested then
        logger:debug("Disabling exhausted harvestable")
        service.disableExhaustedHarvestable(data.reference, data.harvestConfig)
    end
    logger:debug("harvestOnAttack() EXIT")
end
event.register("attackHit", harvestOnAttack )


--- Force a chop action if looking at a harvestable with a valid weapon
---@param e attackStartEventData
event.register("attackStart", function(e)
    --Filter to player
    if e.reference ~= tes3.player then
        logger:debug("Harvest: Not player")
        return
    end
    local data = service.getCurrentHarvestData({ ignoreAttackDirection = true})
    if not data then
        logger:debug("Harvest: Not ready to harvest")
        return
    end
    local hasAttackDirections = data.harvestConfig.attackDirections
        and table.size(data.harvestConfig.attackDirections) > 0
    if not hasAttackDirections then
        logger:debug("No attack directions")
        return
    end
    --Check if current attack direction doesn't match valid directions for this harvestable
    if  data.harvestConfig.attackDirections[e.attackType] then
        --already a valid direction
        return
    end
    if data.harvestConfig.defaultAttackDirection then
        logger:debug("Forcing default attack type %s", table.find(tes3.physicalAttackType, data.harvestConfig.defaultAttackDirection))
        e.attackType = data.harvestConfig.defaultAttackDirection
    else
        --set to first one in list
        for attackType, _ in pairs(data.harvestConfig.attackDirections) do
            logger:debug("Forcing attack type %s", table.find(tes3.physicalAttackType, attackType))
            e.attackType = attackType
            break
        end
    end
end)

--- Block swing sounds when harvesting
---@param e addSoundEventData
event.register("addSound", function(e)
    --filter to player
    if e.reference ~= tes3.player then return end
    local data = service.getCurrentHarvestData()
    if not data then return end
    local swishSounds = {
        ["swishl"] = true,
        ["swishm"] = true,
        ["swishs"] = true,
        ["weapon swish"] = true,
        ["miss"] = true,
    }
    if swishSounds[e.sound.id:lower()] then
        logger:debug("Blocking vanilla weapon swish sound")
        return false
    end
end, { priority = 500})

--- Reset harvestables on load.
event.register("loaded", function()
    service.destroyedHarvestables:iterate(function(reference)
        service.enableHarvestable(reference)
    end)
    timer.start{
        type = timer.simulate,
        iterations = -1,
        duration = 1,
        callback = service.updateDisabledHarvestables
    }
end)

--- Clear any data added when an item was felled from a tree.
---@param e activateEventData
event.register("activate", function(e)
    if common.helper.isCarryable(e.target.baseObject) then
        if e.target and e.target.data then
            e.target.data.ashfallHarvestOriginalLocation = nil
            e.target.data.ashfallDestroyedHarvestable = nil
        end
    end
end)

