local common = require ("mer.ashfall.common.common")
--Calculate how much fuel is added per piece of firewood based on Survival skill

local function getWoodFuel()
    local survivalEffect = math.min( math.remap(common.skills.survival.value, 0, 100, 1, 1.5), 1.5)
    return common.staticConfigs.firewoodFuelMulti * survivalEffect
end
return {
    text = "Add Firewood",
    requirements = function(campfire)
        return (
            mwscript.getItemCount{ reference = tes3.player, item = common.staticConfigs.objectIds.firewood } > 0 and
            ( 
                campfire.data.fuelLevel < common.staticConfigs.maxWoodInFire or 
                campfire.data.burned == true 
            ) and
            campfire.data.dynamicConfig
        )
    end,
    callback = function(campfire)
        tes3.playSound{ reference = tes3.player, sound = "ashfall_add_wood"  }
        campfire.data.fuelLevel = campfire.data.fuelLevel + getWoodFuel()
        campfire.data.burned = false
        mwscript.removeItem{ reference = tes3.player, item = common.staticConfigs.objectIds.firewood }
        event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, nodes = true})
    end,
}