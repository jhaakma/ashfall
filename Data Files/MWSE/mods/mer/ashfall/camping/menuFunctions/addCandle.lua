local common = require ("mer.ashfall.common.common")
--Calculate how much fuel is added per piece of firewood based on Survival skill

local CANDLE_MAX = 10



local function playerHasCandle()
    for _, stack in pairs(tes3.player.object.inventory) do
        if common.helper.itemIsCandle(stack.object) then
            return true
        end
    end
    return false
end

local function hasRoomForCandle(teaWarmer)
    local fuelLevel = teaWarmer.data.fuelLevel or 0
    return fuelLevel < CANDLE_MAX - 1
end

local function getDisabledText(campfire)
    return {
        text = hasRoomForCandle(campfire) and "You have no candles." or "Tea Warmer already has a candle."
    }
end

return {
    text = "Add Candle",
    enableRequirements = function(campfire)
        return playerHasCandle() and hasRoomForCandle(campfire)
    end,
    tooltipDisabled = getDisabledText,
    callback = function(campfire)
        tes3.playSound{
            reference = tes3.player,
            sound = "Item Misc Up",
            loop = false
        }
        campfire.data.fuelLevel = 10
        event.trigger("Ashfall:UpdateAttachNodes", { campfire = campfire})
    end,
}