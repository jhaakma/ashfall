local common = require ("mer.ashfall.common.common")

return {
    text = "Add Grill",
    showRequirements = function(campfire)
        return ( 
            not campfire.data.hasGrill and
            campfire.data.dynamicConfig and
            campfire.data.dynamicConfig.grill == "dynamic"
           
        )
    end,
    enableRequirements = function(campfire)
        return mwscript.getItemCount{ reference = tes3.player, item = common.staticConfigs.objectIds.grill } > 0
    end,
    tooltipDisabled = {
        text = "Requires 1 Grill."
    },
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