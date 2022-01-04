local common = require ("mer.ashfall.common.common")
local LiquidContainer = require("mer.ashfall.objects.LiquidContainer")
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
        local liquidContainer = LiquidContainer.createFromInventory(item, itemData)
        local isModifierKeyPressed = common.helper.isModifierKeyPressed()
        if not liquidContainer then return false end
        if isModifierKeyPressed then --retrieving water from target
            return target.data.waterAmount and target.data.waterAmount > 0
        else --adding water to target
            return liquidContainer.waterAmount > 0
        end
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

