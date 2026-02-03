--[[
    Iterates over Fuel Consumers and updates their fuel level
]]

local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("fuelConsumerController")
local ReferenceController = require("mer.ashfall.referenceController")
local Bellows = require("mer.ashfall.camping.Bellows")
local Campfire = require("mer.ashfall.camping.campfire.Campfire")
local FuelModel = require("mer.ashfall.camping.FuelModel")
local FUEL_DECAY_RATE = 1.0
local FUEL_DECAY_RAIN_MULTIPLIER = 1.4
local FUEL_DECAY_THUNDER_MULTIPLIER = 1.6
local FUEL_UPDATE_INTERVAL = 0.001

ReferenceController.registerReferenceController{
    id = "fuelConsumer",
    requirements = function(_, ref)
        return ref.supportsLuaData
        and ref.data
        and ref.data.fuelLevel
    end
}

local function getRainEffect(fuelConsumer)
    -- Prefer the shared model so other systems can reproduce the same behavior.
    -- Keep the local constants above for backwards-compatibility/logging if needed.
    return FuelModel.getRainEffect(fuelConsumer)
end

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
        local bellowsEffect = Bellows.getScaledFuelDrainEffect(fuelConsumer)
        local rainEffect = getRainEffect(fuelConsumer)
        local campfireData = Campfire.getCampfire(fuelConsumer.object.id)
        local fuelBurnMultiplier = campfireData and campfireData.fuelBurnMultiplier or 1.0
        local fuelDifference =  ( difference * FUEL_DECAY_RATE * rainEffect * bellowsEffect * fuelBurnMultiplier )
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