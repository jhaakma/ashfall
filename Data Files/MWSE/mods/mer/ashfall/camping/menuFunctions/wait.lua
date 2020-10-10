local fastTime = require("mer.ashfall.effects.fastTime")
return {
    text = tes3.findGMST(tes3.gmst.sWait).value,
    enableRequirements = function()
        return tes3.canRest()
    end,
    tooltip = {
        header = "Wait",
        text = "Wait at the campfire, speeing up time for up to an hour."
    },
    tooltipDisabled = {
        header = "Wait",
        text = "You can't wait here; enemies are nearby."
    },
    callback = function()
        fastTime.showFastTimeMenu()
    end,
}