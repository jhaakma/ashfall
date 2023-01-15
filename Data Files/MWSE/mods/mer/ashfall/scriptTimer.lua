--[[ Timer function for weather updates]]--

local temperatureController = require("mer.ashfall.temperatureController")

local weather = require("mer.ashfall.tempEffects.weather")
local wetness = require("mer.ashfall.tempEffects.wetness")
local conditions = require("mer.ashfall.conditions.conditionController")
local torch = require("mer.ashfall.tempEffects.torch")
local raceEffects = require("mer.ashfall.tempEffects.raceEffects")
local fireEffect = require("mer.ashfall.tempEffects.fireEffect")
local magicEffects = require("mer.ashfall.tempEffects.magicEffects")
local hazardEffects = require("mer.ashfall.tempEffects.hazardEffects")
local survivalEffect = require("mer.ashfall.survival")
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
--How often the script should run in gameTime

local lastTime
local function callUpdates()
    if not tes3.player then return end
    local hoursPassed = ( tes3.worldController.daysPassed.value * 24 ) + tes3.worldController.hour.value
    lastTime = lastTime or hoursPassed
    local interval = math.abs(hoursPassed - lastTime)
    --limit to 8 hours in case some crazy time leap
    interval = math.min(interval, 8.0)
    lastTime = hoursPassed

    weather.calculateWeatherEffect(interval)
    sunEffect.calculate(interval)
    wetness.calculateWetTemp(interval)
    needs.hunger.processMealBuffs(interval)

    --Needs:
    for _, script in pairs(needs) do
        script.calculate(interval)
    end
    statsEffect.calculate()

    -- --temp effects
    raceEffects.calculateRaceEffects()
    torch.calculateTorchTemp()
    fireEffect.calculateFireEffect()
    magicEffects.calculateMagicEffects(interval)
    hazardEffects.calculateHazards()
    survivalEffect.calculate()
    conditions.updateConditions() --1fps

    --visuals
    frostBreath.doFrostBreath()

    tes3.player.data.Ashfall.valuesInitialised = true
    temperatureController.calculate(interval)
    event.trigger("Ashfall:updateNeedsUI")
end
event.register("enterFrame", callUpdates)