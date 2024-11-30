--[[ Timer function for weather updates]]--
local common = require("mer.ashfall.common.common")
local temperatureController = require("mer.ashfall.temperatureController")

local weather = require("mer.ashfall.tempEffects.weather")
local wetness = require("mer.ashfall.tempEffects.wetness")
local conditions = require("mer.ashfall.conditions.conditionController")
local torch = require("mer.ashfall.tempEffects.torch")
local raceEffects = require("mer.ashfall.tempEffects.raceEffects")
local fireEffect = require("mer.ashfall.tempEffects.fireEffect")
local magicEffects = require("mer.ashfall.tempEffects.magicEffects")
local hazardEffects = require("mer.ashfall.tempEffects.hazardEffects")
local sunEffect = require("mer.ashfall.tempEffects.sunEffect")
local frostBreath = require("mer.ashfall.effects.frostBreath")
local statsEffect = require("mer.ashfall.needs.statsEffect")

--Needs
local needs = {
    thirst = require("mer.ashfall.needs.thirstController"),
    hunger = require("mer.ashfall.needs.hungerController"),
    tiredness = require("mer.ashfall.needs.sleepController"),
    sickness = require("mer.ashfall.needs.sicknessController"),
}


local function getHoursPassed()
    return ( tes3.worldController.daysPassed.value * 24 ) + tes3.worldController.hour.value
end
local function getInterval(hoursPassed)
    common.data.lastTimeScriptsUpdated = common.data.lastTimeScriptsUpdated or hoursPassed
    local interval = math.abs(hoursPassed - common.data.lastTimeScriptsUpdated)
    --limit to 8 hours in case some crazy time leap
    interval = math.clamp(interval, 0.0, 8.0)
    return interval
end


local function callUpdates()
    if not tes3.player then return end

    statsEffect.calculate()
    -- --temp effects
    raceEffects.calculateRaceEffects()
    torch.calculateTorchTemp()
    fireEffect.calculateFireEffect()
    hazardEffects.calculateHazards()
    conditions.updateConditions() --1fps
    frostBreath.doFrostBreath()

    local hoursPassed = getHoursPassed()
    local interval = getInterval(hoursPassed)
    common.data.lastTimeScriptsUpdated = hoursPassed

    magicEffects.calculateMagicEffects(interval)
    weather.calculateWeatherEffect(interval)
    sunEffect.calculate(interval)
    wetness.calculateWetTemp(interval)
    needs.hunger.processMealBuffs(interval)

    --Needs:
    for _, script in pairs(needs) do
        script.calculate(interval)
    end

    tes3.player.data.Ashfall.valuesInitialised = true
    temperatureController.calculate(interval)
    event.trigger("Ashfall:updateNeedsUI")
end
event.register("enterFrame", callUpdates)