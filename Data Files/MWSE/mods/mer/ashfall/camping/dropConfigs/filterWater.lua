local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("douse")
local LiquidContainer = require("mer.ashfall.objects.LiquidContainer")

return {
    dropText = function(campfire, item, itemData)
        return "Filter Water"
    end,
    canDrop = function(campfire, item, itemData)
        local liquidContainer = LiquidContainer.createFromInventory(item, itemData)
        if not liquidContainer then
            return false
        end

        local hasWater = liquidContainer and liquidContainer.waterAmount > 0
        if not hasWater then
            return false
        end

        local isDirty = liquidContainer:getLiquidType() == "dirty"
        return isDirty
    end,
    onDrop  = function(campfire, reference)
        local waterContainer = LiquidContainer.createFromReference(reference)
        waterContainer.data.waterType = nil
        tes3.playSound{ sound = "Swim Right"}
        tes3.messageBox("You filter the water from %s.", reference.object.name)
        common.helper.pickUp(reference)
    end
}