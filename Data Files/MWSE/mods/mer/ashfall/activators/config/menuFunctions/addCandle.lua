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
    enableRequirements = function(reference)
        return reference.supportsLuaData
            and playerHasCandle()
            and hasRoomForCandle(reference)
            and not common.helper.getRefUnderwater(reference)
    end,
    tooltipDisabled = getDisabledText,
    callback = function(reference)
        tes3.playSound{
            reference = tes3.player,
            sound = "Item Misc Up",
            loop = false
        }
        reference.data.fuelLevel = 10
        event.trigger("Ashfall:UpdateAttachNodes", { reference = reference})
    end,
}