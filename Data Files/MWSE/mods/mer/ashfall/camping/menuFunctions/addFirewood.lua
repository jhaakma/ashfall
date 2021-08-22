local common = require ("mer.ashfall.common.common")
--Calculate how much fuel is added per piece of firewood based on Survival skill

local function getWoodFuel()
    local survivalEffect = math.min( math.remap(common.skills.survival.value, 0, 100, 1, 1.5), 1.5)
    return common.staticConfigs.firewoodFuelMulti * survivalEffect
end

local function getFirewoodCount()
    return mwscript.getItemCount{ reference = tes3.player, item = common.staticConfigs.objectIds.firewood }
end

local function canAddFireWoodToCampfire(campfire)
    return (
        campfire.data.fuelLevel < common.staticConfigs.maxWoodInFire or
        campfire.data.burned == true
    )
end

local function getDisabledText(campfire)
    return {
        text = canAddFireWoodToCampfire(campfire) and "You have no Firewood." or "Max fuel level reached."
    }
end

return {
    text = "Add Firewood",
    showRequirements = function(campfire)
        return campfire.data.dynamicConfig ~= nil
    end,
    enableRequirements = function(campfire)
        return getFirewoodCount() > 0 and canAddFireWoodToCampfire(campfire)

    end,
    tooltipDisabled = getDisabledText,
    callback = function(campfire)
        tes3.playSound{ reference = tes3.player, sound = "ashfall_add_wood"  }
        campfire.data.fuelLevel = campfire.data.fuelLevel + getWoodFuel()
        campfire.data.burned = false
        mwscript.removeItem{ reference = tes3.player, item = common.staticConfigs.objectIds.firewood }
        event.trigger("Ashfall:UpdateAttachNodes", { campfire = campfire})
    end,
}