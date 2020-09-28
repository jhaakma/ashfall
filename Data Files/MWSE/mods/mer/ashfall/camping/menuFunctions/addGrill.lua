local common = require ("mer.ashfall.common.common")

return {
    text = "Add Grill",
    requirements = function(campfire)
        return ( 
            not campfire.data.hasGrill and
            campfire.data.dynamicConfig and
            campfire.data.dynamicConfig.grill == "dynamic" and
            mwscript.getItemCount{ reference = tes3.player, item = common.staticConfigs.objectIds.grill } > 0
        )
    end,
    callback = function(campfire)
        mwscript.removeItem{
            reference = tes3.player, 
            item = "ashfall_grill",
            count = 1
        }
        campfire.data.hasGrill = true
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
    end
    ,
}