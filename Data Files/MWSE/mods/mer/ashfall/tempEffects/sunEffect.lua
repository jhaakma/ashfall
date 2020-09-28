local this = {}
local common = require('mer.ashfall.common.common')

--Register heat source
local temperatureController = require("mer.ashfall.temperatureController")
temperatureController.registerExternalHeatSource("sunTemp")

local HEAT_DEFAULT = 10
local TIME_MIN = 0.5
local TIME_MAX = 1.5
local SEASON_MIN = 0.5
local SEASON_MAX = 1.5

local sunWeatherMapping = {
	[tes3.weather.clear] = 1.0,
	[tes3.weather.cloudy] = 0.7,
	[tes3.weather.foggy] = 0.1,
	[tes3.weather.overcast] = 0.4,
	[tes3.weather.rain] = 0.1,
	[tes3.weather.thunder] = 0.0,
	[tes3.weather.ash] = 0.5,
	[tes3.weather.blight] = 0.5,
	[tes3.weather.snow] = 0.6,
	[tes3.weather.blizzard] = 0.2,
}

function this.calculate(interval)
    local shadeMultiplier
    local hour = tes3.worldController.hour.value
    if common.helper.getInside(tes3.player) then
        shadeMultiplier = 0.0
    else
        if hour < 4 or hour > 20 then
            shadeMultiplier = 1.0
        else
            local sunPos = tes3.worldController.weatherController.sceneSunBase.worldTransform.translation
            local playerPos = tes3.player.position
            local sunLightDirection = (sunPos - tes3.getCameraPosition() ):normalized()
            local result = tes3.rayTest{
                position = playerPos,
                direction = sunLightDirection,
                ignore = { tes3.player }
            }
            if result then
                shadeMultiplier = 0.0
            else
                shadeMultiplier = sunWeatherMapping[tes3.getCurrentWeather().index]
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
        HEAT_DEFAULT * 
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

return this