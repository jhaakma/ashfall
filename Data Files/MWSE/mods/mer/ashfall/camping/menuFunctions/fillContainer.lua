local thirstController = require("mer.ashfall.needs.thirstController")
local common = require("mer.ashfall.common.common")
local logger = common.createLogger("fillContainer")
local LiquidContainer = require("mer.ashfall.objects.LiquidContainer")

return  {
    text = "Fill Container",
    showRequirements = function(reference)
        ---@type AshfallLiquidContainer
        local source = LiquidContainer.createFromReference(reference)
        local hasWaterAmount = source.waterAmount > 0
        local isWater = source:isWater()
        local isTea = source:isBrewedTea()
        local isStew = source:isCookedStew()

        return hasWaterAmount and (isWater or isTea or isStew)
    end,
    enableRequirements = function(reference)
        ---@type AshfallLiquidContainer
        local source = LiquidContainer.createFromReference(reference)
        local playerHasEmpties = thirstController.playerHasEmpties(source)
        return playerHasEmpties
    end,
    tooltipDisabled = {
        text = common.messages.noContainersToFill
    },
    callback = function(reference)
        thirstController.fillContainer{
            source = LiquidContainer.createFromReference(reference),
            callback = function()
                if (not reference.data.waterAmount) or reference.data.waterAmount <= 0 then
                    logger:debug("FILLCONTAINER Clearing utensil data")
                    event.trigger("Ashfall:Campfire_clear_utensils", { campfire = reference})
                end
            end
        }
        timer.delayOneFrame(function()
            event.trigger("Ashfall:UpdateAttachNodes", {campfire = reference,})
        end)

    end
}