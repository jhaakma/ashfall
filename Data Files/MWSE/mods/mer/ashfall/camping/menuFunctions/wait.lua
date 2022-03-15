local animCtrl = require("mer.ashfall.animation.animationController")
local config = require("mer.ashfall.config").config
return {
    text = "Sit Down",
    enableRequirements = function()
        return tes3.canRest()
    end,
    showRequirements = function()
        return config.devFeatures
    end,
    tooltipDisabled = {
        header = "Sit Down",
        text = "You can't wait here; enemies are nearby."
    },
    callback = function()
        animCtrl.showFastTimeMenu{
            message = "Sit Down",
            anim = "sitting",
            recovering = true,
            speeds = { 2, 5, 10 }
        }
    end,
}