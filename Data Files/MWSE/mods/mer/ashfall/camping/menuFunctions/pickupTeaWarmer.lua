local common = require ("mer.ashfall.common.common")

return {
    text = "Pick Up",
    callback = function(reference)
        timer.delayOneFrame(function()
            common.helper.pickUp(reference)
        end)
    end
}