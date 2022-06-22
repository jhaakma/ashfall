local common = require ("mer.ashfall.common.common")

return {
    text = "Pick Up",
    tooltip = function()
        return common.helper.showHint(string.format(
            "You can pick this up directly by holding %s and activating.",
            common.helper.getModifierKeyString()
        ))
    end,
    callback = function(reference)
        timer.delayOneFrame(function()
            common.helper.pickUp(reference)
        end)
    end
}