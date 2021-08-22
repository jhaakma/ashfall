--[[

This script gets region and weather info on cell change/weather change

]] --
local this = {}
local common = require('mer.ashfall.common.common')
local climateConfig = require('mer.ashfall.config.weatherRegionConfig')
 --

--Register heat source
local temperatureController = require("mer.ashfall.temperatureController")
temperatureController.registerExternalHeatSource("weatherTemp")

local SEASON_MIN = 0.8
local SEASON_MAX = 1.2

local currentWeather



--Keyword search in interior names for cold caves etc

local function updateWeather(weatherObj)
    if weatherObj then
        currentWeather = weatherObj.index
    end
end

local function immediateChange(e)
    updateWeather(e.to)
end

local function transitionEnd(e)
    updateWeather(e.to)
end



local function getSeasonEffect()
    local seasonTemp = math.remap(common.helper.getSeasonMultiplier(), 0, 1, SEASON_MIN, SEASON_MAX)
    return seasonTemp
end


local function getTimeEffect()
    local regionID = tes3.player.cell.region and tes3.player.cell.region.id or ''

    local gameHour = tes3.worldController.hour.value
    --This puts Midnight at 0, Midday at 12, in both directions
    local convertedTime = gameHour < 12 and gameHour or (12 - (gameHour - 12))
    --Clamp so temp stays the same for an hour at midday and midnight
    local timeEffect = math.clamp(convertedTime, 0.5, 11.5)
    --remap to temperature based on region effects
    local regionData = climateConfig.getRegionData(regionID)
    timeEffect = math.remap(timeEffect, 0.5, 11.5, regionData.min, regionData.max)

    return timeEffect
end

local function getWeatherEffect()
    return  climateConfig.getWeatherTemperature(currentWeather)
end

local lastCellWasInterior
function this.calculateWeatherEffect(interval)
    if common.helper.getInside(tes3.player) then
        common.data.weatherTemp = common.data.intWeatherEffect
            or common.staticConfigs.interiorTempValues.default
        lastCellWasInterior = true
    else
        local weatherTemp = ( getTimeEffect() + getWeatherEffect() ) * getSeasonEffect()

        --If we just transitioned outside, instantly update the weather temp
        if lastCellWasInterior then
            common.data.weatherTemp = weatherTemp
        else
            common.data.weatherTemp =(
                common.data.weatherTemp +
                ((weatherTemp - common.data.weatherTemp) * math.min(1, interval * 40))
            )
        end
        lastCellWasInterior = false
    end
end

local function cellChanged()
    updateWeather(tes3.getCurrentWeather())

    --default
    local intWeatherEffect = common.staticConfigs.interiorTempValues.default

    --check ids
    local lowerCellId = string.lower(tes3.player.cell.id)
        for key, val in pairs(common.staticConfigs.interiorTempPatterns) do
            if string.find(lowerCellId, key) then
                intWeatherEffect = val
            end
        end
   -- end
    common.data.intWeatherEffect = intWeatherEffect
end

local function dataLoaded()
    updateWeather(tes3.getCurrentWeather())
    common.data.weatherTemp = common.data.weatherTemp or common.staticConfigs.interiorTempValues.default
end

event.register('Ashfall:dataLoaded', dataLoaded)

local function firstDataLoaded()
    cellChanged()
    event.register('cellChanged', cellChanged)
    event.register('weatherChangedImmediate', immediateChange)
    event.register('weatherTransitionFinished', transitionEnd)
end
event.register("Ashfall:dataLoadedOnce", firstDataLoaded)

--Change weather every few hours
local function setWeatherInterval()
    local interval = math.random(1, 6)
    tes3.worldController.weatherController.hoursBetweenWeatherChanges = interval
end

event.register('weatherTransitionFinished', setWeatherInterval)
event.register('weatherChangedImmediate', setWeatherInterval)
setWeatherInterval()

return this
