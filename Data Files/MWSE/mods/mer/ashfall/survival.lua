local common = require ("mer.ashfall.common.common")
local temperatureController = require("mer.ashfall.temperatureController")
temperatureController.registerBaseTempMultiplier({ id ="survivalEffect"})
local this = {}

local CHECK_INTERVAL = 0.20
local MAX_EFFECT = 0.7

--Calculate survival's effect on temperature
function this.calculate()
    local survivalEffect = math.remap(common.skills.survival.value, 10, 100, 1.0, MAX_EFFECT)
    survivalEffect = math.clamp(survivalEffect, 1, MAX_EFFECT)
    common.data.survivalEffect = survivalEffect
end


local function checkConditions()
    if not common.data then return end
    if not common.config.getConfig().enableTemperatureEffects then return end

    local totalIncrease = 0
    --Increase when out in bad weather
    if not common.data.isSheltered then
        local weatherValues = {
            [tes3.weather.rain] = 1,
            [tes3.weather.thunder] = 2,
            [tes3.weather.snow] = 3,
            [tes3.weather.ash] = 3,
            [tes3.weather.blight] = 4,
            [tes3.weather.blizzard] = 4
        }
        local weather = tes3.getCurrentWeather().index
        local weatherInc = weatherValues[weather] and weatherValues[weather]  or 0
        totalIncrease = totalIncrease + weatherInc
    end

    --Increase when warming up next to a campfire
    if common.data.nearCampfire then
        local fireInc = math.remap(common.data.fireTemp, 0, 100, 1, 5)
        
        totalIncrease = totalIncrease + fireInc
    end

    --Increase when soaking wet
    if common.data.wetness > 80 then
        totalIncrease = totalIncrease + 1
    end

    if totalIncrease > 0 then
        common.skills.survival:progressSkill(totalIncrease)
    end
end

local function startSurvivalTimer()
    timer.start{
        type = timer.game,
        iterations = -1,
        duration = CHECK_INTERVAL,
        callback = checkConditions
    }
end

event.register("Ashfall:dataLoadedOnce", startSurvivalTimer)


return this