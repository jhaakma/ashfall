local common = require ("mer.ashfall.common.common")
return {
    text = "Add Supports (requires 3 wood)",
    requirements = function(campfire)
        local numWood = mwscript.getItemCount{ reference = tes3.player, item = common.staticConfigs.objectIds.firewood}
        return (
            campfire.data.hasSupports ~= true and 
            numWood >= 3 and
            campfire.data.dynamicConfig and
            campfire.data.dynamicConfig.supports == "dynamic"
        )
    end,
    callback = function(campfire)
        mwscript.removeItem{
            reference = tes3.player, 
            item = common.staticConfigs.objectIds.firewood,
            count = 3
        }
        campfire.data.hasSupports = true
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
    end
}