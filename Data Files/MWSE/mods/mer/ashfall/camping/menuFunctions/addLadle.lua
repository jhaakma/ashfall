return {
    text = "Add Ladle",
    showRequirements = function(campfire)
        return (
            campfire.data.hasSupports and
            campfire.data.utensil == "cookingPot" and
            not campfire.data.ladle and
            campfire.data.dynamicConfig and
            campfire.data.dynamicConfig.kettle == "dynamic"
        )
    end,
    enableRequirements = function()
        return mwscript.getItemCount{ reference = tes3.player, item = "misc_com_iron_ladle"} > 0
    end,
    tooltipDisabled = { 
        text = "Requires 1 Iron Ladle."
    },
    callback = function(campfire)
        mwscript.removeItem{ reference = tes3.player, item = "misc_com_iron_ladle" }
        campfire.data.ladle = true
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Down"  }
        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
    end
}