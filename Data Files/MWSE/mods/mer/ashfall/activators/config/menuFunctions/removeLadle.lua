local common = require ("mer.ashfall.common.common")

return  {
    text = "Remove Ladle",
    showRequirements = function(campfire)
        return (
            (
                (not campfire.data.dynamicConfig) or
                (campfire.data.dynamicConfig.ladle ~= "static")
            )
            and campfire.data.ladle
        )
    end,
    enableRequirements = function(campfire)
        local hasUncookedStew = campfire.data.stewLevels
            and campfire.data.stewProgress
            and campfire.data.stewProgress < 100
        return not hasUncookedStew
    end,
    tooltipDisabled = {
        text = "Empty or finish cooking stew before removing ladle."
    },
    callback = function(campfire)
        local ladleId = "misc_com_iron_ladle" -- Default for legacy ladle boolean
        if campfire.data.ladle and type(campfire.data.ladle) == "string" then
            ladleId = campfire.data.ladle
        end
        tes3.addItem{ reference = tes3.player, item = ladleId }
        campfire.data.ladle = nil
        event.trigger("Ashfall:UpdateAttachNodes", { reference = campfire})
    end
}