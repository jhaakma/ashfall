local this = {}
local common = require('mer.ashfall.common.common')

--Register heat source
local temperatureController = require("mer.ashfall.temperatureController")
temperatureController.registerExternalHeatSource("sunTemp")

local TIME_MIN = 0.5
local TIME_MAX = 1
local SEASON_MIN = 0.5
local SEASON_MAX = 1

local sunWeatherMapping = {
	[tes3.weather.clear] = 1.0,
	[tes3.weather.cloudy] = 0.8,
	[tes3.weather.foggy] = 0.3,
	[tes3.weather.overcast] = 0.2,
	[tes3.weather.rain] = 0.1,
	[tes3.weather.thunder] = 0.0,
	[tes3.weather.ash] = 0.5,
	[tes3.weather.blight] = 0.5,
	[tes3.weather.snow] = 0.5,
	[tes3.weather.blizzard] = 0.1,
}

function this.calculate(interval)
    local shadeMultiplier
    local hour = tes3.worldController.hour.value
    if common.helper.getInside(tes3.player) then
        shadeMultiplier = 0.0
    else
        local wc = tes3.worldController.weatherController
        if hour < (wc.sunriseHour - 1.5) or hour > (wc.sunsetHour + 1.5) then
            --definitely night time
            shadeMultiplier = 0.0
        else
            local sunPos = tes3.worldController.weatherController.sceneSunBase.worldTransform.translation
            local playerPos = tes3.getPlayerEyePosition()
            local sunLightDirection = (sunPos - tes3.getCameraPosition() ):normalized()
            local result = tes3.rayTest{
                position = playerPos,
                direction = sunLightDirection,
                ignore = { tes3.player }
            }
            shadeMultiplier = sunWeatherMapping[tes3.getCurrentWeather().index]
            if result then
                shadeMultiplier = math.max(0, shadeMultiplier * 0.2 - 0.1)
            end
        end
    end
    --clamp to daylight hours and scale dawn-dusk hours to 0-2.0
    local convertedTime = math.remap(math.clamp(hour, 4, 20), 4, 20, 0, 2 )
    --This puts dawn/dusk at 0.0, Midday at 1.0
    convertedTime = convertedTime < 1 and convertedTime or (1 - (convertedTime - 1))
    local timeMulti = math.remap(convertedTime, 0, 1, TIME_MIN, TIME_MAX)
    local seasonMulti = math.remap( common.helper.getSeasonMultiplier() , 0, 1, SEASON_MIN, SEASON_MAX)

    local sunHeat = (
        common.staticConfigs.maxSunTemp * 
        timeMulti *
        seasonMulti *
        shadeMultiplier
    )

    common.data.sunTemp = common.data.sunTemp or 0
    common.data.sunTemp = (
        common.data.sunTemp + 
        ((sunHeat - common.data.sunTemp) * math.min(1, interval * 500))
    )
end

local function blockSunDamage(e)
    if not(common.data and common.data.sunTemp) then return end
    local sunDamage = math.clamp(common.data.sunTemp / common.staticConfigs.maxSunTemp / 2, 0, 1)
    e.damage = sunDamage
end
event.register("calcSunDamageScalar", blockSunDamage, { priority = -100 })

return this