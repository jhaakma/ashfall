local common = require("mer.ashfall.common.common")
local logger = common.createLogger("HeatedItem")
local ItemInstance = require("CraftingFramework.carryableContainers.components.ItemInstance")
local Campfire = require("mer.ashfall.camping.campfire.Campfire")
local HeatUtil = require("mer.ashfall.heat.HeatUtil")
local Glow = require("mer.ashfall.clay.Glow")

---Shared class for heat + glow mechanics (used by unfired and fired pottery).
---This is an ItemInstance with its own dataKey so heat persists independently.
---@class Ashfall.Clay.HeatedItem : ItemInstance
---@field data Ashfall.Clay.HeatedItem.data
---@field TEMP_CHANGE_RATE number
---@field _tempChangeRate number?
local HeatedItem = {
    DATA_KEY = "Ashfall_HeatedItem",
    ---Default temperature change rate (degrees per hour)
    TEMP_CHANGE_RATE = 5,
}

---@class Ashfall.Clay.HeatedItem.data
---@field currentTemperature number?
---@field highestTemperature number?
---@field lastTemperatureUpdate number?
---@field targetHeat number?
---@field lastHadHeatSource boolean?
---@field lastHeatSourceSnapshot any? -- caller-owned snapshot for time-gap simulation (e.g. HeatCurve snapshot)

---@class Ashfall.Clay.HeatedItem.new.params : ItemInstance.new.params
---@field tempChangeRate number?

---Construct from reference/itemData.
---@param e Ashfall.Clay.HeatedItem.new.params
---@return Ashfall.Clay.HeatedItem?
function HeatedItem:new(e)
    if e.reference and not e.reference.supportsLuaData then return end

    local heated = ItemInstance:new{
        item = e.item,
        itemData = e.itemData,
        reference = e.reference,
        dataKey = HeatedItem.DATA_KEY,
        logger = e.logger or logger,
    }
    setmetatable(heated, self)
    self.__index = self
    ---@cast heated Ashfall.Clay.HeatedItem
    heated._tempChangeRate = e.tempChangeRate
    return heated --[[@as Ashfall.Clay.HeatedItem]]
end

---@return number
function HeatedItem:getTempChangeRate()
    return self._tempChangeRate or self.TEMP_CHANGE_RATE
end

---Attach glow material to this reference's sceneNode.
function HeatedItem:attachGlow()
    if not self.reference or not self.reference.sceneNode then
        return
    end
    Glow.attachToNode(self.reference.sceneNode)
end

---Updates the diffuse material color from white to red based on current temperature.
function HeatedItem:updateGlow()
    if not self.reference or not self.reference.sceneNode then
        return
    end
    local temperatureRatio = math.remap(
        self.data.currentTemperature or 0,
        0, Campfire.STAGES.firing.minTemp,
        0, 1.0
    )
    local strength = math.clamp(temperatureRatio, 0, 1)

    -- If the glow controller hasn't been attached yet (e.g., manager didn't fire
    -- onActivated for this reference), attach and retry.
    local updated = Glow.setStrength(self.reference.sceneNode, strength)
    if (not updated) and strength > 0 then
        logger:error("Glow controller not found; attaching glow and retrying")
        self:attachGlow()
        Glow.setStrength(self.reference.sceneNode, strength)
    end
end

---Reset the last temperature update to nil.
function HeatedItem:resetLastTemperatureUpdate()
    self.data.lastTemperatureUpdate = nil
end

---Calculate what the new temperature would be given a target temperature.
---Temperature changes linearly over time based on configured change rate.
---@param targetTemperature number
---@return number newTemperature
function HeatedItem:calculateNewTemperature(targetTemperature)
    local now = tes3.getSimulationTimestamp()
    local lastUpdate = self.data.lastTemperatureUpdate or now
    local hoursElapsed = now - lastUpdate

    local currentTemp = self.data.currentTemperature or 0
    local tempDifference = targetTemperature - currentTemp

    -- Speed up heating/cooling when the temperature difference is large.
    local differenceEffect = math.remap(math.abs(tempDifference), 0, Campfire.STAGES.firing.minTemp, 1.0, 10.0)
    differenceEffect = math.max(differenceEffect, 1.0)

    local maxTempChange = self:getTempChangeRate() * hoursElapsed * differenceEffect
    local tempChange = math.clamp(tempDifference, -maxTempChange, maxTempChange)
    local newTemp = currentTemp + tempChange

    logger:trace(
        "Temperature calculation: current=%s, target=%s, elapsed=%.2fh, change=%s, new=%s",
        currentTemp,
        targetTemperature,
        hoursElapsed,
        tempChange,
        newTemp
    )

    return newTemp
