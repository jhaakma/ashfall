local common = require ("mer.ashfall.common.common")
local config = require("mer.ashfall.config").config
local foodConfig = common.staticConfigs.foodConfig
return {
    text = function(campfire)
        local stewName = foodConfig.isStewNotSoup(campfire.data.stewLevels) and "Stew" or "Soup"
        return string.format("Eat %s", stewName)
    end,
    showRequirements = function(campfire)
        return (
            campfire.data.stewLevels and
            campfire.data.stewProgress and
            campfire.data.stewProgress == 100
        )
    end,
    enableRequirements = function(campfire)
        return common.staticConfigs.conditionConfig.hunger:getValue() > 0.01
            or not config.enableHunger
    end,
    tooltipDisabled = {
        text = "You are full."
    },
    callback = function(campfire)
        event.trigger("Ashfall:eatStew", { data = campfire.data})
        event.trigger("Ashfall:UpdateAttachNodes", { reference = campfire})
    end
}