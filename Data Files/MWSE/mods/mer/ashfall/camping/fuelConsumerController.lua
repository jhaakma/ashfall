--[[
    Iterates over Fuel Consumers and updates their fuel level
]]

local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("fuelConsumerController")
local ReferenceController = require("mer.ashfall.referenceController")
local fuelDecay = 1.0
local fuelDecayRainEffect = 1.4
local fuelDecayThunderEffect = 1.6
local FUEL_UPDATE_INTERVAL = 0.001

ReferenceController.registerReferenceController{
    id = "fuelConsumer",
    requirements = function(_, ref)
        return ref.supportsLuaData
        and ref.data
        and ref.data.fuelLevel
    end
}

local function updateFuelConsumer(fuelConsumer)
    local timestamp = tes3.getSimulationTimestamp()
    fuelConsumer.data.lastFuelUpdated = fuelConsumer.data.lastFuelUpdated or timestamp
    local difference = math.round(timestamp - fuelConsumer.data.lastFuelUpdated, 4)

    if difference < 0 then
        logger:error("FUELCONSUMER fuelConsumer.data.lastFuelUpdated(%.4f) is ahead of e.timestamp(%.4f).",
            fuelConsumer.data.lastFuelUpdated, timestamp)
        --something fucky happened
        fuelConsumer.data.lastFuelUpdated = timestamp
    end

    fuelConsumer.data.lastFuelUpdated = timestamp
    if fuelConsumer.data.isLit then
        local bellowsEffect = 1.0
        local bellowsId = fuelConsumer.data.bellowsId and fuelConsumer.data.bellowsId:lower()
        local bellowsData = common.staticConfigs.bellows[bellowsId]
        if bellowsData then
            bellowsEffect = bellowsData.burnRateEffect
        end

        local rainEffect = 1.0
        if not fuelConsumer.tempData.ashfallIsSheltered then
            --raining and fuelConsumer exposed
            if tes3.getCurrentWeather().index == tes3.weather.rain then
                rainEffect = fuelDecayRainEffect
            --thunder and fuelConsumer exposed
            elseif tes3.getCurrentWeather().index == tes3.weather.thunder then
                rainEffect = fuelDecayThunderEffect
            end
        end

        local fuelDifference =  ( difference * fuelDecay * rainEffect * bellowsEffect )
        fuelConsumer.data.fuelLevel = fuelConsumer.data.fuelLevel - fuelDifference
        fuelConsumer.data.charcoalLevel = fuelConsumer.data.charcoalLevel or 0
        fuelConsumer.data.charcoalLevel = fuelConsumer.data.charcoalLevel + fuelDifference

        --static campfires never go out
        local isInfinite = fuelConsumer.data.staticCampfireInitialised
            or (fuelConsumer.data.dynamicConfig and fuelConsumer.data.dynamicConfig.campfire == "static")

        if isInfinite then
            fuelConsumer.data.fuelLevel = math.max(fuelConsumer.data.fuelLevel, 1)
        end

        if fuelConsumer.data.fuelLevel <= 0 then
            fuelConsumer.data.fuelLevel = 0
            local playSound = difference < 0.01
            event.trigger("Ashfall:fuelConsumer_Extinguish", {fuelConsumer = fuelConsumer, playSound = playSound})
        end
    else
        fuelConsumer.data.lastFuelUpdated = nil
    end
end

local function updateShelteredCampfire(ref)
    ref.tempData.ashfallIsSheltered = common.helper.checkRefSheltered(ref)
end

event.register("loaded", function()
    timer.start{
        duration = FUEL_UPDATE_INTERVAL,
        iterations = -1,
        callback = function()
            ReferenceController.iterateReferences("fuelConsumer", updateFuelConsumer)
        end
    }
    timer.start{
        duration = common.helper.getUpdateIntervalInSeconds(),
        iterations = -1,
        callback = function()
            ReferenceController.iterateReferences("fuelConsumer", function(ref)
                updateShelteredCampfire(ref)
            end)
        end
    }
end)

---@param e referenceDeactivatedEventData
event.register("referenceActivated", function(e)
    if ReferenceController.isReference("fuelConsumer", e.reference) then
        updateShelteredCampfire(e.reference)
    end
end)