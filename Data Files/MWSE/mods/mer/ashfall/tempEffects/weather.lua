--[[

This script gets region and weather info on cell change/weather change

]] --
local this = {}
local common = require('mer.ashfall.common.common')
 -- 

--Register heat source
local temperatureController = require("mer.ashfall.temperatureController")
temperatureController.registerExternalHeatSource("weatherTemp")

local SEASON_MIN = 0.8
local SEASON_MAX = 1.2

local currentWeather

local weatherValues = {
    [tes3.weather.blight] = 40,
    [tes3.weather.ash] = 30,
    [tes3.weather.clear] = 0,
    [tes3.weather.cloudy] = -10,
    [tes3.weather.overcast] = -20,
    [tes3.weather.foggy] = -25,
    [tes3.weather.rain] = -35,
    [tes3.weather.thunder] = -45,
    [tes3.weather.snow] = -55,
    [tes3.weather.blizzard] = -70
}


--Alter min/max weather values
local regionValues = {
    ['Moesring Mountains Region'] = {min = -80, max = -30},
    ['Felsaad Coast Region'] = {min = -80, max = -30},
    ['Isinfier Plains Region'] = {min = -80, max = -30},
    ['Brodir Grove Region'] = {min = -75, max = -25},
    ['Thirsk Region'] = {min = -75, max = -20},
    ['Hirstaang Forest Region'] = {min = -65, max = -20},
    --Vvardenfell
    --Cold
    ['Sheogorad'] = {min = -60, max = -25},
    ["Azura's Coast Region"] = {min = -45, max = -20},
    --Normal
    ['Ascadian Isles Region'] = {min = -40, max = -20}, --Perfectly normal weather here
    ['Grazelands Region'] = {min = -40, max = 0},
     -- gets cold at night, warm in day
    --Hot
    ['Bitter Coast Region'] = {min = -25, max = 5},
    ['West Gash Region'] = {min = -35, max = 5},
    ['Ashlands Region'] = {min = -10, max = 5},
    ['Molag Mar Region'] = {min = 0, max = 10},
    ['Red Mountain Region'] = {min = 0, max = 15}
}

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
    --remap to temperature based on weather ranges and region effects
    local min = (regionValues[regionID] and regionValues[regionID].min or 0)
    local max = (regionValues[regionID] and regionValues[regionID].max or 0)
    timeEffect = math.remap(timeEffect, 0.5, 11.5, min, max)

    return timeEffect
end

local function getWeatherEffect()
    currentWeather = currentWeather or tes3.weather.clear
    return  weatherValues[currentWeather]
end

local lastCellWasInterior
function this.calculateWeatherEffect(interval)


    if common.helper.getInside(tes3.player) then
        common.data.weatherTemp = common.data.intWeatherEffect or 0
        lastCellWasInterior = true
    else
        

        local weatherTemp = ( 
            getTimeEffect() + 
            getWeatherEffect()
        ) * getSeasonEffect()

        --Check if indoors
        
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

local registerOnce
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
