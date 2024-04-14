local common = require("mer.ashfall.common.common")

return {
    text = "Douse",
    showRequirements = function(reference)

        if not reference.supportsLuaData then return false end
        local wetness = common.staticConfigs.conditionConfig.wetness
        return reference.data.waterAmount
            and reference.data.waterAmount > 0
            and common.data.wetness <= wetness.states.soaked.max
            and (reference.data.waterType == "dirty" or not reference.data.waterType)
            and (not reference.data.stewLevels)
            and (not reference.data.waterHeat or reference.data.waterHeat < common.staticConfigs.hotWaterHeatValue)
    end,
    callback = function(reference)
        event.trigger("Ashfall:Douse", { data = reference.data })
        event.trigger("Ashfall:UpdateAttachNodes", { reference = reference})
    end
}