end

---Set the temperature, updating `highestTemperature` if necessary.
---@param newTemperature number
function HeatedItem:setTemperature(newTemperature)
    self:setTemperatureAt(newTemperature, tes3.getSimulationTimestamp())
end

---Set the temperature at an explicit simulation timestamp.
---This is required for long time-gap simulation where we advance in slices.
---@param newTemperature number
---@param timestamp number
function HeatedItem:setTemperatureAt(newTemperature, timestamp)
    self.data.currentTemperature = newTemperature
    self.data.lastTemperatureUpdate = timestamp
    if newTemperature > (self.data.highestTemperature or 0) then
        self.data.highestTemperature = newTemperature
    end
end

---Get a snapshot of current heat state (safe to transfer between items).
---@return Ashfall.Clay.HeatedItem.data
function HeatedItem:getHeatData()
    return {
        currentTemperature = self.data.currentTemperature,
        highestTemperature = self.data.highestTemperature,
        lastTemperatureUpdate = self.data.lastTemperatureUpdate,
        targetHeat = self.data.targetHeat,
        lastHadHeatSource = self.data.lastHadHeatSource,
        lastHeatSourceSnapshot = self.data.lastHeatSourceSnapshot,
    }
end

---Apply a heat snapshot.
---@param heatData Ashfall.Clay.HeatedItem.data
function HeatedItem:setHeatData(heatData)
    self.data.currentTemperature = heatData.currentTemperature
    self.data.highestTemperature = heatData.highestTemperature
    self.data.lastTemperatureUpdate = heatData.lastTemperatureUpdate
    self.data.targetHeat = heatData.targetHeat
    self.data.lastHadHeatSource = heatData.lastHadHeatSource
    self.data.lastHeatSourceSnapshot = heatData.lastHeatSourceSnapshot
end

---@class Ashfall.Clay.HeatedItem.UpdateEvent
---@field oldTemperature number
---@field newTemperature number
---@field targetHeat number
---@field dtHours number?

---@class Ashfall.Clay.HeatedItem.UpdateOptions
---@field onHeatUpdated fun(heated: Ashfall.Clay.HeatedItem, e: Ashfall.Clay.HeatedItem.UpdateEvent)?

---Update towards a target heat, firing callbacks if provided.
---@param targetHeat number
---@param opts Ashfall.Clay.HeatedItem.UpdateOptions?
function HeatedItem:updateToTargetHeat(targetHeat, opts)
    local oldTemp = self.data.currentTemperature or 0
    self.data.targetHeat = targetHeat

    local newTemp = self:calculateNewTemperature(targetHeat)
    -- Mirror previous behavior: always update the timestamp.
    self:setTemperature(newTemp)

    if opts and opts.onHeatUpdated then
        opts.onHeatUpdated(self, {
            oldTemperature = oldTemp,
            newTemperature = newTemp,
            targetHeat = targetHeat,
            dtHours = nil,
        })
    end
end

---Update towards heat from a heat source reference.
---@param heatSource tes3reference|nil
---@param opts Ashfall.Clay.HeatedItem.UpdateOptions?
function HeatedItem:updateFromHeatSource(heatSource, opts)
    local heat = HeatUtil.getHeat(heatSource) or 0
    self:updateToTargetHeat(heat, opts)
end

---Step temperature one discrete in-game hour toward a target heat.
---Used by pottery firing simulation where other per-hour mechanics also run.
---@param targetHeat number
---@param opts Ashfall.Clay.HeatedItem.UpdateOptions?
function HeatedItem:stepTowardTargetHeatOneHour(targetHeat, opts)
    self:stepTowardTargetHeat(targetHeat, 1.0, opts)
end

