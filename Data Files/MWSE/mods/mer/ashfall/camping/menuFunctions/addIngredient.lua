local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("addIngredient")
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")
local foodConfig = common.staticConfigs.foodConfig
local LiquidContainer = require("mer.ashfall.liquid.LiquidContainer")

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

local function hasCapacityForIngred(reference, foodType)
    return not reference.data.stewLevels or
    not reference.data.stewLevels[foodType] or
    reference.data.stewLevels[foodType] < 100
end



local function addIngredient(e)
    CampfireUtil.addIngredToStew{
        campfire = e.campfire,
        item = e.item,
        itemData = e.itemData,
        count = e.amount,
    }
    tes3.player.object.inventory:removeItem{
        mobile = tes3.mobilePlayer,
        item = e.item,
        itemData = e.itemData,
        count = e.amount
    }
    tes3ui.forcePlayerInventoryUpdate()
    event.trigger("Ashfall:UpdateAttachNodes", { campfire = e.campfire})
end



local function ingredientSelect(campfire, foodType)
    common.data.inventorySelectStew = true
    timer.delayOneFrame(function()
        logger:debug("ingedient select menu for stew")
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
                    logger:debug("Selecting ingredient amount for stew")
                    local liquidContainer = LiquidContainer.createFromReference(campfire)
                    local capacity = liquidContainer:getStewCapacity(foodType)
                    local max = math.min(
                        tes3.getItemCount{ reference = tes3.player, item = e.item },
                        capacity
                    )
                    logger:debug("max: %s", max)
                    e.amount = 1
                    e.campfire = campfire
                    e.foodType = foodType
                    if max > 1 and not (e.itemData and e.itemData.data) then
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
    showRequirements = function(ref)
        local isCookingPot = ref.data.utensil == "cookingPot"
            or common.staticConfigs.cookingPots[ref.object.id:lower()]
        local hasWater = ref.data.waterAmount
            and ref.data.waterAmount > 0
        return isCookingPot and hasWater
    end,
    enableRequirements = function(ref)
        return  not not ref.data.ladle
    end,
    tooltipDisabled = {
        text = "An Iron Ladle is required to make Stew."
    },
    callback = function(reference)
        --add buttons for ingredients that can be added
        local buttons = {}
        for _, foodType in ipairs(foodTypes) do
            local hasFood =  playerHasFood(foodType)
            local hasCapacity  =  hasCapacityForIngred(reference, foodType)

            table.insert(buttons, {
                text = foodType,
                callback = function() ingredientSelect(reference, foodType) end,
                enableRequirements = function()
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