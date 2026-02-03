local common = require("mer.ashfall.common.common")
local logger = common.createLogger("FuelModel")
local Bellows = require("mer.ashfall.camping.Bellows")
local Campfire = require("mer.ashfall.camping.campfire.Campfire")

---@class Ashfall.FuelModel
local FuelModel = {}

-- Keep these constants centralized so time-gap simulation and real-time decay match.
local FUEL_DECAY_RATE = 1.0
local FUEL_DECAY_RAIN_MULTIPLIER = 1.4
local FUEL_DECAY_THUNDER_MULTIPLIER = 1.6

---@class Ashfall.FuelModel.Snapshot
---@field timestamp number
---@field id string
---@field isLit boolean
---@field fuelLevel number
---@field isInfinite boolean
---@field rainEffect number
---@field fuelBurnMultiplier number
---@field bellowsFuelDrainEffect number
---@field burnPerHour number

---@param fuelConsumer tes3reference
---@return boolean
local function isInfiniteFuelConsumer(fuelConsumer)
    if not fuelConsumer or not fuelConsumer.data then
        return false
    end

    return fuelConsumer.data.staticCampfireInitialised
        or (fuelConsumer.data.dynamicConfig and fuelConsumer.data.dynamicConfig.campfire == "static")
end

---@param fuelConsumer tes3reference
---@return number
function FuelModel.getRainEffect(fuelConsumer)
    local sheltered = fuelConsumer
        and fuelConsumer.tempData
        and fuelConsumer.tempData.ashfallIsSheltered

    if sheltered then
        return 1.0
    end

    local weather = tes3.getCurrentWeather()
    if not weather then
        return 1.0
    end

    if weather.index == tes3.weather.rain then
        return FUEL_DECAY_RAIN_MULTIPLIER
    elseif weather.index == tes3.weather.thunder then
        return FUEL_DECAY_THUNDER_MULTIPLIER
    end

    return 1.0
end

---@param fuelConsumer tes3reference
---@return number
function FuelModel.getBurnPerHour(fuelConsumer)
    if not fuelConsumer or not fuelConsumer.data then
        return 0
    end

    if fuelConsumer.data.isLit ~= true then
        return 0
    end

    local bellowsEffect = Bellows.getScaledFuelDrainEffect(fuelConsumer) or 1.0
    local rainEffect = FuelModel.getRainEffect(fuelConsumer)

    local campfireData = Campfire.getCampfire(fuelConsumer.object.id)
    local fuelBurnMultiplier = campfireData and campfireData.fuelBurnMultiplier or 1.0

    return (FUEL_DECAY_RATE * rainEffect * bellowsEffect * fuelBurnMultiplier)
end

---@param fuelConsumer tes3reference
---@return Ashfall.FuelModel.Snapshot
function FuelModel.snapshot(fuelConsumer)
    local timestamp = tes3.getSimulationTimestamp()
    local id = fuelConsumer and fuelConsumer.object and fuelConsumer.object.id or ""

    local fuelLevel = (fuelConsumer and fuelConsumer.data and fuelConsumer.data.fuelLevel) or 0
    local isLit = (fuelConsumer and fuelConsumer.data and fuelConsumer.data.isLit) == true
    local isInfinite = isInfiniteFuelConsumer(fuelConsumer)

    local rainEffect = FuelModel.getRainEffect(fuelConsumer)

    local campfireData = (fuelConsumer and fuelConsumer.object) and Campfire.getCampfire(fuelConsumer.object.id) or nil
    local fuelBurnMultiplier = campfireData and campfireData.fuelBurnMultiplier or 1.0

    local bellowsFuelDrainEffect = Bellows.getScaledFuelDrainEffect(fuelConsumer) or 1.0
    local burnPerHour = isLit and (FUEL_DECAY_RATE * rainEffect * bellowsFuelDrainEffect * fuelBurnMultiplier) or 0

    return {
        timestamp = timestamp,
        id = id,
        isLit = isLit,
        fuelLevel = fuelLevel,
        isInfinite = isInfinite,
        rainEffect = rainEffect,
        fuelBurnMultiplier = fuelBurnMultiplier,
        bellowsFuelDrainEffect = bellowsFuelDrainEffect,
        burnPerHour = burnPerHour,
    }
end

---@param fuelConsumer tes3reference
---@param hours number
---@return number fuelDelta
function FuelModel.getFuelDeltaOverHours(fuelConsumer, hours)
    if (hours or 0) <= 0 then
        return 0
    end

    local burnPerHour = FuelModel.getBurnPerHour(fuelConsumer)
    return burnPerHour * hours
end

return FuelModel
