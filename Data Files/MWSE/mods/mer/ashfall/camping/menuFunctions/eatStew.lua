local common = require ("mer.ashfall.common.common")
local foodConfig = common.staticConfigs.foodConfig
return {
    text = function(campfire)
        local stewName = foodConfig.isStewNotSoup(campfire.data.stewLevels) and "Stew" or "Soup" 
        return string.format("Eat %s", stewName)
    end,
    requirements = function(campfire)
        return (
            campfire.data.stewLevels and 
            campfire.data.stewProgress and
            campfire.data.stewProgress == 100 and
            common.staticConfigs.conditionConfig.hunger:getValue() > 0.01
        )
    end,
    callback = function(campfire)
        event.trigger("Ashfall:eatStew", { data = campfire.data})
        timer.delayOneFrame(function()
            if campfire.data.waterAmount == 0 then
                event.trigger("Ashfall:Campfire_clear_utensils", { campfire = campfire})
            end
        end)
    end
}