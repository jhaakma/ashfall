local animCtrl = require("mer.ashfall.effects.animationController")
return {
    text = "Sit Down",
    enableRequirements = function()
        return tes3.canRest()
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