return {
    text = "Attach Kettle",
    showRequirements = function(campfire)
        return (
            campfire.data.hasSupports and
            not campfire.data.utensil and
            campfire.data.dynamicConfig and
            campfire.data.dynamicConfig.kettle == "dynamic"
        )
    end,
    enableRequirements = function()
        return mwscript.getItemCount{ reference = tes3.player, item = "ashfall_kettle"} > 0
    end,
    tooltipDisabled = { 
        text = "Requires 1 Kettle."
    },
    callback = function(campfire)
        mwscript.removeItem{ reference = tes3.player, item = "ashfall_kettle" }
        campfire.data.utensil = "kettle"
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Down"  }
        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
    end
}