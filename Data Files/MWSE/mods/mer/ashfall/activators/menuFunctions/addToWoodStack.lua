local WoodStack = require("mer.ashfall.items.woodStack")
local addWood = WoodStack.buttons.addWood
return {
    text = addWood.text,
    tooltip = addWood.tooltip,
    enableRequirements = function(reference)
        return addWood.enableRequirements{ reference = reference }
    end,
    tooltipDisabled = addWood.tooltipDisabled,
    callback = function(reference)
        return addWood.callback{reference = reference}
    end,
}