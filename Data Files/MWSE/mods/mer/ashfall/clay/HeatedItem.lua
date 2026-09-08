local common = require("mer.ashfall.common.common")
local logger = common.createLogger("HeatedItem")
local ItemInstance = require("CraftingFramework.carryableContainers.components.ItemInstance")
local Campfire = require("mer.ashfall.camping.campfire.Campfire")
local GlowVisuals = require("mer.ashfall.clay.Visuals.GlowVisuals")
local TimeGapSimulator = require("CraftingFramework.components.TimeGapSimulator")
local PotteryTooltips = require("mer.ashfall.clay.PotteryTooltips")
local PotteryRecipe = require("mer.ashfall.clay.PotteryRecipe")

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

    local hadHeatData = e.reference
        and e.reference.supportsLuaData
        and e.reference.data
        and e.reference.data[HeatedItem.DATA_KEY] ~= nil

    local heated = ItemInstance:new{
        item = e.item,
        itemData = e.itemData,
        reference = e.reference,
        dataKey = HeatedItem.DATA_KEY,
    }
    setmetatable(heated, self)
    self.__index = self
    ---@cast heated Ashfall.Clay.HeatedItem
    heated._tempChangeRate = e.tempChangeRate or self.TEMP_CHANGE_RATE
    if e.reference
        and e.reference.supportsLuaData
        and not hadHeatData
        and e.reference.data
        and e.reference.data[HeatedItem.DATA_KEY] ~= nil
    then
        event.trigger("Ashfall:registerReference", { reference = e.reference })
    end
    return heated --[[@as Ashfall.Clay.HeatedItem]]
end

---@return number
function HeatedItem:getTempChangeRate()
    return self._tempChangeRate or self.TEMP_CHANGE_RATE
end


---Updates the diffuse material color from white to red based on current temperature.
function HeatedItem:updateVisuals()
    if not self.reference or not self.reference.sceneNode then
        return
    end
    local temperatureRatio = math.remap(
        self.data.currentTemperature or 0,
        0, Campfire.STAGES.firing.minTemp,
        0, 1.0
    )
    local strength = math.clamp(temperatureRatio, 0, 1)
    GlowVisuals.update(self.reference.sceneNode, strength)
end

---@return number
function HeatedItem:getCurrentTemperature()
    return self.data.currentTemperature or 0
end

---@class Ashfall.Clay.HeatedItem.PickupGuardOptions
---@field message string?

---Returns false to block activation if this item is too hot to pick up.
---Items at cooking stage (1 degree) or higher are too hot.
---@param opts Ashfall.Clay.HeatedItem.PickupGuardOptions?
---@return boolean|nil False to block activation
function HeatedItem:blockPickupIfTooHot(opts)
    local currentTemp = self:getCurrentTemperature()
    -- Too hot if at or above cooking stage
    if currentTemp >= Campfire.STAGES.cooking.minTemp then
        tes3.messageBox((opts and opts.message) or "It is too hot to pick up.")
        return false
    end

    --Otherwise, if allowing to pick up, remove heat data
    self:clearData()
end

---Reset the last temperature update to nil.
function HeatedItem:resetLastTemperatureUpdate()
    self.data.lastTemperatureUpdate = nil
end

function HeatedItem:clearData()
    self.data.currentTemperature = nil
    self.data.highestTemperature = nil
    self.data.lastTemperatureUpdate = nil
    self.data.targetHeat = nil
    self.data.lastHadHeatSource = nil
    self.data.lastHeatSourceSnapshot = nil
end

---If all data field are nil or false, remove the Ashfall_HeatedItem table entirely
---to allow item stacking
function HeatedItem:clearDataIfEmpty()
    if self.data and (
        self.data.currentTemperature or
        self.data.highestTemperature or
        self.data.lastTemperatureUpdate or
        self.data.targetHeat or
        self.data.lastHadHeatSource or
        self.data.lastHeatSourceSnapshot
    ) then
        return
    end
    logger:trace("Clearing empty data table for %s", self.item.id)
    self.dataHolder.data[HeatedItem.DATA_KEY] = nil
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
    event.trigger("Ashfall:RegisterReference", { reference = self.reference })
end

---@class Ashfall.Clay.HeatedItem.UpdateEvent
---@field oldTemperature number
---@field newTemperature number
---@field targetHeat number
---@field dtHours number?

---@class Ashfall.Clay.HeatedItem.UpdateOptions
---@field onHeatUpdated fun(heated: Ashfall.Clay.HeatedItem, e: Ashfall.Clay.HeatedItem.UpdateEvent)?


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
    if not opts or type(opts.targetHeatAt) ~= "function" then
        logger:error("HeatedItem:advance() requires opts.targetHeatAt")
        return
    end

    local updateOptions = opts.updateOptions
    local startTimestamp = opts.startTimestamp or self.data.lastTemperatureUpdate or tes3.getSimulationTimestamp()

    TimeGapSimulator.advance(hoursElapsed, {
        stepHours = opts.stepHours,
        targetValueAt = opts.targetHeatAt,
        startTimestamp = startTimestamp,
        getCurrentValue = function()
            return self.data.currentTemperature or 0
        end,

        stepTowardTarget = function(currentTemp, targetHeat, dt, timestamp)
            self:stepTowardTargetHeat(targetHeat, dt, updateOptions, timestamp)
        end,

        onStep = function(e)
            if opts.onStep then
                -- Adapt the generic event to HeatedItem's legacy format
                return opts.onStep(self, {
                    tHours = e.tHours,
                    dtHours = e.dtHours,
                    oldTemperature = e.oldValue,
                    newTemperature = e.newValue,
                    targetHeat = e.targetValue,
                })
            end
        end,
    })
end

---Check if a reference is a heated item
---@param ref tes3reference
---@return boolean
function HeatedItem.isHeatedItem(ref)
    if not ref or not ref.supportsLuaData then
        return false
    end
    local itemData = ref.data
    if not itemData then
        return false
    end
    return itemData[HeatedItem.DATA_KEY] ~= nil
end

---@param e activateEventData
function HeatedItem.onActivate(e)
    local isHeatedItem = HeatedItem.isHeatedItem(e.target)
    if not isHeatedItem then
        return
    end
    local heated = HeatedItem:new{ reference = e.target }
    if heated then return heated:blockPickupIfTooHot() end
end

---@param e uiObjectTooltipEventData
function HeatedItem.onUiObjectTooltip(e)
    if not e or not e.object then
        return
    end

    local hasHeatData = false
    if e.itemData and e.itemData.data and e.itemData.data[HeatedItem.DATA_KEY] then
        hasHeatData = true
    elseif e.reference and HeatedItem.isHeatedItem(e.reference) then
        hasHeatData = true
    end

    if not hasHeatData then
        return
    end

    local heated = HeatedItem:new{ item = e.object, itemData = e.itemData, reference = e.reference }
    if not heated then
        return
    end

    local kind = "fired"
    if PotteryRecipe.isPotteryItem(e.object) then
        kind = "unfired"
    end

    local tempLabel = PotteryTooltips.getTemperatureLabel(heated, { kind = kind })
    if tempLabel then
        PotteryTooltips.addLabelsToTooltip(e.tooltip, { tempLabel })
    end
end

return HeatedItem
