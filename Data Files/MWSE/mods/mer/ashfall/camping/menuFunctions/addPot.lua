local common = require ("mer.ashfall.common.common")

return  {
    text = "Attach Cooking Pot",
    showRequirements = function(campfire)
        return (
            campfire.data.hasSupports and 
            campfire.data.utensil == nil and
            campfire.data.dynamicConfig and
            campfire.data.dynamicConfig.cookingPot == "dynamic"
        )
    end,
    enableRequirements = function()
        return mwscript.getItemCount{ reference = tes3.player, item = common.staticConfigs.objectIds.cookingPot} > 0
    end,
    tooltipDisabled = { 
        text = "You have no Cooking Pot."
    },
    callback = function(campfire)
        mwscript.removeItem{ reference = tes3.player, item = common.staticConfigs.objectIds.cookingPot }
        campfire.data.utensil = "cookingPot"
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Down"  }
        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
    end
}