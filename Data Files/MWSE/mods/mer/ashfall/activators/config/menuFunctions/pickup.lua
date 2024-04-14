local common = require ("mer.ashfall.common.common")

return {
    text = "Pick Up",
    showRequirements = function(reference)

        if not reference.supportsLuaData then return false end
        return reference.data.utensilId == nil
            and common.staticConfigs.bottleList[reference.object.id:lower()] ~= nil
    end,
    tooltip = function()
        return common.helper.showHint(string.format(
            "You can pick this up directly by holding %s and activating.",
            common.helper.getModifierKeyString()
        ))
    end,
    callback = function(reference)
        local safeRef = tes3.makeSafeObjectHandle(reference)
        timer.delayOneFrame(function()
            if safeRef and safeRef:valid() then
                common.helper.pickUp(reference, true)
            end
        end)
    end
}