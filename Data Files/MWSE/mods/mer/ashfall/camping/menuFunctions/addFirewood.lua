local common = require ("mer.ashfall.common.common")
--Calculate how much fuel is added per piece of firewood based on Survival skill

local function getWoodFuel()
    local survivalEffect = math.min( math.remap(common.skills.survival.value, 0, 100, 1, 1.5), 1.5)
    return common.staticConfigs.firewoodFuelMulti * survivalEffect
end

local function getFirewoodCount()
    return tes3.getItemCount{ reference = tes3.player, item = common.staticConfigs.objectIds.firewood }
end

local function canAddFireWoodToCampfire(campfire)
    local fuelLevel = campfire.data.fuelLevel or 0
    return fuelLevel < common.staticConfigs.maxWoodInFire
end

local function getDisabledText(campfire)
    return {
        text = canAddFireWoodToCampfire(campfire) and "You have no Firewood." or "Max fuel level reached."
    }
end

return {
    text = "Add Firewood",
    showRequirements = function(campfire)
        return true
    end,
    enableRequirements = function(campfire)
        return getFirewoodCount() > 0 and canAddFireWoodToCampfire(campfire)
    end,
    tooltipDisabled = getDisabledText,
    callback = function(campfire)
        tes3.playSound{
            reference = tes3.player,
            sound = "ashfall_add_wood",
            loop = false
        }
        campfire.data.fuelLevel = (campfire.data.fuelLevel or 0) + getWoodFuel()
        campfire.data.burned = campfire.data.isLit == true
        tes3.removeItem{ reference = tes3.player, item = common.staticConfigs.objectIds.firewood, playSound = false }
        event.trigger("Ashfall:UpdateAttachNodes", { campfire = campfire})
    end,
}