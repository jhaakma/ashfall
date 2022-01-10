local common = require("mer.ashfall.common.common")

return {
    text = "Douse",
    showRequirements = function(campfire)
        local wetness = common.staticConfigs.conditionConfig.wetness
        return campfire.data.waterAmount
            and campfire.data.waterAmount > 0
            and common.data.wetness <= wetness.states.soaked.max
            and (campfire.data.waterType == "dirty" or not campfire.data.waterType)
            and (not campfire.data.stewLevels)
            and (not campfire.data.waterHeat or campfire.data.waterHeat < common.staticConfigs.hotWaterHeatValue)
    end,
    callback = function(campfire)
        event.trigger("Ashfall:Douse", { data = campfire.data })
        event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire})
    end
}