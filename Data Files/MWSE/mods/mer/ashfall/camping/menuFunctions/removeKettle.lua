return {
    text = "Remove Kettle",
    requirements = function(campfire)
        return (
            campfire.data.dynamicConfig and
            campfire.data.dynamicConfig.kettle == "dynamic" and
            campfire.data.utensil == "kettle" and
            ( not campfire.data.waterAmount or
            campfire.data.waterAmount == 0 )
        )
    end,
    callback = function(campfire)
        mwscript.addItem{ reference = tes3.player, item = "ashfall_kettle" }
        event.trigger("Ashfall:Campfire_clear_utensils", { campfire = campfire, removeUtensil = true})
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
    end
}