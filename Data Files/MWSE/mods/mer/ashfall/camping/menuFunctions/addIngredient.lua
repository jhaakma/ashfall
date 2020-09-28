local common = require ("mer.ashfall.common.common")
local foodConfig = common.staticConfigs.foodConfig
local skillSurvivalStewIngredIncrement  = 5
local stewIngredientCooldownAmount = 20
return {
    text = "Add Ingredient",
    requirements = function(campfire)
        return (
            campfire.data.utensil == "cookingPot" and
            campfire.data.waterAmount and
            campfire.data.waterAmount > 0
        )
    end,
    callback = function(campfire)
        local function ingredientSelect(foodType)
            common.data.inventorySelectStew = true
            timer.delayOneFrame(function()
                tes3ui.showInventorySelectMenu{
                    title = "Select Ingredient:",
                    noResultsText = string.format("You do not have any %ss.", string.lower(foodType)),
                    filter = function(e)
                        return (
                            e.item.objectType == tes3.objectType.ingredient and
                            foodConfig.getFoodTypeResolveMeat(e.item.id) == foodType
                            --Can only grill meat and veges
                        )
                    end,
                    callback = function(e)
                        common.data.inventorySelectStew = nil
                        if e.item then
                            --Cool down stew
                            campfire.data.stewProgress = campfire.data.stewProgress or 0
                            campfire.data.stewProgress = math.max(( campfire.data.stewProgress - stewIngredientCooldownAmount ), 0)

                            --initialise stew levels
                            campfire.data.stewLevels = campfire.data.stewLevels or {}
                            campfire.data.stewLevels[foodType] = campfire.data.stewLevels[foodType] or 0

                            --Add ingredient to stew
                            campfire.data.stewLevels[foodType] = (
                                campfire.data.stewLevels[foodType] +
                                (
                                    (
                                        common.staticConfigs.capacities.cookingPot / campfire.data.waterAmount
                                    ) / common.staticConfigs.stewMealCapacity
                                ) * 100
                            )

                            common.skills.survival:progressSkill(skillSurvivalStewIngredIncrement)

                            
                            tes3.player.object.inventory:removeItem{
                                mobile = tes3.mobilePlayer,
                                item = e.item,
                                itemData = e.itemData
                            }
                            tes3ui.forcePlayerInventoryUpdate()
                            tes3.playSound{ reference = tes3.player, sound = "Swim Right" }
                            --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
                        end
                    end
                }
            end)
        end
        local ingredButtons = {
            { text = foodConfig.TYPE.meat, callback = function() ingredientSelect(foodConfig.TYPE.meat) end },
            { text = foodConfig.TYPE.vegetable, callback = function() ingredientSelect(foodConfig.TYPE.vegetable) end },
            { text = foodConfig.TYPE.mushroom, callback = function() ingredientSelect(foodConfig.TYPE.mushroom) end },
            { text = foodConfig.TYPE.seasoning, callback = function() ingredientSelect(foodConfig.TYPE.seasoning) end },
            { text = foodConfig.TYPE.herb, callback = function() ingredientSelect(foodConfig.TYPE.herb) end },

        }
        local buttons = {}
        --add buttons for ingredients that can be added
        for _, button in ipairs(ingredButtons) do
            local foodType = button.text

            local hasCapacityForIngred = (
                not campfire.data.stewLevels or
                not campfire.data.stewLevels[foodType] or 
                campfire.data.stewLevels[foodType] < 100
            )
            if hasCapacityForIngred then
                local hasIngredient = false
                for _, stack in pairs(tes3.player.object.inventory) do
                    if foodConfig.getFoodTypeResolveMeat(stack.object.id) == foodType then
                        hasIngredient = true
                        break
                    end
                end

                if hasIngredient then
                    table.insert(buttons, button)
                end
            end
        end

        if #buttons > 0 then
            table.insert(buttons, { text = tes3.findGMST(tes3.gmst.sCancel).value })

            common.helper.messageBox({
                message = "Select Ingredient Type:",
                buttons = buttons
            })
        else
            tes3.messageBox("You do not have any ingredients.", {"Okay"})
        end
    end
}