local common = require ("mer.ashfall.common.common")
local thirstController = require("mer.ashfall.needs.thirstController")
local teaConfig = common.staticConfigs.teaConfig

return {
    text = "Drink",
    showRequirements = function(campfire)
        local hasWaterAmount = campfire.data.waterAmount and campfire.data.waterAmount > 0
        local hasJustWater = (not teaConfig.teaTypes[campfire.data.waterType]) and ( not campfire.data.stewLevels )
        local hasBrewedTea = campfire.data.teaProgress and campfire.data.teaProgress >= 100
        local hasStew = campfire.data.stewProgress
        return hasWaterAmount and not hasStew and (hasJustWater or hasBrewedTea)
    end,
    callback = function(campfire)
        local function doDrink()
            --tes3.playSound{ reference = tes3.player, sound = "Swallow" }

            local amountToDrink = math.min(common.staticConfigs.capacities[campfire.data.utensil], campfire.data.waterAmount)
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
                        text = "Drink", 
                        callback = function() doDrink() end 
                    },
                    { 
                        text = utensilText, 
                        callback = function()
                            tes3.playSound{ reference = tes3.player, pitch = 0.8, sound = "Swim Left"} 
                            event.trigger("Ashfall:Campfire_clear_utensils", { campfire = campfire})
                            --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
                        end
                    }
                },
                doesCancel = true,
            }
        else
            doDrink()
        end
    end
}