--[[ Timer function for weather updates]]--

local temperatureController = require("mer.ashfall.temperatureController")

local weather = require("mer.ashfall.tempEffects.weather")
local wetness = require("mer.ashfall.tempEffects.wetness")
local conditions = require("mer.ashfall.conditionController")
local torch = require("mer.ashfall.tempEffects.torch")
local raceEffects = require("mer.ashfall.tempEffects.raceEffects")
local fireEffect = require("mer.ashfall.tempEffects.fireEffect")
local magicEffects = require("mer.ashfall.tempEffects.magicEffects")
local hazardEffects = require("mer.ashfall.tempEffects.hazardEffects")
local survivalEffect = require("mer.ashfall.survival")
local sunEffect = require("mer.ashfall.tempEffects.sunEffect")
local frostBreath = require("mer.ashfall.effects.frostBreath")
local statsEffect = require("mer.ashfall.needs.statsEffect")

--Survival stuff
local tentController = require("mer.ashfall.tentController")
local activators = require("mer.ashfall.activators.activatorController")

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

    --Heavy scripts
    activators.callRayTest()
    --temp effects
    raceEffects.calculateRaceEffects()
    torch.calculateTorchTemp()
    fireEffect.calculateFireEffect()
    magicEffects.calculateMagicEffects()
    hazardEffects.calculateHazards()
    survivalEffect.calculate()
    conditions.updateConditions()
    
    --visuals

    frostBreath.doFrostBreath()

    tes3.player.data.Ashfall.valuesInitialised = true
    temperatureController.calculate(interval)
    event.trigger("Ashfall:updateNeedsUI")
end

event.register("enterFrame", callUpdates)



-- local function dataLoaded()
    
--     timer.delayOneFrame(
--         function()
--             --Use game timer when sleeping
--             timer.start({
--                 duration =  0.1, 
--                 callback = function()
--                     if tes3.player and tes3.menuMode() then
--                         callUpdates()
--                     end 
--                 end, 
--                 type = timer.game, 
--                 iterations = -1
--             })
--         end
        
--     )
-- end


-- --Register functions
-- event.register("Ashfall:dataLoadedOnce", dataLoaded)

local function resetTime()
    lastTime = nil
end
event.register("loaded", resetTime)