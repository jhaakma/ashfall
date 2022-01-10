local common = require ("mer.ashfall.common.common")
local LiquidContainer = require("mer.ashfall.objects.LiquidContainer")
return {
    dropText = function(campfire, item, itemData)
        return "Extinguish"
    end,
    canDrop = function(campfire, item, itemData)
        if not common.helper.isModifierKeyPressed() then
            return false
        end
        local liquidContainer = LiquidContainer.createFromInventory(item, itemData)

        if not liquidContainer then
            return false
        end

        local hasWater = liquidContainer and liquidContainer.waterAmount > 0
        if not hasWater then
            return false
        end

        local fireLit = campfire.data.isLit
        if not fireLit then
            return false, "Campfire is not lit."
        end


        local isStew = liquidContainer.waterType == "stew"
        if isStew then
            return false, "Invalid liquid type."
        end

        return true
    end,
    onDrop = function(campfire, reference)
        if not common.helper.isModifierKeyPressed() then return end
        local liquidContainer = LiquidContainer.createFromReference(reference)
        if liquidContainer then
            event.trigger("Ashfall:fuelConsumer_Extinguish", {fuelConsumer = campfire, playSound = true})
            liquidContainer:transferLiquid(LiquidContainer.createInfiniteWaterSource(), 10)
            tes3.playSound{ reference = tes3.player, sound = "Swim Left" }
            common.helper.pickUp(reference)
        else
            common.log:error("Not a liquid container somehow")
        end
    end
}