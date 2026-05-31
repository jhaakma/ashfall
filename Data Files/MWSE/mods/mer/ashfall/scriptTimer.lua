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

local function getTimerInterval(hoursPassed)
    common.data.lastTimeTimerScriptsUpdated = common.data.lastTimeTimerScriptsUpdated or hoursPassed
    local interval = math.abs(hoursPassed - common.data.lastTimeTimerScriptsUpdated)
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
    --Needs:
    for _, script in pairs(needs) do
        script.calculate(interval)
    end
    event.trigger("Ashfall:UpdateNeedsUI")
    event.trigger("Ashfall:UpdateHUD")
    temperatureController.calculate(interval)
end
-- The survival stack used to run on `enterFrame` (~60Hz, and even while paused
-- in menus). It's now driven by a simulate timer (~10Hz, paused in menus). The
-- needs/temperature math is interval-driven by game hours, so a lower tick rate
-- accumulates identically; the non-interval temp effects (fire/torch/etc.) only
-- recompute the current state, which can't change while the game is paused.
-- Timers are cancelled right before each `loaded`, so re-starting here on every
-- load does not stack.
event.register("loaded", function()
    timer.start{
        type = timer.simulate,
        duration = 0.1,
        iterations = -1,
        persist = false,
        callback = callUpdates,
    }
end)

-- The simulate timer doesn't tick during a vanilla rest/wait (menu mode), so the
-- needs that would have accumulated over those hours are applied once at the rest
-- boundary via the Ashfall:RestFinished event (see the needs controllers). Without
-- this, the first tick after the rest would see the whole rest as a single interval
-- and double-apply those needs at the normal rate. Re-baseline the interval clock so
-- that catch-up tick is a no-op. (The real timer keeps ticking through the rest, so
-- lastTimeTimerScriptsUpdated is left untouched.)
event.register("Ashfall:RestFinished", function()
    common.data.lastTimeScriptsUpdated = getHoursPassed()
end)

event.register("loaded", function()
    timer.start{
        type = timer.real,
        duration = 0.2,
        iterations = -1,
        callback = function()
            local hoursPassed = getHoursPassed()
            local interval = getTimerInterval(hoursPassed)
            common.data.lastTimeTimerScriptsUpdated = hoursPassed

            magicEffects.calculateMagicEffects(interval)
            weather.calculateWeatherEffect(interval)
            sunEffect.calculate(interval)
            wetness.calculateWetTemp(interval)
            needs.hunger.processMealBuffs(interval)
            tes3.player.data.Ashfall.valuesInitialised = true

        end
    }
end)