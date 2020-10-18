local common = require ("mer.ashfall.common.common")
local animCtrl = require("mer.ashfall.effects.animationController")

return {
    text = "Sit Down",
    enableRequirements = function()
        return tes3.canRest()
    end,
    showRequirements = function()
        return common.config.getConfig().devFeatures
            and animCtrl.hasAnimFiles()
    end,
    tooltipDisabled = {
        header = "Sit Down",
        text = "You can't wait here; enemies are nearby."
    },
    callback = animCtrl.sitDown
}