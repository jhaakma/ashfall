local thirstController = require("mer.ashfall.needs.thirstController")
local common = require("mer.ashfall.common.common")
local teaConfig = common.staticConfigs.teaConfig

return  {
    text = "Fill Container",
    requirements = function(campfire)
        return (
            campfire.data.waterAmount and 
            campfire.data.waterAmount > 0 and
            not campfire.data.stewLevels and
            ( 
                (not teaConfig.teaTypes[campfire.data.waterType]) or
                campfire.data.teaProgress >= 100
            )
        )
    end,
    callback = function(campfire)
        --fill bottle
        local teaType
        local hasBrewedTea = (
            campfire.data.teaProgress and
            campfire.data.teaProgress >= 100 and
            teaConfig.teaTypes[campfire.data.waterType]
        )
        if hasBrewedTea  then
            teaType = campfire.data.waterType
        end
        thirstController.fillContainer{
            source = campfire,
            teaType = teaType,
            callback = function()
                if campfire.data.waterAmount <= 0 then
                    common.log:debug("Clearing utensil data")
                    event.trigger("Ashfall:Campfire_clear_utensils", { campfire = campfire})
                end
            end
        }
        
    end
}