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
        return mwscript.getItemCount{ reference = tes3.player, item = "Misc_Com_Bucket_Metal" } > 0
    end,
    tooltipDisabled = { 
        text = "Requires 1 Metal Bucket."
    },
    callback = function(campfire)
        mwscript.removeItem{ reference = tes3.player, item = "Misc_Com_Bucket_Metal" }
        campfire.data.utensil = "cookingPot"
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Down"  }
        if mwscript.getItemCount{ reference = tes3.player, item = "misc_com_iron_ladle"} > 0 then
            mwscript.removeItem{ reference = tes3.player, item = "misc_com_iron_ladle" }
            campfire.data.ladle = true
        end
        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
    end
}