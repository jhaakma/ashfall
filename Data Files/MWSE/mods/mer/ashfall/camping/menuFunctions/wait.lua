local fastTime = require("mer.ashfall.effects.fastTime")
local common = require("mer.ashfall.common.common")
local animCtrl = require("mer.ashfall.effects.animationController")
return {
    text = tes3.findGMST(tes3.gmst.sWait).value,
    enableRequirements = function()
        return tes3.canRest()
    end,
    tooltipDisabled = {
        header = "Wait",
        text = "You can't wait here; enemies are nearby."
    },
    callback = function()
        local canSit = common.config.getConfig().devFeatures
            and animCtrl.hasAnimFiles()
        fastTime.showFastTimeMenu{doSit = canSit }
    end,
}