local common = require ("mer.ashfall.common.common")
local config = require("mer.ashfall.config").config
local thirstController = require("mer.ashfall.needs.thirstController")
local LiquidContainer   = require("mer.ashfall.liquid.LiquidContainer")
local campfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")
local teaConfig = common.staticConfigs.teaConfig
local logger = common.createLogger("MenuFunction:AddWater")

return {
    text = "Add Water",
    showRequirements = function(targetRef)

        local maxCapacity = campfireUtil.getUtensilCapacity{
            dataHolder = targetRef,
            object = targetRef.object
        }

        local needsWater = (not targetRef.data.waterAmount)
            or targetRef.data.waterAmount < maxCapacity

        local isTea = teaConfig.teaTypes[targetRef.data.waterType] ~= nil
        return needsWater and campfireUtil.isWaterContainer(targetRef) and not isTea
    end,
    tooltip = function()
        return common.helper.showHint(
            "You can add water by dragging and dropping a water-filled container directly onto the target."
        )
    end,
    callback = function(reference)
        local to = LiquidContainer.createFromReference(reference)
        if to == nil then
            logger:error("Could not create liquid container from reference %s", reference.id)
            return
        end
        timer.delayOneFrame(function()
            common.helper.showInventorySelectMenu{
                title = "Select Water Container:",
                noResultsText = ("You don't have any %s."):format(to:getLiquidName()),
                filter = function(e)
                    local from = LiquidContainer.createFromInventory(e.item, e.itemData)
                    return from and from:canTransfer(to) or false
                end,
                callback = function(e)
                    if e.item then
                        local from = LiquidContainer.createFromInventory(e.item, e.itemData)
                        if not from then logger:error("Unable to create liquid container from %s", e.item.id) return end

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