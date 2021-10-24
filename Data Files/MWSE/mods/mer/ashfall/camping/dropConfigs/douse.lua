local common = require ("mer.ashfall.common.common")
local LiquidContainer = require("mer.ashfall.objects.LiquidContainer")
return {
    dropText = function(campfire, item, itemData)
        return string.format("Extinguish")
    end,
    canDrop = function(campfire, item, itemData)
        local id = item.id:lower()
        local liquidContainer = LiquidContainer.createFromInventory(item, itemData)
        if liquidContainer then
            local fireLit = campfire.data.isLit
            local hasWater = liquidContainer and liquidContainer.waterAmount > 0
            local isStew = liquidContainer.waterType == "stew"
            return fireLit and hasWater and not isStew
        end
        return false
    end,
    onDrop = function(campfire, reference)
        local id = reference.object.id:lower()
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