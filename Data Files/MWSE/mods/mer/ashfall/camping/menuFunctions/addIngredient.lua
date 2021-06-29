local common = require ("mer.ashfall.common.common")
local foodConfig = common.staticConfigs.foodConfig
local skillSurvivalStewIngredIncrement  = 5
local stewIngredientCooldownAmount = 20

local foodTypes = {
    foodConfig.type.meat,
    foodConfig.type.vegetable,
    foodConfig.type.mushroom,
    foodConfig.type.seasoning,
    foodConfig.type.herb,
}

local function playerHasFood(foodType)
    for _, stack in pairs(tes3.player.object.inventory) do
        if foodConfig.getFoodTypeResolveMeat(stack.object) == foodType then
            return true
        end
    end
    return false
end

local function hasCapacityForIngred(campfire, foodType)
    return not campfire.data.stewLevels or
    not campfire.data.stewLevels[foodType] or 
    campfire.data.stewLevels[foodType] < 100
end



local function addIngredient(e)
    --Cool down stew
    e.campfire.data.stewProgress = e.campfire.data.stewProgress or 0
    e.campfire.data.stewProgress = math.max(( e.campfire.data.stewProgress - stewIngredientCooldownAmount ), 0)

    --initialise stew levels
    e.campfire.data.stewLevels = e.campfire.data.stewLevels or {}
    e.campfire.data.stewLevels[e.foodType] = e.campfire.data.stewLevels[e.foodType] or 0
    --Add ingredient to stew
    common.log:trace("old stewLevel: %s", e.campfire.data.stewLevels[e.foodType])
    local waterRatio = e.campfire.data.waterAmount / common.staticConfigs.capacities.cookingPot
    common.log:trace("waterRatio: %s", waterRatio)
    local ingredAmountToAdd = e.amount * common.staticConfigs.stewIngredAddAmount / waterRatio
    common.log:trace("ingredAmountToAdd: %s", ingredAmountToAdd)
    e.campfire.data.stewLevels[e.foodType] = math.min(e.campfire.data.stewLevels[e.foodType] + ingredAmountToAdd, 100)
    common.log:trace("new stewLevel: %s", e.campfire.data.stewLevels[e.foodType])

    common.skills.survival:progressSkill(skillSurvivalStewIngredIncrement*e.amount)
    tes3.player.object.inventory:removeItem{
        mobile = tes3.mobilePlayer,
        item = e.item,
        itemData = e.itemData,
        count = e.amount
    }
    tes3ui.forcePlayerInventoryUpdate()
    tes3.playSound{ reference = tes3.player, sound = "Swim Right" }
    --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
end



local function ingredientSelect(campfire, foodType)
    common.data.inventorySelectStew = true
    timer.delayOneFrame(function()
        common.log:debug("ingedient select menu for stew")
        tes3ui.showInventorySelectMenu{
            title = "Select Ingredient:",
            noResultsText = string.format("You do not have any %ss.", string.lower(foodType)),
            filter = function(e)
                return (
                    foodConfig.getFoodTypeResolveMeat(e.item) == foodType
                    --Can only grill meat and veges
                )
            end,
            callback = function(e) --select how many
                common.data.inventorySelectStew = nil
                if e.item then
                    common.log:debug("Selecting ingredient amount for stew")
                    local waterRatio = campfire.data.waterAmount / common.staticConfigs.capacities.cookingPot
                    local stewLevel = (campfire.data.stewLevels and campfire.data.stewLevels[foodType] or 0)
                    local adjustedIngredAmount = common.staticConfigs.stewIngredAddAmount / waterRatio
                    common.log:debug("adjustedIngredAmount: %s", adjustedIngredAmount)
                    local rawCapacity = 100 - stewLevel
                    common.log:debug("rawCapacity: %s", rawCapacity)
                    local capacity = math.ceil(rawCapacity / adjustedIngredAmount)
                    common.log:debug("capacity: %s", capacity)
                    local max = math.min(
                        mwscript.getItemCount{ reference = tes3.player, item = e.item },
                        capacity
                    )
                    common.log:debug("max: %s", max)
                    e.amount = 1
                    e.campfire = campfire
                    e.foodType = foodType
                    if max > 1 then
                        common.helper.createSliderPopup{
                            label = "How many?",
                            min = 0,
                            max = max,
                            jump = 1,
                            table = e,
                            varId = "amount",
                            okayCallback = function()
                                addIngredient(e)
                            end
                        }
                    else
                        addIngredient(e)
                    end
                end
            end
        }
    end)
end


return {
    text = "Add Ingredient",
    showRequirements = function(campfire)
        return campfire.data.utensil == "cookingPot"
            and campfire.data.waterAmount 
            and campfire.data.waterAmount > 0
    end,
    enableRequirements = function(campfire)
        return  campfire.data.ladle == true
    end,
    tooltipDisabled = {
        text = "An Iron Ladle is required to make Stew."
    },
    callback = function(campfire)

        --add buttons for ingredients that can be added
        local buttons = {}
        for _, foodType in ipairs(foodTypes) do
            local hasFood =  playerHasFood(foodType)
            local hasCapacity  =  hasCapacityForIngred(campfire, foodType)

            table.insert(buttons, { 
                text = foodType, 
                callback = function() ingredientSelect(campfire, foodType) end,
                requirements = function()
                    return hasFood and hasCapacity
                end,
                tooltipDisabled = {
                    text = hasFood and string.format("You cannot add any more %s.", foodType)
                        or string.format("You do not have any %s.", foodType)
                },
                tooltip = {
                    text = foodConfig.getStewBuffForFoodType(foodType).ingredTooltip or foodType
                }
            })

        end
        common.helper.messageBox({
            message = "Select Ingredient Type:",
            buttons = buttons,
            doesCancel = true,
        })
    end
}