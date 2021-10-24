local thirstController = require("mer.ashfall.needs.thirstController")
local common = require("mer.ashfall.common.common")
local LiquidContainer = require("mer.ashfall.objects.LiquidContainer")
local teaConfig = common.staticConfigs.teaConfig

return  {
    text = "Fill Container",
    showRequirements = function(campfire)
        local hasWaterAmount = campfire.data.waterAmount and campfire.data.waterAmount > 0
        local hasJustWater = (not teaConfig.teaTypes[campfire.data.waterType]) and ( not campfire.data.stewLevels )
        local hasBrewedTea = campfire.data.teaProgress and campfire.data.teaProgress >= 100
        local hasCookedStew = campfire.data.stewProgress and campfire.data.stewProgress >= 100
        return hasWaterAmount and (hasJustWater or hasBrewedTea or hasCookedStew)
    end,
    callback = function(campfire)
        thirstController.fillContainer{
            source = LiquidContainer.createFromReference(campfire),
            callback = function()
                if (not campfire.data.waterAmount) or campfire.data.waterAmount <= 0 then
                    common.log:debug("FILLCONTAINER Clearing utensil data")
                    event.trigger("Ashfall:Campfire_clear_utensils", { campfire = campfire})
                end
            end
        }
        timer.delayOneFrame(function()
            event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire,})
        end)

    end
}