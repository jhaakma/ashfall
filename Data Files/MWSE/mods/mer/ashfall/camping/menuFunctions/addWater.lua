local common = require ("mer.ashfall.common.common")
local thirstController = require("mer.ashfall.needs.thirstController")
local LiquidContainer   = require("mer.ashfall.objects.LiquidContainer")
local campfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")
local teaConfig = common.staticConfigs.teaConfig
return {
    text = "Add Water",
    showRequirements = function(campfire)

        local maxCapacity = campfireUtil.getUtensilCapacity{
            dataHolder = campfire,
            object = campfire.object
        }
        local needsWater = (
            not campfire.data.waterAmount or
            campfire.data.waterAmount < maxCapacity
        )
        local hasUtensil = (
            campfire.data.utensil == "kettle" or
            campfire.data.utensil == "cookingPot"
        )
        local isTea = teaConfig.teaTypes[campfire.data.waterType] ~= nil
        return needsWater and hasUtensil and not isTea
    end,
    callback = function(campfire)
        local to = LiquidContainer.createFromReference(campfire)
        timer.delayOneFrame(function()
            tes3ui.showInventorySelectMenu{
                title = "Select Water Container:",
                noResultsText = "You do not have any water.",
                filter = function(e)
                    local from = LiquidContainer.createFromInventory(e.item, e.itemData)
                    return from and from:canTransfer(to) or false
                end,
                callback = function(e)
                    if e.item then
                        local from = LiquidContainer.createFromInventory(e.item, e.itemData)

                        local capacityRemainingInPot = to.capacity - to.waterAmount
                        local maxAmount = math.min(from.waterAmount, capacityRemainingInPot)
                        local t = { amount = maxAmount }
                        common.helper.createSliderPopup{
                            label = "Add water",
                            min = 1,
                            max = maxAmount,
                            varId = "amount",
                            table = t,
                            okayCallback = function()
                                from:transferLiquid(to, t.amount)
                            end
                        }
                    end
                end
            }
        end)

    end
}