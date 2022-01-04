local common = require ("mer.ashfall.common.common")

return {
    text = "Pick Up",
    showRequirements = function(reference)
        return common.staticConfigs.utensils[reference.object.id:lower()]
    end,
    callback = function(reference)
        timer.delayOneFrame(function()
            common.helper.pickUp(reference)
        end)
    end
}