local common = require("mer.ashfall.common.common")
local logger = common.createLogger("HeatCurve")
local Bellows = require("mer.ashfall.camping.Bellows")
local Campfire = require("mer.ashfall.camping.campfire.Campfire")
local Activator = require("mer.ashfall.activators.Activator")
local FuelModel = require("mer.ashfall.camping.FuelModel")

---@class Ashfall.HeatCurve
local HeatCurve = {}

---@class Ashfall.HeatCurve.Snapshot
---@field timestamp number
---@field id string
---@field isLit boolean
---@field fuelLevel number
---@field isInfinite boolean
---@field burnPerHour number
---@field heatBellowsEffect number
---@field weakEffect number
---@field isColdEffect number
---@field heatMultiplier number

---@param heatSource tes3reference
---@return Ashfall.HeatCurve.Snapshot
function HeatCurve.snapshotFuelConsumer(heatSource)
    local fuelSnap = FuelModel.snapshot(heatSource)

    local isWeak = Activator.registeredActivators.teaWarmer:isActivator(heatSource)
    local weakEffect = isWeak and 0.1 or 1.0

    local isColdEffect = (heatSource and heatSource.data and heatSource.data.hasColdFlame) and -1 or 1

    local campfireData = Campfire.getCampfire(heatSource.object.id)
    local heatMultiplier = campfireData and campfireData.heatMultiplier or 1.0

    local heatBellowsEffect = Bellows.getScaledHeatEffect(heatSource) or 1.0

    return {
        timestamp = fuelSnap.timestamp,
        id = fuelSnap.id,
        isLit = fuelSnap.isLit,
        fuelLevel = fuelSnap.fuelLevel,
        isInfinite = fuelSnap.isInfinite,
        burnPerHour = fuelSnap.burnPerHour,
        heatBellowsEffect = heatBellowsEffect,
        weakEffect = weakEffect,
        isColdEffect = isColdEffect,
        heatMultiplier = heatMultiplier,
    }
end

---@param snap Ashfall.HeatCurve.Snapshot|nil
---@param tHours number
---@return number targetHeat
function HeatCurve.heatAt(snap, tHours)
    if not snap then
        return 0
    end

    if not snap.isLit then
        return 0
    end

    local t = math.max(tHours or 0, 0)

    local fuel
    if snap.isInfinite then
        fuel = math.max(snap.fuelLevel or 0, 1)
    else
        local startFuel = snap.fuelLevel or 0
        local burn = snap.burnPerHour or 0
        fuel = math.max(0, startFuel - burn * t)
    end

    if fuel <= 0 then
        return 0
    end

    return fuel
        * (snap.heatBellowsEffect or 1.0)
        * (snap.weakEffect or 1.0)
        * (snap.isColdEffect or 1)
        * (snap.heatMultiplier or 1.0)
end

---@param snap Ashfall.HeatCurve.Snapshot|nil
---@return fun(tHours: number): number
function HeatCurve.makeTargetHeatFn(snap)
    return function(tHours)
        return HeatCurve.heatAt(snap, tHours)
    end
end

---@param targetHeat number
---@return fun(tHours: number): number
function HeatCurve.makeConstantTargetHeatFn(targetHeat)
    local heat = targetHeat or 0
    return function()
        return heat
    end
end

---Return a new snapshot advanced by an offset in hours (fuel burned down).
---This is used when an unfired pot finishes firing mid-time-gap and is converted
---to a fired pot; the fired pot should continue from the in-gap kiln state.
---@param snap Ashfall.HeatCurve.Snapshot|nil
---@param offsetHours number
---@return Ashfall.HeatCurve.Snapshot|nil
function HeatCurve.advanceSnapshot(snap, offsetHours)
    if not snap then
        return nil
    end

    local dt = math.max(offsetHours or 0, 0)
    local newSnap = table.copy(snap)
    newSnap.timestamp = (snap.timestamp or 0) + dt

    if not snap.isLit then
        return newSnap
    end

    if snap.isInfinite then
        newSnap.fuelLevel = math.max(snap.fuelLevel or 0, 1)
        return newSnap
    end

    local startFuel = snap.fuelLevel or 0
    local burn = snap.burnPerHour or 0
    local fuel = math.max(0, startFuel - burn * dt)
    newSnap.fuelLevel = fuel
    if fuel <= 0 then
        newSnap.isLit = false
    end

    return newSnap
end

return HeatCurve
