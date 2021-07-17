local common = require ("mer.ashfall.common.common")
local thirstController = require("mer.ashfall.needs.thirstController")
local teaConfig = common.staticConfigs.teaConfig

local function hasWaterAmount(campfire)
    return campfire.data.waterAmount and campfire.data.waterAmount > 0
end

local function hasJustWater(campfire)
    return (not teaConfig.teaTypes[campfire.data.waterType]) and ( not campfire.data.stewLevels )
end

local function hasBrewedTea(campfire)
    return campfire.data.teaProgress and campfire.data.teaProgress >= 100
end

local function hasStew(campfire)
    return not not campfire.data.stewProgress
end

local function isBoiling(campfire)
    return campfire.data.waterHeat >= 80
end

return {
    text = "Drink",
    showRequirements = function(campfire)
        return hasWaterAmount(campfire) 
        and (not hasStew(campfire))
        and (hasJustWater(campfire) or hasBrewedTea(campfire))
    end,
    enableRequirements = function(campfire)
        local tooHotToDrink =  hasWaterAmount(campfire) 
            and (not hasStew(campfire))
            and isBoiling(campfire) 
        if tooHotToDrink and not campfire.data.ladle then 
            return false 
        end
        return true
    end,
    tooltipDisabled = {
        text = "It is too hot to drink. Wait for it to cool down or transfer to a container first."
    },
    callback = function(campfire)
        local function doDrink()
            --tes3.playSound{ reference = tes3.player, sound = "Swallow" }

            local amountToDrink = math.min(campfire.data.waterCapacity, campfire.data.waterAmount)
            local amountDrank = thirstController.drinkAmount{ amount = amountToDrink, waterType = campfire.data.waterType,}
            campfire.data.waterAmount = campfire.data.waterAmount - amountDrank
            if campfire.data.teaProgress and campfire.data.teaProgress >= 100 then
                if amountDrank > 0 then
                    event.trigger("Ashfall:DrinkTea", { teaType = campfire.data.waterType, amountDrank = amountDrank})
                end
            end
            if campfire.data.waterAmount == 0 then
                event.trigger("Ashfall:Campfire_clear_utensils", { campfire = campfire})
            end
            --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
        end

        local utensilNames = {
            kettle = "Kettle",
            cookingPot = "Cooking Pot"
        }
        local utensilText = string.format("Empty %s", utensilNames[campfire.data.utensil])
        if campfire.data.waterType == "dirty" then
            common.helper.messageBox{
                message = "This water is dirty.",
                buttons = {
                    { 
                        text = "Drink Anyway", 
                        callback = function() doDrink() end 
                    },
                },
                doesCancel = true,
            }
        else
            doDrink()
        end
    end
}