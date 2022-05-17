local common = require ("mer.ashfall.common.common")
local LiquidContainer = require("mer.ashfall.liquid.LiquidContainer")
return {
    dropText = function(target, item, itemData)
        --Liquids
        local isModifierKeyPressed = common.helper.isModifierKeyPressed()
        if isModifierKeyPressed then --retrieving water from target
            local liquidContainer = LiquidContainer.createFromReference(target)
            return string.format("Retrieve %s", liquidContainer:getLiquidName())
        else --adding water to target
            local liquidContainer = LiquidContainer.createFromInventory(item, itemData)
            return string.format("Add %s", liquidContainer:getLiquidName())
        end
    end,
    --onDrop for Stew handled separately, this only does tea
    canDrop = function(target, item, itemData)
        local itemLiquidContainer = LiquidContainer.createFromInventory(item, itemData)
        local targetLiquidContainer = LiquidContainer.createFromReference(target)
        if not itemLiquidContainer then return false end
        if not targetLiquidContainer then return false end

        local isModifierKeyPressed = common.helper.isModifierKeyPressed()
        if isModifierKeyPressed then --retrieving water from target
            if targetLiquidContainer.waterAmount <= 0 then
                return false, "No water to retrieve."
            end
            local canTransfer, errorMsg = targetLiquidContainer:canTransfer(itemLiquidContainer)
            if not canTransfer then
                return false, errorMsg
            end
        else --adding water to target
            if not (itemLiquidContainer.waterAmount > 0) then
                return false, "No water to pour."
            end
            local canTransfer, errorMsg = itemLiquidContainer:canTransfer(targetLiquidContainer)
            if not canTransfer then
                return false, errorMsg
            end
        end
        return true
    end,
    onDrop = function(target, reference)
        local from = LiquidContainer.createFromReference(reference)
        local to = LiquidContainer.createFromReference(target)
        if from and to then
            local waterAdded
            local errorMsg
            if common.helper.isModifierKeyPressed() then --retrieving water from target
                waterAdded, errorMsg = to:transferLiquid(from)
            else --adding water to target
                waterAdded, errorMsg = from:transferLiquid(to)
            end
            if waterAdded <= 0 then
                tes3.messageBox(errorMsg or "Unable to transfer liquid.")
            end
            common.helper.pickUp(reference)
        end
    end
}

