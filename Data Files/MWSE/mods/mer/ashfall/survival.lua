local common = require ("mer.ashfall.common.common")
local config = require("mer.ashfall.config").config
local exposureConfig = require("mer.ashfall.config.skillConfigs").survival.exposure
local temperatureController = require("mer.ashfall.temperatureController")
temperatureController.registerBaseTempMultiplier({ id ="survivalEffect"})

local CHECK_INTERVAL = 0.5


--Calculate survival's effect on temperature
local function updateSurvivalTemperatureEffect()
    local survivalEffect = math.remap(common.skills.survival.current, 10, 100, 1.0, exposureConfig.temperatureEffectMax)
    survivalEffect = math.clamp(survivalEffect, 1, exposureConfig.temperatureEffectMax)
    common.data.survivalEffect = survivalEffect
end

local function progressSurvivalSkillFromExposure()
    if not common.data then return end
    if not config.enableTemperatureEffects then return end

    local totalIncrease = 0
    --Increase when out in bad weather
    if not common.data.isSheltered then
        local weatherInc = table.get(exposureConfig.weathers, tes3.getCurrentWeather().index, 0)
        totalIncrease = totalIncrease + weatherInc
    end

    --Increase when warming up next to a campfire
    if common.data.nearCampfire then
        local fireEffect = common.helper.clampmap(
            common.data.fireTemp,
            0,
            100,
            exposureConfig.fire.min,
            exposureConfig.fire.max
        )
        totalIncrease = totalIncrease + fireEffect
    end

    --Increase when wet
    if common.data.wetness > common.staticConfigs.conditionConfig.wetness.states.wet.min then
        local wetnessEffect = common.helper.clampmap(
            common.data.wetness,
            common.staticConfigs.conditionConfig.wetness.states.wet.min,
            common.staticConfigs.conditionConfig.wetness.max,
            0,
            exposureConfig.water.max
        )
        totalIncrease = totalIncrease + wetnessEffect
    end

    --Multiply by time passed so its' per hour
    totalIncrease = totalIncrease * CHECK_INTERVAL

    if totalIncrease > 0 then
        common.skills.survival:exercise(totalIncrease)
    end
end

local function startSurvivalTimer()
    timer.start{
        type = timer.game,
        iterations = -1,
        duration = CHECK_INTERVAL,
        callback = function()
            progressSurvivalSkillFromExposure()
            updateSurvivalTemperatureEffect()
        end
    }
end

event.register("loaded", startSurvivalTimer)