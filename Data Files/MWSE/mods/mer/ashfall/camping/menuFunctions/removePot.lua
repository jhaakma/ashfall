local common = require ("mer.ashfall.common.common")

return  {
    text = "Remove Pot",
    showRequirements = function(campfire)
        return (
            campfire.data.dynamicConfig and
            campfire.data.dynamicConfig.cookingPot == "dynamic" and
            campfire.data.utensil == "cookingPot" and
            ( not campfire.data.waterAmount or
            campfire.data.waterAmount == 0 )
        )
    end,
    enableRequirements = function(campfire)
        return ( not campfire.data.waterAmount or
        campfire.data.waterAmount == 0 )
    end,
    tooltipDisabled = {
        text = "Cooking Pot must be emptied before it can be removed."
    },
    callback = function(campfire)
        mwscript.addItem{ reference = tes3.player, item = "Misc_Com_Bucket_Metal" }
        if campfire.data.ladle == true then
            mwscript.addItem{ reference = tes3.player, item = "misc_com_iron_ladle" }
        end
        event.trigger("Ashfall:Campfire_clear_utensils", { campfire = campfire, removeUtensil = true})
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
    end
}