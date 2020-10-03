local common = require ("mer.ashfall.common.common")
local thirstController = require("mer.ashfall.needs.thirstController")
local conditions = require("mer.ashfall.conditionController")
return {
    text = "Drink",
    requirements = function(campfire)
        return (
            campfire.data.waterAmount and 
            campfire.data.waterAmount > 0 and
            not campfire.data.stewLevels --and
            --conditions.thirst:getValue() <= 99
        )
    end,
    callback = function(campfire)
        local function doDrink()
            --tes3.playSound{ reference = tes3.player, sound = "Swallow" }
            local amountToDrink = math.min(common.staticConfigs.capacities[campfire.data.utensil], campfire.data.waterAmount)
            local amountDrank = thirstController.drinkAmount{ amount = amountToDrink, waterType = campfire.data.waterType,}
            campfire.data.waterAmount = campfire.data.waterAmount - amountDrank
            if campfire.data.waterAmount == 0 then
                event.trigger("Ashfall:Campfire_clear_utensils", { campfire = campfire})
            end
            if campfire.data.teaProgress and campfire.data.teaProgress >= 100 then
                if amountDrank > 0 then
                    event.trigger("Ashfall:DrinkTea", { teaType = campfire.data.waterType, amountDrank = amountDrank})
                end
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
                    },
                    { text = tes3.findGMST(tes3.gmst.sCancel).value }
                }
            }
        else
            doDrink()
        end
    end
}