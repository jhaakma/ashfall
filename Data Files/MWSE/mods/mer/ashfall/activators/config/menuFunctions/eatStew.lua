local common = require ("mer.ashfall.common.common")
local config = require("mer.ashfall.config").config
local foodConfig = common.staticConfigs.foodConfig
return {
    text = function(campfire)
        local stewName = foodConfig.isStewNotSoup(campfire.data.stewLevels) and "Stew" or "Soup"
        return string.format("Eat %s", stewName)
    end,
    showRequirements = function(reference)

        if not reference.supportsLuaData then return false end
        return (
            reference.data.stewLevels and
            reference.data.stewProgress and
            reference.data.stewProgress == 100
        )
    end,
    enableRequirements = function(reference)
        return common.staticConfigs.conditionConfig.hunger:getValue() > 0.01
            or not config.enableHunger
    end,
    tooltipDisabled = {
        text = "You are full."
    },
    callback = function(reference)
        event.trigger("Ashfall:eatStew", { data = reference.data})
        event.trigger("Ashfall:UpdateAttachNodes", { reference = reference})
    end
}