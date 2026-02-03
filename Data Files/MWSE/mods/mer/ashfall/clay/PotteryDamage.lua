local common = require("mer.ashfall.common.common")
local logger = common.createLogger("PotteryDamage")
local PotteryBreaking = require("mer.ashfall.clay.PotteryBreaking")

---Shared break/crack mechanics used by multiple pottery types.
---
---This module focuses on *chance calculation* and *roll/apply* helpers.
---Pottery classes provide the inputs (quality/progress/temper, recipe, etc.).
---@class Ashfall.Clay.PotteryDamage
local PotteryDamage = {}

-- Shared tuning constants (keep these centralized to avoid magic numbers in logic).
-- Temperatures are in the same units used by Ashfall (Campfire stage temps).

--- Pickup safety constant, fraction of firing min temp.
local SAFE_PICKUP_TEMP_FACTOR = 0.35

-- Underfiring constants (UnfiredPottery break model).
local UNDERFIRE_TEMP_DEFICIT_SCALE = 1.5
local UNDERFIRE_TEMP_DEFICIT_EXPONENT = 3
local UNDERFIRE_PROGRESS_RISK_PER_PROGRESS = 0.25
local UNDERFIRE_TEMPER_DAMAGE_FACTOR = 0.5

-- Thermal shock constants (FiredPottery cooling model).
-- Thermal shock is driven primarily by the cooling gradient (current - target).
-- We intentionally ignore small gradients to avoid triggering during natural heat-source cooldown.
local THERMAL_SHOCK_MIN_DELTA_FACTOR = 0.55
local THERMAL_SHOCK_HEAT_EXPONENT = 1.10
local THERMAL_SHOCK_DELTA_EXPONENT = 1.75
local THERMAL_SHOCK_QUALITY_RISK_MULT = 0.75
local THERMAL_SHOCK_TEMPER_RISK_FACTOR = 0.75

-- Thermal shock uses a *rate per hour* (hazard rate), then converts to probability over time.
-- This avoids "nothing ever happens" when updates are frequent and hoursElapsed is small.
-- At max heat+delta, this yields near-guaranteed cracking on the next update.
local THERMAL_SHOCK_BASE_RATE_PER_HOUR = 80.0
local THERMAL_SHOCK_MAX_RATE_PER_HOUR = 200.0

-- Roll helper constants.
local MAX_PER_HOUR_PROBABILITY = 0.99

---Temperature at/under which it is safe to pick up a hot pottery item.
---Kept in sync with thermal-shock "safe" threshold so pickup is either blocked or safe.
---@param firingMinTemp number
---@return number
function PotteryDamage.getSafePickupTemperature(firingMinTemp)
    return (firingMinTemp or 0) * SAFE_PICKUP_TEMP_FACTOR
end

---@class Ashfall.Clay.PotteryDamage.ApplyParams
---@field reference tes3reference
---@field data table -- must contain `cracked` boolean?
---@field recipe Ashfall.PotteryRecipe|nil
---@field shouldNotifyPlayer boolean

---If already cracked, break; otherwise crack.
---@param e Ashfall.Clay.PotteryDamage.ApplyParams
---@return "none"|"cracked"|"broken"
function PotteryDamage.applyCrackOrBreak(e)
    if not e.reference then
        return "none"
    end

    if e.data and e.data.cracked then
        PotteryBreaking.breakPottery(e.reference, e.recipe, e.shouldNotifyPlayer)
        return "broken"
    end

    PotteryBreaking.crackPottery(e.reference, e.data, e.shouldNotifyPlayer)
    return "cracked"
end

---@class Ashfall.Clay.PotteryDamage.UnderfireParams
---@field currentTemperature number
---@field highestTemperature number
---@field firingMinTemp number
---@field firingProgress number -- 0..1
---@field quality number -- 0..1 (0 terrible, 1 perfect)
---@field tempered boolean
---@field kilnMultiplier number
---@field breakResistance number
---@field cracked boolean
---@field crackChanceMultiplier number
---@field perHourBreakModifier number

---Generalised version of unfired pottery under-firing/uneven-firing break chance.
---Returns a per-hour probability (0..1).
---@param e Ashfall.Clay.PotteryDamage.UnderfireParams
---@return number chancePerHour
function PotteryDamage.calculateUnderfireChance(e)
    local hasStartedFiring = (e.highestTemperature or 0) >= e.firingMinTemp
    if (not hasStartedFiring) or (e.firingProgress or 0) == 0 then
        return 0
    end

    local currentTemp = e.currentTemperature or 0
    local tempRisk
    if currentTemp >= e.firingMinTemp then
        tempRisk = 1
    else
        local tempDeficit = e.firingMinTemp - currentTemp
        tempRisk = 1 + math.pow(tempDeficit / UNDERFIRE_TEMP_DEFICIT_SCALE, UNDERFIRE_TEMP_DEFICIT_EXPONENT)
    end

    local quality = math.clamp(e.quality or 0.0, 0.0, 1.0)
    local qualityModifier = math.remap(quality, 0.0, 1.0, 1.0, 0.0)

    local temperModifier = e.tempered and UNDERFIRE_TEMPER_DAMAGE_FACTOR or 1.0

    local combinedRisk = tempRisk * qualityModifier * temperModifier
    local progressModifier = 1.0 + ((e.firingProgress or 0) * UNDERFIRE_PROGRESS_RISK_PER_PROGRESS)

    local kilnMultiplier = e.kilnMultiplier or 1.0
    local perHour = e.perHourBreakModifier or 0.1
    local resistance = e.breakResistance or 0.0

    local chance = combinedRisk * progressModifier * perHour * kilnMultiplier * (1 - resistance)
    chance = math.clamp(chance, 0, 1)

    if not e.cracked then
        chance = chance * (e.crackChanceMultiplier or 1.0)
    end

    return math.clamp(chance, 0, 1)
