local common = require ("mer.ashfall.common.common")

return  {
    text = "Remove Ladle",
    showRequirements = function(reference)
        if not reference.supportsLuaData then return false end
        return (
            (
                (not reference.data.dynamicConfig) or
                (reference.data.dynamicConfig.ladle ~= "static")
            )
            and reference.data.ladle
        )
    end,
    enableRequirements = function(reference)
        local hasUncookedStew = reference.data.stewLevels
            and reference.data.stewProgress
            and reference.data.stewProgress < 100
        return not hasUncookedStew
    end,
    tooltipDisabled = {
        text = "Empty or finish cooking stew before removing ladle."
    },
    callback = function(reference)
        local ladleId = "misc_com_iron_ladle" -- Default for legacy ladle boolean
        if reference.data.ladle and type(reference.data.ladle) == "string" then
            ladleId = reference.data.ladle
        end
        tes3.addItem{ reference = tes3.player, item = ladleId }
        reference.data.ladle = nil
        event.trigger("Ashfall:UpdateAttachNodes", { reference = reference})
    end
}