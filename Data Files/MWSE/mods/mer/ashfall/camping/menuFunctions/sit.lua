local common = require ("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local animCtrl = require("mer.ashfall.effects.animationController")

return {
    text = "Sit Down",
    enableRequirements = function()
        return tes3.canRest()
    end,
    showRequirements = function()
        return config.devFeatures
    end,
    tooltipDisabled = {
        header = "Sit Down (Real Time)",
        text = "You can't wait here; enemies are nearby."
    },
    callback = function()
        common.data.recoveringFatigue = true
        animCtrl.sitDown{ recovering = true }
    end
}