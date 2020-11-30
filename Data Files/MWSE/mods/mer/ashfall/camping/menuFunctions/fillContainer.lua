local thirstController = require("mer.ashfall.needs.thirstController")
local common = require("mer.ashfall.common.common")
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
        --fill bottle
        local waterType
        local hasBrewedTea = (
            campfire.data.teaProgress and
            campfire.data.teaProgress >= 100 and
            teaConfig.teaTypes[campfire.data.waterType]
        )
        if hasBrewedTea  then
            waterType = campfire.data.waterType
        end

        local stewLevels
        local hasStew = (
            campfire.data.stewProgress and
            campfire.data.stewProgress >= 100 and
            campfire.data.stewLevels
        )
        if hasStew then
            stewLevels = campfire.data.stewLevels
        end
        thirstController.fillContainer{
            source = campfire,
            waterType = waterType,
            stewLevels = stewLevels,
            callback = function()
                if campfire.data.waterAmount <= 0 then
                    common.log:debug("Clearing utensil data")
                    event.trigger("Ashfall:Campfire_clear_utensils", { campfire = campfire})
                end
            end
        }
        
    end
}