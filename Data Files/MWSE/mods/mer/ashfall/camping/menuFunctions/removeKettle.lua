return {
    text = "Remove Kettle",
    showRequirements = function(campfire)
        return (
            campfire.data.dynamicConfig and
            campfire.data.dynamicConfig.kettle == "dynamic" and
            campfire.data.utensil == "kettle"
        )
    end,
    enableRequirements = function(campfire)
        return ( not campfire.data.waterAmount or
        campfire.data.waterAmount == 0 )
    end,
    tooltipDisabled = {
        text = "Kettle must be emptied before it can be removed."
    },
    callback = function(campfire)
        local kettleId = campfire.data.kettleId or "ashfall_kettle"
        mwscript.addItem{ reference = tes3.player, item = kettleId }
        event.trigger("Ashfall:Campfire_clear_utensils", { campfire = campfire, removeUtensil = true})
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})

        campfire.data.kettleId = nil
        event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire,})
    end
}