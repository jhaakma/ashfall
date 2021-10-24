local common = require ("mer.ashfall.common.common")

return  {
    text = "Remove Ladle",
    showRequirements = function(campfire)
        return (
            campfire.data.dynamicConfig and
            campfire.data.dynamicConfig.cookingPot == "dynamic" and
            campfire.data.ladle == true
        )
    end,
    enableRequirements = function(campfire)
        return not campfire.data.stewLevels
    end,
    tooltipDisabled = {
        text = "Empty Stew before removing Ladle."
    },
    callback = function(campfire)
        tes3.addItem{ reference = tes3.player, item = "misc_com_iron_ladle" }
        campfire.data.ladle = false
        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
    end
}