end

---Roll a per-hour chance over an arbitrary time period.
---Uses: P(event in n hours) = 1 - (1 - p)^n
---@param hours number
---@param chancePerHour number
---@return boolean triggered
function PotteryDamage.rollChanceOverHours(hours, chancePerHour)
    if (chancePerHour or 0) <= 0 then
        return false
    end

    local p = math.clamp(chancePerHour, 0, MAX_PER_HOUR_PROBABILITY)
    local totalChance = 1 - math.pow(1 - p, hours)
    logger:trace("Rolling damage: p/h=%.4f over %.6fh -> %.4f", p, hours, totalChance)
    return math.random() < totalChance
end

---Roll a hazard rate over an arbitrary time period.
---Uses: P(event in t hours) = 1 - exp(-ratePerHour * t)
---@param hours number
---@param ratePerHour number
---@return boolean triggered
function PotteryDamage.rollRateOverHours(hours, ratePerHour)
    if (hours or 0) <= 0 then
        return false
    end
    if (ratePerHour or 0) <= 0 then
        return false
    end

    local rate = math.max(ratePerHour, 0)
    local totalChance = 1 - math.exp(-rate * hours)
    totalChance = math.clamp(totalChance, 0, 1)
    logger:trace("Rolling damage: rate/h=%.4f over %.6fh -> %.4f", rate, hours, totalChance)
    return math.random() < totalChance
end

---@class Ashfall.Clay.PotteryDamage.ThermalShockParams
---@field currentTemperature number
---@field targetTemperature number? -- usually ambient (0) when removed from heat
---@field firingMinTemp number
---@field breakResistance number
---@field quality number? -- 0..1
---@field tempered boolean?

--- Rate-per-hour (hazard rate) of crack/break while cooling toward a lower target temperature.
--- Use with `rollRateOverHours(hoursElapsed, ratePerHour)`.
---@param e Ashfall.Clay.PotteryDamage.ThermalShockParams
---@return number ratePerHour
function PotteryDamage.calculateThermalShockRatePerHour(e)

    local minTemp = e.firingMinTemp or 0
    if minTemp <= 0 then
        return 0
    end

    local currentTemp = e.currentTemperature or 0
    local targetTemp = e.targetTemperature or 0

    -- Only while cooling and still hot.
    local safeTemp = PotteryDamage.getSafePickupTemperature(minTemp)
    if currentTemp <= safeTemp then
        return 0
    end

    if targetTemp >= currentTemp then
        return 0
    end

    -- How strong the thermal gradient is (bigger drop = more shock).
    local delta = currentTemp - targetTemp
    local minDelta = minTemp * THERMAL_SHOCK_MIN_DELTA_FACTOR
    if delta <= minDelta then
        return 0
    end

    -- 0 at safeTemp, 1 at minTemp (clamped). Still matters, but less than delta.
    local heatFactor = math.clamp(math.remap(currentTemp, safeTemp, minTemp, 0, 1), 0, 1)
    heatFactor = math.pow(heatFactor, THERMAL_SHOCK_HEAT_EXPONENT)

    -- 0 at minDelta, 1 at minTemp (clamped).
    local deltaFactor = math.clamp(math.remap(delta, minDelta, minTemp, 0, 1), 0, 1)
    deltaFactor = math.pow(deltaFactor, THERMAL_SHOCK_DELTA_EXPONENT)

    -- Craftsmanship modifiers.
    local quality = e.quality
    local qualityFactor = 1.0
    if type(quality) == "number" then
        qualityFactor = 1.0 + (1.0 - math.clamp(quality, 0.0, 1.0)) * THERMAL_SHOCK_QUALITY_RISK_MULT
    end

    local temperFactor = (e.tempered == true) and THERMAL_SHOCK_TEMPER_RISK_FACTOR or 1.0

    local resistance = e.breakResistance or 0.0

    -- Rate per hour (hazard rate). At max heat+delta this should crack nearly immediately.
    local ratePerHour = THERMAL_SHOCK_BASE_RATE_PER_HOUR
        * heatFactor
        * deltaFactor
        * qualityFactor
        * temperFactor
        * (1 - resistance)

    return math.clamp(ratePerHour, 0, THERMAL_SHOCK_MAX_RATE_PER_HOUR)
end

-- Backwards-compatible alias (older callers).
-- Returns a rate-per-hour, despite the historical name.
function PotteryDamage.calculateThermalShockChance(e)
    return PotteryDamage.calculateThermalShockRatePerHour(e)
end

return PotteryDamage
