local common = require ("mer.ashfall.common.common")
local WoodStack = require("mer.ashfall.items.woodStack")
local takeWood = WoodStack.buttons.takeWood
return {
    text = takeWood.text,
    tooltip = function()
        return common.helper.showHint(string.format(
            "You can take firewood directly by activating the wood stack while holding down %s.",
            common.helper.getModifierKeyString()
        ))
    end,
    enableRequirements = function(reference)
        return takeWood.enableRequirements{ reference = reference }
    end,
    tooltipDisabled = takeWood.tooltipDisabled,
    callback = function(reference)
        return takeWood.callback{reference = reference}
    end,
}