local fastTime = require("mer.ashfall.effects.fastTime")
return {
    text = tes3.findGMST(tes3.gmst.sWait).value,
    requirements = function()
        return true
    end,
    callback = function()
        fastTime.showFastTimeMenu()
    end,
}