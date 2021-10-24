local common = require ("mer.ashfall.common.common")
local LiquidContainer = require("mer.ashfall.objects.LiquidContainer")
local teaConfig       = require("mer.ashfall.config.teaConfig")

return {
    dropText = function(campfire, item, itemData)
        --Liquids
        local liquidContainer = LiquidContainer.createFromInventory(item, itemData)
        return string.format("Add %s", liquidContainer:getLiquidName())
    end,
    --onDrop for Stew handled separately, this only does tea
    canDrop = function(campfire, item, itemData)
        local liquidContainer = LiquidContainer.createFromInventory(item, itemData)
        return liquidContainer
    end,
    onDrop = function(campfire, reference)
        local from = LiquidContainer.createFromReference(reference)
        local to = LiquidContainer.createFromReference(campfire)
        if from and to then
            local waterAdded = from:transferLiquid(to)
            if waterAdded <= 0 then
                tes3.messageBox("Unable to transfer liquid.")
            end
            common.helper.pickUp(reference)
        end
    end
}

