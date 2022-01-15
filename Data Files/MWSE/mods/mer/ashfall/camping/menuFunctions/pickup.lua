local common = require ("mer.ashfall.common.common")

return {
    text = "Pick Up",
    showRequirements = function(campfire)
        return campfire.data.utensilId == nil
            and common.staticConfigs.bottleList[campfire.object.id:lower()] ~= nil
    end,
    callback = function(reference)
        timer.delayOneFrame(function()
            common.helper.pickUp(reference)
        end)
    end
}