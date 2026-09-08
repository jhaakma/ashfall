local common = require("mer.ashfall.common.common")
local logger = common.createLogger("Dampness")
local ItemInstance = require("CraftingFramework.carryableContainers.components.ItemInstance")
local DampVisuals = require("mer.ashfall.clay.Dampness.DampVisuals")
local TimeGapSimulator = require("CraftingFramework.components.TimeGapSimulator")
local HeatUtil = require("mer.ashfall.heat.HeatUtil")
local HeatCurve = require("mer.ashfall.heat.HeatCurve")
local Campfire = require("mer.ashfall.camping.campfire.Campfire")

---Class for managing dampness effect on pottery
---@class Ashfall.Clay.DampComponent : ItemInstance
---@field data Ashfall.Clay.DampComponent.data
---@field _dryRate number Dampness decrease rate per hour when drying
---@field _moistureRate number Dampness increase rate per hour when moistening
local DampComponent = {
    DATA_KEY = "Ashfall_DampComponent",
    DEFAULT_DRY_PER_HOUR = 0.1, -- Base dampness change per hour when drying without heat
    HEATED_DRY_PER_HOUR = 0.8, -- Dampness change per hour when on a heat source
    MOISTURE_PER_HOUR = 2.0, -- Dampness increase per hour when exposed to moisture
}

---@class Ashfall.Clay.DampComponent.data
---@field dampness number Dampness level from 0 (dry) to 1 (fully damp)
---@field lastUpdateTime number Last time the dampness was updated

---@class Ashfall.Clay.DampComponent.new.params : ItemInstance.new.params
---@field dryRate nil|number Override the default dry rate
---@field moistureRate nil|number Override the default moisture rate

---Constructor
---@param e Ashfall.Clay.DampComponent.new.params
---@return Ashfall.Clay.DampComponent
function DampComponent.new(e)
    local dampComponent = ItemInstance:new{
        item = e.item,
        itemData = e.itemData,
        reference = e.reference,
        dataKey = DampComponent.DATA_KEY,
    }
    setmetatable(dampComponent, { __index = DampComponent })
    ---@cast dampComponent Ashfall.Clay.DampComponent
    dampComponent._dryRate = e.dryRate or DampComponent.DEFAULT_DRY_PER_HOUR
    dampComponent._moistureRate = e.moistureRate or DampComponent.MOISTURE_PER_HOUR
    return dampComponent
end

function DampComponent:updateVisuals()
    if not (self.reference and self.reference.sceneNode) then
        logger:warn("No reference or sceneNode to update damp visuals")
        return
    end
    local dampness = self.data.dampness or 0
    DampVisuals.update(self.reference.sceneNode, dampness)
end

---Calculate dampness change toward a target value
---@param targetDampness number Target dampness level (0-1)
---@param dtHours number Time elapsed in hours
function DampComponent:stepTowardTargetDampness(targetDampness, dtHours, timestamp)
    local currentDampness = self.data.dampness or 0
    local dampDifference = targetDampness - currentDampness

    -- Use different rates depending on whether we're drying or moistening
    local rate = (dampDifference > 0) and self._moistureRate or self._dryRate
    local maxDampChange = rate * dtHours
    local dampChange = math.clamp(dampDifference, -maxDampChange, maxDampChange)
    local newDampness = math.clamp(currentDampness + dampChange, 0, 1)

    self.data.dampness = newDampness
    self.data.lastUpdateTime = timestamp or tes3.getSimulationTimestamp()

    logger:trace(
        "Dampness step: dt=%.3fh current=%.3f target=%.3f change=%.3f new=%.3f",
        dtHours,
        currentDampness,
        targetDampness,
        dampChange,
        newDampness
    )
end

---@class Ashfall.Clay.DampComponent.AdvanceOptions
---@field stepHours number? -- default 0.25
---@field targetDampnessAt fun(tHours: number): number -- function returning target dampness at time t
---@field onStep fun(e: {tHours: number, dtHours: number, oldDampness: number, newDampness: number, targetDampness: number}): (boolean|nil)? -- return false to stop
---@field startTimestamp number? -- simulation timestamp for t=0
---@field heatSource tes3reference? -- optional heat source to speed up drying
---@field heatType "strong"|"weak"? -- optional heat type for calculating heat effect
---@field heatSourceSnapshot any? -- optional pre-captured heat source snapshot for time-gap simulation

---Advance dampness over a time gap by stepping in small slices
---@param hoursElapsed number
---@param opts Ashfall.Clay.DampComponent.AdvanceOptions
function DampComponent:advance(hoursElapsed, opts)
    if not opts or type(opts.targetDampnessAt) ~= "function" then
        logger:error("DampComponent:advance() requires opts.targetDampnessAt")
        return
    end

    local startTimestamp = opts.startTimestamp or self.data.lastUpdateTime or tes3.getSimulationTimestamp()

    -- Create heat function to simulate fuel burn over time
    local targetHeatAt
    if not opts.heatSource then
        targetHeatAt = function(tHours) return 0 end
    else
        -- Use snapshot if provided, otherwise create one
        local snap = opts.heatSourceSnapshot or HeatCurve.snapshotFuelConsumer(opts.heatSource, opts.heatType)
        if snap then
            targetHeatAt = HeatCurve.makeTargetHeatFn(snap)
        else
            -- Fallback to constant heat if snapshot fails
            local heat = HeatUtil.getHeat(opts.heatSource, opts.heatType) or 0
            targetHeatAt = function(tHours) return heat end
        end
    end

    TimeGapSimulator.advance(hoursElapsed, {
        stepHours = opts.stepHours,
        targetValueAt = opts.targetDampnessAt,
        startTimestamp = startTimestamp,

        getCurrentValue = function()
            return self.data.dampness or 0
        end,

        stepTowardTarget = function(currentDampness, targetDampness, dt, timestamp)
            -- Calculate heat at this time step
            local tHours = timestamp - startTimestamp
            local heatAtTime = targetHeatAt(tHours)

            -- Scale drying rate based on heat
            -- If heat >= firing temp, use heated rate; otherwise interpolate
            local firingMinTemp = Campfire.STAGES.firing.minTemp
            local heatFactor = math.clamp(heatAtTime / firingMinTemp, 0, 1)
            local baseDryRate = DampComponent.DEFAULT_DRY_PER_HOUR
            local heatedDryRate = DampComponent.HEATED_DRY_PER_HOUR
            local scaledDryRate = baseDryRate + (heatedDryRate - baseDryRate) * heatFactor

            -- Temporarily override the drying rate for this step
            local oldDryRate = self._dryRate
            self._dryRate = scaledDryRate
            self:stepTowardTargetDampness(targetDampness, dt, timestamp)
            self._dryRate = oldDryRate
        end,

        onStep = function(e)
            -- Update visuals after each step
            self:updateVisuals()

            if opts.onStep then
                return opts.onStep({
                    tHours = e.tHours,
                    dtHours = e.dtHours,
                    oldDampness = e.oldValue,
                    newDampness = e.newValue,
                    targetDampness = e.targetValue,
                })
            end
        end,
    })
end



return DampComponent