---Step temperature toward a target heat over an arbitrary time slice.
---Uses the same “differenceEffect” acceleration as calculateNewTemperature,
---but with an explicit dt so callers can simulate large gaps safely.
---@param targetHeat number
---@param dtHours number
---@param opts Ashfall.Clay.HeatedItem.UpdateOptions?
---@param timestamp number?
function HeatedItem:stepTowardTargetHeat(targetHeat, dtHours, opts, timestamp)
    local dt = math.max(dtHours or 0, 0)
    if dt == 0 then
        return
    end

    local oldTemp = self.data.currentTemperature or 0
    self.data.targetHeat = targetHeat

    local tempDiff = targetHeat - oldTemp
    local differenceEffect = math.remap(math.abs(tempDiff), 0, Campfire.STAGES.firing.minTemp, 1.0, 10.0)
    differenceEffect = math.max(differenceEffect, 1.0)

    local maxTempChange = self:getTempChangeRate() * dt * differenceEffect
    local tempChange = math.clamp(tempDiff, -maxTempChange, maxTempChange)
    local newTemp = oldTemp + tempChange

    logger:trace(
        "Step: dt=%.3fh current=%s target=%s change=%s new=%s",
        dt,
        oldTemp,
        targetHeat,
        tempChange,
        newTemp
    )

    local ts = timestamp or tes3.getSimulationTimestamp()
    self:setTemperatureAt(newTemp, ts)

    if opts and opts.onHeatUpdated then
        opts.onHeatUpdated(self, {
            oldTemperature = oldTemp,
            newTemperature = newTemp,
            targetHeat = targetHeat,
            dtHours = dt,
        })
    end
end

---@class Ashfall.Clay.HeatedItem.AdvanceEvent
---@field tHours number -- elapsed time since the start of advance
---@field dtHours number
---@field oldTemperature number
---@field newTemperature number
---@field targetHeat number

---@class Ashfall.Clay.HeatedItem.AdvanceOptions
---@field stepHours number? -- default 0.25
---@field targetHeatAt fun(tHours: number): number
---@field updateOptions Ashfall.Clay.HeatedItem.UpdateOptions?
---@field onStep fun(heated: Ashfall.Clay.HeatedItem, e: Ashfall.Clay.HeatedItem.AdvanceEvent): (boolean|nil)? -- return false to stop early
---@field startTimestamp number? -- simulation timestamp corresponding to tHours=0

---Advance temperature over a time gap by stepping in small slices.
---Callers supply a target-heat function so heat sources can decay during the gap.
---@param hoursElapsed number
---@param opts Ashfall.Clay.HeatedItem.AdvanceOptions
function HeatedItem:advance(hoursElapsed, opts)
    local total = math.max(hoursElapsed or 0, 0)
    if total <= 0 then
        return
    end

    local stepHours = (opts and opts.stepHours) or 0.25
    if stepHours <= 0 then
        stepHours = total
    end

    local targetHeatAt = opts and opts.targetHeatAt
    if type(targetHeatAt) ~= "function" then
        logger:error("HeatedItem:advance() requires opts.targetHeatAt")
        return
    end

    local onStep = opts and opts.onStep
    local updateOptions = opts and opts.updateOptions

    -- Establish a virtual time origin so multi-slice advancement leaves a coherent
    -- `lastTemperatureUpdate` that matches the simulated progression.
    local startTimestamp = (opts and opts.startTimestamp) or self.data.lastTemperatureUpdate or tes3.getSimulationTimestamp()

    local remaining = total
    local t = 0
    while remaining > 0 do
        local dt = math.min(stepHours, remaining)

        local targetHeat = targetHeatAt(t)
        local oldTemp = self.data.currentTemperature or 0
        local stepTimestamp = startTimestamp + t + dt
        self:stepTowardTargetHeat(targetHeat, dt, updateOptions, stepTimestamp)
        local newTemp = self.data.currentTemperature or 0

        if onStep then
            local continue = onStep(self, {
                tHours = t,
                dtHours = dt,
                oldTemperature = oldTemp,
                newTemperature = newTemp,
                targetHeat = targetHeat,
            })
            if continue == false then
                break
            end
        end

        remaining = remaining - dt
        t = t + dt
    end
end

return HeatedItem
