local common = require ("mer.ashfall.common.common")

return {
    text = "Pick Up",
    showRequirements = function(campfire)
        return campfire.data.utensilId == nil
            and common.staticConfigs.bottleList[campfire.object.id:lower()] ~= nil
    end,
    callback = function(reference)
        local safeRef = tes3.makeSafeObjectHandle(reference)
        timer.delayOneFrame(function()
            if safeRef:valid() then
                common.helper.pickUp(reference, true)
            end
        end)
    end
}