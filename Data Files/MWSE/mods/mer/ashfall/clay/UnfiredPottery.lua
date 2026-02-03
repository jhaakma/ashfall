local common = require("mer.ashfall.common.common")
local logger = common.createLogger("UnfiredPottery")
local ItemInstance = require("CraftingFramework.carryableContainers.components.ItemInstance")
local PotteryRecipe = require("mer.ashfall.clay.PotteryRecipe")
local PotteryDecals = require("mer.ashfall.clay.PotteryDecals")
local PotteryBreaking = require("mer.ashfall.clay.PotteryBreaking")
local RawClay = require("mer.ashfall.clay.RawClay")
local FiredPottery = require("mer.ashfall.clay.FiredPottery")
local Campfire = require("mer.ashfall.camping.campfire.Campfire")
local HeatUtil = require("mer.ashfall.heat.HeatUtil")
local HeatedItem = require("mer.ashfall.clay.HeatedItem")
local PotteryDamage = require("mer.ashfall.clay.PotteryDamage")
local Temper = require("mer.ashfall.clay.Temper")
local HeatCurve = require("mer.ashfall.heat.HeatCurve")

---Class for managing instances of unfired pottery items
---@class Ashfall.UnfiredPottery : ItemInstance
---@field data Ashfall.UnfiredPotteryData
local UnfiredPottery = {
    ---The number of hours required to fire a small pottery item
    MIN_FIRING_HOURS = 6,
    ---The number of hours required to fire a large pottery item
    MAX_FIRING_HOURS = 12,
    ---The rate at which temperature changes per hour (degrees per hour)
    TEMP_CHANGE_RATE = 5,
    ---Multiplier for crack chance (makes cracking happen earlier)
    CRACK_CHANCE_MULTIPLIER = 2.0,
    ---Modifier for break chance per hour
    PER_HOUR_BREAK_MODIFIER = 0.1,
    ---Break risk categories
    BREAK_RISK_LEVELS = {
        {threshold = 0.50, name = "Critical!", color = {1.0, 0.0, 0.0}},
        {threshold = 0.20, name = "High",      color = {1.0, 0.3, 0.0}},
        {threshold = 0.05, name = "Medium",    color = {1.0, 0.7, 0.0}},
        {threshold = 0.01, name = "Low",       color = {1.0, 1.0, 0.4}},
        {threshold = 0.001, name = "Minimal",  color = {0.8, 0.8, 0.6}},
    },
}


---Pottery-specific stages (different names from general campfire stages)
---@type { minTemp: number, name: string, color: number[] }[]
UnfiredPottery.COLOR_STAGES = {
    {
        minTemp = Campfire.STAGES.glazing.minTemp,
        name = "Glazing",
        color = Campfire.STAGES.glazing.color
    },
    {
        minTemp = Campfire.STAGES.firing.minTemp,
        name = "Firing",
        color = {1.0, 0.3, 0.3}
    },
    {
        minTemp = 0,
        name = "Heating Up",
        color = {1.0, 0.8, 0.4}
    },
}


---@class Ashfall.UnfiredPotteryData
---@field firingHoursRemaining number? The number of in-game hours remaining to complete firing
---@field lastFiredTimestamp number? The simulation timestamp when the item was last processed for firing
---@field cracked boolean? Whether the pottery is cracked
---@field broken boolean? Whether the pottery is broken. This should only be true during breaking animation, as it gets deleted right after
---@field quality number? A value from 0.0 (terrible) to 1.0 (perfect) representing the quality of the pottery item

---Get the shared heated-item state for this pottery.
---@return Ashfall.Clay.HeatedItem?
function UnfiredPottery:getHeatedItem()
    local heated = HeatedItem:new{
        item = self.item,
        itemData = self.dataHolder,
        reference = self.reference,
        tempChangeRate = self.TEMP_CHANGE_RATE,
    }
    if not heated then
        return nil
    end
    return heated
end

---@param heated Ashfall.Clay.HeatedItem
---@return Ashfall.Clay.HeatedItem.UpdateOptions
function UnfiredPottery:getHeatUpdateOptions(heated)
    return {
        onHeatUpdated = function(h)
            -- Unfired pottery controls visuals when heat changes.
            h:updateGlow()
        end
    }
end

---Construct from reference
---@param e ItemInstance.new.params
---@return Ashfall.UnfiredPottery?
function UnfiredPottery:new(e)
    if e.reference and not e.reference.supportsLuaData then return end

    local item = e.item or e.reference.baseObject

    logger:trace("UnfiredPottery:new() called for reference: %s", item.id)
    if not UnfiredPottery.isUnfiredItem(item) then
        logger:error("Attempted to create UnfiredPottery from non-unfired item: " .. item.id)
        return nil
    end
    local unfiredPottery = ItemInstance:new{
        item = item,
        itemData = e.itemData,
        reference = e.reference,
        dataKey = "Ashfall_UnfiredPottery",
    }
    setmetatable(unfiredPottery, self)
    self.__index = self
    return unfiredPottery --[[@as Ashfall.UnfiredPottery]]
end

---Updates the diffuse material color from white to red based on temperature
function UnfiredPottery:updateGlow()
    logger:trace("UnfiredPottery:updateGlow() called")
    if not self.reference then
        logger:warn("UnfiredPottery:updateGlow() called but no reference present")
        return
    end
    local heated = self:getHeatedItem()
    if heated then
        heated:updateGlow()
    end
end

---Runs on timer to update firing progress
---@param heatSource tes3reference|nil The heat level from the fire source
function UnfiredPottery:updateFiring(heatSource)
    if self.data.broken then
        return
    end
    logger:trace("UnfiredPottery:updateFiring() called with heat: %s", heatSource)
    local heated = self:getHeatedItem()
    if not heated then
        return
    end

    local now = tes3.getSimulationTimestamp()
    local startTimestamp = self.data.lastFiredTimestamp or (heated.data.lastTemperatureUpdate or now)
    local hoursElapsed = now - startTimestamp
    if hoursElapsed < 0 then
        hoursElapsed = 0
    end

    local updateOptions = self:getHeatUpdateOptions(heated)

    -- Ensure we have an initial snapshot to simulate fuel burn during long waits.
    if heatSource and not heated.data.lastHeatSourceSnapshot then
        heated.data.lastHeatSourceSnapshot = HeatCurve.snapshotFuelConsumer(heatSource)
    end

    -- Build a target-heat function for this time gap.
    -- Prefer the previous snapshot so fuel burn is simulated across long waits.
    local targetHeatAt
    if not heatSource then
        targetHeatAt = HeatCurve.makeConstantTargetHeatFn(0)
    else
        local snap = heated.data.lastHeatSourceSnapshot
        local sameSource = snap and snap.id and heatSource.object and (snap.id:lower() == heatSource.object.id:lower())
        if snap and sameSource then
            targetHeatAt = HeatCurve.makeTargetHeatFn(snap)
        else
            targetHeatAt = HeatCurve.makeConstantTargetHeatFn(HeatUtil.getHeat(heatSource) or 0)
        end
    end

    heated:advance(hoursElapsed, {
        stepHours = 0.25,
        targetHeatAt = targetHeatAt,
        updateOptions = updateOptions,
        startTimestamp = startTimestamp,
        onStep = function(_, e)
            if self.data.broken or not self.reference then
                return false
            end

            -- Roll for cracking/breaking over this slice.
            if self:rollForDamage(e.dtHours, heatSource) then
                if self.data.cracked then
                    self:breakPottery()
                    return false
                else
                    self:crackPottery()
                end
            end

            -- Progress firing while hot enough.
            if self:canFire() then
                local remaining = self.data.firingHoursRemaining or self:getFiringTimeHours()
                remaining = remaining - e.dtHours
                if remaining <= 0 then
                    -- Completion time within the catch-up gap (approx to the end of this step).
                    self:completeFiring(heatSource, e.tHours + e.dtHours)
                    return false
                end
                self.data.firingHoursRemaining = remaining
            end

            return true
        end,
    })

    -- If the item was replaced/deleted during firing, stop.
    if self.data.broken or not self.reference then
        return
    end

    self:setLastFiredTimestamp()

    -- Persist a new heat-source snapshot for the next update gap.
    heated.data.lastHadHeatSource = heatSource ~= nil
    heated.data.lastHeatSourceSnapshot = heatSource and HeatCurve.snapshotFuelConsumer(heatSource) or nil
end

--Check if player notifications (sounds and messageBoxes) should be played,
--Only notify player if they are nearby when the event occurs
---@return boolean
function UnfiredPottery:shouldNotifyPlayer()
    -- local hoursSinceLastUpdate = self:getHoursSinceLastUpdate()
    -- return hoursSinceLastUpdate < 0.1
    return true
end

---Get the time since last update
---@return number hoursElapsed
function UnfiredPottery:getHoursSinceLastUpdate()
    logger:trace("UnfiredPottery:getHoursSinceLastUpdate() called")
    local now = tes3.getSimulationTimestamp()
    local lastUpdate = self.data.lastFiredTimestamp or now
    local hoursElapsed = now - lastUpdate
    logger:trace("Hours since last update: %s", hoursElapsed)
    return hoursElapsed
end

---Calculate the remaining firing time based on elapsed time since last update
---@return number The number of hours remaining to complete firing
function UnfiredPottery:calculateRemainingFiringTime()
    logger:trace("UnfiredPottery:calculateRemainingFiringTime() called")
    local now = tes3.getSimulationTimestamp()
    local hoursSinceLastFired = now - (self.data.lastFiredTimestamp or now)
    local previousHoursRemaining = self.data.firingHoursRemaining or self:getFiringTimeHours()
    logger:trace("Hours since last fired: %s, hours remaining: %s", hoursSinceLastFired, previousHoursRemaining)
    return previousHoursRemaining - hoursSinceLastFired
end



function UnfiredPottery:canFire()
    logger:trace("UnfiredPottery:canFire() called")
    local heated = self:getHeatedItem()
    local currentTemp = heated and (heated.data.currentTemperature or 0) or 0
    local canFire = currentTemp >= Campfire.STAGES.firing.minTemp
    logger:trace("canFire result: %s (currentTemp: %s, minTemp: %s)", canFire, currentTemp, Campfire.STAGES.firing.minTemp)
    return canFire
end

---Update the lastFiredTimestamp to the current simulation time
function UnfiredPottery:setLastFiredTimestamp()
    logger:trace("UnfiredPottery:setLastFiredTimestamp() called")
    self.data.lastFiredTimestamp = tes3.getSimulationTimestamp()
    logger:trace("Timestamp set to: %s", self.data.lastFiredTimestamp)
end

--Reset the last fired timestamp to nil
function UnfiredPottery:resetLastFiredTimestamp()
    logger:trace("UnfiredPottery:resetLastFiredTimestamp() called")
    self.data.lastFiredTimestamp = nil
end

--Reset the last tempaerature update to nil
function UnfiredPottery:resetLastTemperatureUpdate()
    logger:trace("UnfiredPottery:resetLastTemperatureUpdate() called")
    local heated = self:getHeatedItem()
    if heated then
        heated:resetLastTemperatureUpdate()
    end
end

---Calculate what the new temperature would be given a target temperature
---Temperature changes linearly over time based on TEMP_CHANGE_RATE
---@param targetTemperature number The target temperature (from fire heat)
---@return number newTemperature The calculated new temperature
function UnfiredPottery:calculateNewTemperature(targetTemperature)
    local heated = self:getHeatedItem()
    if not heated then
        return 0
    end
    return heated:calculateNewTemperature(targetTemperature)
end

---Set the temperature of the pottery item, updating highestTemperature if necessary
---@param newTemperature number The new temperature (pre-calculated)
function UnfiredPottery:setTemperature(newTemperature)
    logger:trace("UnfiredPottery:setTemperature() called with new temperature: %s", newTemperature)

    local heated = self:getHeatedItem()
    if not heated then
        return
    end
    local previousHighest = heated.data.highestTemperature or 0
    heated:setTemperature(newTemperature)
    if newTemperature > previousHighest then
        logger:trace("New highest temperature reached: %s", newTemperature)
    end
end
---Simulate firing over a large time gap by processing hour-by-hour
---This handles cases where the player was in another cell and time passed without updates
---@param heated Ashfall.Clay.HeatedItem
---@param previousHeat number|nil The heat level from the previous update
---@param currentHeat number|nil The current heat level from fire source
---@param heatSource tes3reference|nil The heat source reference
function UnfiredPottery:simulateTimeGap(heated, previousHeat, currentHeat, heatSource)

    local startHeat = previousHeat or 0
    local endHeat = currentHeat or 0
    logger:trace("UnfiredPottery:simulateTimeGap() called with heat range: %s -> %s", startHeat, endHeat)

    local hoursElapsed = self:getHoursSinceLastUpdate()
    local simulatedHours = math.floor(hoursElapsed)

    logger:trace("Simulating %s hours of firing", simulatedHours)

    -- Simulate each hour
    for hour = 1, simulatedHours do
        -- Interpolate heat between start and end values
        local heatProgress = (hour - 1) / math.max(simulatedHours - 1, 1)
        local targetHeat = startHeat + (endHeat - startHeat) * heatProgress

        heated:stepTowardTargetHeatOneHour(targetHeat, self:getHeatUpdateOptions(heated))

        -- Roll for cracking/breaking this hour
        if self:rollForDamage(1, heatSource) then
            if self.data.cracked then
                logger:trace("Pottery broke during hour %s", hour)
                self:breakPottery()
                return
            else
                logger:trace("Pottery cracked during hour %s", hour)
                self:crackPottery()
            end
        end

        -- Check if firing can progress
        if self:canFire() then
            local previousRemaining = self.data.firingHoursRemaining or self:getFiringTimeHours()
            local newRemaining = previousRemaining - 1

            logger:trace("Firing progress: %s hours remaining", newRemaining)

            if newRemaining <= 0 then
                logger:trace("Pottery completed during hour %s", hour)
                self:completeFiring()
                return
            end

            self.data.firingHoursRemaining = newRemaining
        end
    end

    -- Update timestamp after simulation
    self:setLastFiredTimestamp()
    logger:trace("Simulation complete")
end


---Calculate the chance per hour that pottery will break
---@param heatSource tes3reference|nil The heat source reference
---@return number chancePerHour The probability (0-1) that pottery breaks each hour
function UnfiredPottery:calculateDamageChance(heatSource)
    local heated = self:getHeatedItem()
    local currentTemp = heated and (heated.data.currentTemperature or 0) or 0
    local highestTemp = heated and (heated.data.highestTemperature or 0) or 0
    local progress = self:getFiringProgress()

    local kilnModifier = 1.0
    if heatSource then
        logger:trace("Checking kiln data for heat source: %s", heatSource.object.id)
        local campfireData = Campfire.getCampfire(heatSource.object.id)
        if campfireData and campfireData.damageChanceMultiplier then
            kilnModifier = campfireData.damageChanceMultiplier
        else
            logger:trace("No kiln data or damageChanceMultiplier found for heat source")
        end
    end
    logger:trace("Kiln modifier: %.4f", kilnModifier)

    local tempered = Temper:new{
        item = self.item,
        itemData = self.dataHolder,
        reference = self.reference,
    }
    local isTempered = tempered and tempered:hasTemper() or false

    local resistance = self:getRecipe().breakResistance or 0.0
    logger:trace("Break resistance: %.4f", resistance)

    local chance = PotteryDamage.calculateUnderfireChance{
        currentTemperature = currentTemp,
        highestTemperature = highestTemp,
        firingMinTemp = Campfire.STAGES.firing.minTemp,
        firingProgress = progress,
        quality = self.data.quality or 0.0,
        tempered = isTempered,
        kilnMultiplier = kilnModifier,
        breakResistance = resistance,
        cracked = self.data.cracked == true,
        crackChanceMultiplier = self.CRACK_CHANCE_MULTIPLIER,
        perHourBreakModifier = self.PER_HOUR_BREAK_MODIFIER,
    }

    logger:trace("Final break chance per hour: %.4f", chance)
    return chance
end

---Get damage modifier based on if the item is tempered
---@return number damageModifier
function UnfiredPottery:getTemperDamageModifier()
    local tempered = Temper:new{
        item = self.item,
        itemData = self.dataHolder,
        reference = self.reference
    }
    local isTempered = tempered and tempered:hasTemper() or false
    return isTempered and 0.5 or 1.0
end


---Get quality modifier for break calculations
---@return number qualityModifier Value from 0 (perfect) to 1.0 (terrible)
function UnfiredPottery:getQualityRisk()
    return math.remap(self.data.quality or 0.0, 0.0, 1.0, 1.0, 0.0)
end

---Get temperature modifier for break calculations
---@return integer
function UnfiredPottery:getTemperatureRisk()
    local heated = self:getHeatedItem()
    local currentTemp = heated and (heated.data.currentTemperature or 0) or 0
    if currentTemp >= Campfire.STAGES.firing.minTemp then
        return 1
    end
    local tempDeficit = Campfire.STAGES.firing.minTemp - currentTemp
    local tempRisk = 1 + math.pow(tempDeficit / 1.5, 3)
    return tempRisk
end

---Get progress modifier for break calculations
---@return number progressModifier Multiplier ranging from 0.5 to 2.0
function UnfiredPottery:getProgressRiskModifier(progress)
    local progressModifier = 1.0 + (progress * 0.25) --  1.0x to 1.25x
    return progressModifier
end

---Roll to check if pottery breaks over a time period
---@param hours number The number of hours that passed
---@param heatSource tes3reference|nil The heat source reference
---@return boolean True if pottery broke
function UnfiredPottery:rollForDamage(hours, heatSource)
    logger:trace("UnfiredPottery:rollForDamage() called for %.8f hours", hours)

    local chancePerHour = self:calculateDamageChance(heatSource)
    if chancePerHour == 0 then
        logger:trace("No break chance calculated, skipping roll")
        return false
    end

    return PotteryDamage.rollChanceOverHours(hours, chancePerHour)
end

---Crack the pottery item, setting cracked status and applying visual effects
function UnfiredPottery:crackPottery()
    if not self.reference then
        logger:warn("UnfiredPottery:crackPottery() called but no reference present")
        return
    end
    if self.data.cracked then
        logger:warn("UnfiredPottery:crackPottery() called but pottery is already cracked")
        return
    end
    local shouldNotifyPlayer = self:shouldNotifyPlayer()
    PotteryBreaking.crackPottery(self.reference, self.data, shouldNotifyPlayer)
end

--Break the pottery item, replacing it with animated broken clay activator
function UnfiredPottery:breakPottery()
    if not self.reference then
        logger:warn("UnfiredPottery:breakPottery() called but no reference present")
        return
    end
    if self.data.broken then
        logger:warn("UnfiredPottery:breakPottery() called but pottery is already broken")
        return
    end
    self.data.broken = true
    logger:trace("UnfiredPottery:breakPottery() called - pottery has broken")

    local recipe = self:getRecipe()
    local shouldNotifyPlayer = self:shouldNotifyPlayer()
    PotteryBreaking.breakPottery(self.reference, recipe, shouldNotifyPlayer)
end

---Set decals on ref activated
function UnfiredPottery:setDecals()
    if not self.reference then
        logger:warn("UnfiredPottery:setDecals() called but no reference present")
        return
    end
    PotteryBreaking.setDecals(self.reference, self.data)
end


---Complete the firing process, replacing unfired item with fired item
---@param heatSource tes3reference|nil
---@param completionOffsetHours number|nil -- hours since start of current catch-up gap (used to advance heat-source snapshot)
function UnfiredPottery:completeFiring(heatSource, completionOffsetHours)
    if not self.reference then
        logger:warn("UnfiredPottery:completeFiring() called but no reference present")
        return
    end
    logger:trace("UnfiredPottery:completeFiring() called - pottery successfully fired")
    local recipe = self:getRecipe()
    local firedItem = recipe:getFiredItem()
    logger:debug("Creating fired item: %s", firedItem)

    local wasCracked = self.data.cracked
    local wasTempered
    do
        local tempered = Temper:new{
            item = self.item,
            itemData = self.dataHolder,
            reference = self.reference,
        }
        wasTempered = tempered and tempered:hasTemper() or false
    end
    local heatData
    do
        local heated = self:getHeatedItem()
        heatData = heated and heated:getHeatData() or nil
    end
    local position = self.reference.position:copy()
    local orientation = self.reference.orientation:copy()
    local cell = self.reference.cell

    self.reference:delete()

    local newRef = tes3.createReference{
        object = firedItem,
        position = position,
        orientation = orientation,
        cell = cell,
    }

    if newRef then
        local firedPottery = FiredPottery:new{ reference = newRef }
        if firedPottery then
            -- Carry over craftsmanship inputs for later break calculations.
            firedPottery.data.quality = self.data.quality
            firedPottery.data.tempered = wasTempered

            -- Transfer heat state so fired items retain temperature + glow.
            if heatData then
                local firedHeated = firedPottery:getHeatedItem()
                if firedHeated then
                    -- If we completed mid-gap, advance the heat-source snapshot so the fired pot
                    -- continues from the correct in-gap kiln fuel state.
                    if completionOffsetHours and heatData.lastHeatSourceSnapshot then
                        heatData.lastHeatSourceSnapshot = HeatCurve.advanceSnapshot(
                            heatData.lastHeatSourceSnapshot,
                            completionOffsetHours
                        )
                    end

                    firedHeated:setHeatData(heatData)
                    firedHeated:attachGlow()
                    firedPottery:updateGlow()
                end
            end

            if wasCracked then
                firedPottery.data.cracked = true
                logger:debug("Set cracked flag on fired pottery")
            end

            firedPottery:setDecals()

            -- Catch up remaining heat/cooldown for the rest of the time gap.
            -- This is important when the player waited a long time and the pot finished firing
            -- during that wait; otherwise the fired pot could remain "hot" indefinitely.
            firedPottery:updateHeat(heatSource)

        end
    end

    if self:shouldNotifyPlayer() then
        tes3.playSound{
            soundPath = "ashfall/clayclink.wav",
        }
    end
    common.skills.pottery:exercise(recipe.difficulty * (wasCracked and 0.5 or 1.0))
end

---Get the recipe for this pottery item
---@return Ashfall.PotteryRecipe
function UnfiredPottery:getRecipe()
    logger:trace("UnfiredPottery:getRecipe() called for item: %s", self.item.id)
    local recipe = PotteryRecipe.getRecipeByRawItemId(self.item.id)
    logger:trace("Recipe found: %s", recipe and recipe.id or "nil")
    return recipe
end

---Calculate the number of hours required to fire this item
---@return number
function UnfiredPottery:getFiringTimeHours()
    logger:trace("UnfiredPottery:getFiringTimeHours() called")
    local recipe = self:getRecipe()
    local firingTime = math.remap(recipe.clayAmount, 1, 2, self.MIN_FIRING_HOURS, self.MAX_FIRING_HOURS)
    logger:trace("Firing time calculated: %s hours (clay amount: %s)", firingTime, recipe.clayAmount)
    return firingTime
end

---Calculate the current firing progress based on
---firing time remaining
---@return number
function UnfiredPottery:getFiringProgress()
    logger:trace("UnfiredPottery:getFiringProgress() called")
    local totalFiringTime = self:getFiringTimeHours()
    local hoursRemaining = self.data.firingHoursRemaining or totalFiringTime
    local progress = (totalFiringTime - hoursRemaining) / totalFiringTime
    local clampedProgress = math.clamp(progress, 0, 1)
    logger:trace("Firing progress: %.2f%% (remaining: %s / total: %s hours)", clampedProgress * 100, hoursRemaining, totalFiringTime)
    return clampedProgress
end

---Get the temperature state and color based on current temperature
---@return string|nil stateName The state description, or nil if no heat
---@return number[]|nil color The RGB color
function UnfiredPottery:getTemperatureState()
    local heated = self:getHeatedItem()
    local currentTemp = heated and (heated.data.currentTemperature or 0) or 0
    local targetHeat = heated and (heated.data.targetHeat or 0) or 0
    local isWarming = currentTemp < targetHeat

    -- No tooltip if completely cold
    if currentTemp <= 0 then
        return nil, nil
    end

    -- Find matching stage from config table
    local stageName = "Heating Up"
    local color = {1.0, 0.8, 0.4}

    for _, stage in ipairs(self.COLOR_STAGES) do
        if currentTemp >= stage.minTemp then
            stageName = stage.name
            color = stage.color
            break
        end
    end

    -- Override with "Cooling Down" if below firing temp and cooling
    if currentTemp < Campfire.STAGES.firing.minTemp and not isWarming and currentTemp > 0 then
        stageName = "Cooling Down"
        color = {0.5, 0.7, 1.0}
    end

    return stageName, color
end

---Get the break risk level for display
---@return string|nil riskName The risk level name, or nil if no risk
---@return number[]|nil color The RGB color for the risk level
function UnfiredPottery:getRiskLabelAndColor()
    local breakChance = self:calculateDamageChance()

    if breakChance <= 0 then
        return nil, nil
    end

    -- Find matching risk level from config
    for _, level in ipairs(self.BREAK_RISK_LEVELS) do
        if breakChance >= level.threshold then
            return level.name, level.color
        end
    end

    -- No displayable risk
    return nil, nil
end

---Return tooltip text for this unfired pottery item
function UnfiredPottery:getTooltips()
    local labels = {}

    if not self.data.broken then

        -- Firing progress
        local progress = self:getFiringProgress()
        if progress > 0 then
            table.insert(labels, {text = string.format("Firing Progress: %.1f%%", progress * 100), color = nil})
        end

        -- Cracked status
        if self.data.cracked then
            table.insert(labels, {text = "Cracked!", color = {1.0, 0.5, 0.0}})
        end

        -- Crack/Break risk (if any)
        local riskName, riskColor = self:getRiskLabelAndColor()
        if riskName then
            local riskLabel = self.data.cracked and "Break Risk" or "Crack Risk"
            table.insert(labels, {text = string.format("%s: %s", riskLabel, riskName), color = riskColor})
        end

        if self.reference then
            -- Temperature state (only if has temperature)
            local stateName, stateColor = self:getTemperatureState()
            if stateName then
                table.insert(labels, {text = stateName, color = stateColor})
            end
        end

        -- Quality
        local qualityPercent = (self.data.quality or 0.0) * 100
        table.insert(labels, string.format("Quality: %d", qualityPercent))


        -- --Temperature TODO: remove
        -- local currentTemp = self.data.currentTemperature or 0
        -- table.insert(labels, string.format("Temperature: %.1f", currentTemp))
    end

    return labels
end

---Calculate pot quality from temper and player survival skill
function UnfiredPottery:calculateQuality()
    local survivalSkill = common.skills.survival.current
    local skillBonus = math.remap(survivalSkill, 0, 100, 0.0, 0.5)
    local finalQuality = math.clamp(skillBonus, 0.0, 1.0)
    logger:trace("Calculated pottery quality: %.2f (survivalSkill: %s)", finalQuality, survivalSkill)
    return finalQuality
end

---Create an unfired pottery Item with a provided temper
---@param e { objectId: string, tempered: boolean, position: tes3vector3, orientation: tes3vector3, cell: tes3cell }
---@return Ashfall.UnfiredPottery?
function UnfiredPottery.createPotteryRef(e)
    local reference = tes3.createReference{
        object = e.objectId,
        position = e.position,
        orientation = e.orientation,
        cell = e.cell,
    }
    local pottery = UnfiredPottery:new{ reference = reference }
    if not pottery then
        logger:error("Failed to create unfired pottery for objectId: %s", e.objectId)
        return nil
    end

    pottery.data.quality = pottery:calculateQuality()

    -- Apply temper if provided
    if e.tempered then
        local tempered = Temper:new{ reference = pottery.reference }
        if tempered then
            tempered:addTemper()
        end
    end

    return pottery
end


---Returns true if item is an unfired pottery item
---@return boolean
function UnfiredPottery.isUnfiredItem(item)
    logger:trace("UnfiredPottery.isUnfiredItem() called for item: %s", item and item.id or "nil")
    local potteryRecipe = PotteryRecipe.getRecipeByRawItemId(item.id)
    return potteryRecipe and potteryRecipe.firedItemId ~= nil
end

---If pottery, add firing info to tooltip
---@param e uiObjectTooltipEventData
function UnfiredPottery.onUiObjectTooltip(e)
    if not UnfiredPottery.isUnfiredItem(e.object) then
        return
    end
    local pottery = UnfiredPottery:new{ item = e.object, itemData = e.itemData, reference = e.reference }
    if pottery then
        local labels = pottery:getTooltips()
        for _, label in ipairs(labels) do
            if type(label) == "table" then
                common.helper.addLabelToTooltip(e.tooltip, label.text, label.color)
            else
                common.helper.addLabelToTooltip(e.tooltip, label)
            end
        end
    end
end

---Handle activation of unfired or broken pottery
---@param e activateEventData
function UnfiredPottery.onActivate(e)
    --If broken, add "broken clay" item to inventory and delete
    local result = PotteryBreaking.onActivateBroken(e)
    if result == false then
        return false
    end

    if UnfiredPottery.isUnfiredItem(e.target.baseObject) then
        local pottery = UnfiredPottery:new{ reference = e.target }
        if pottery then
            local heated = pottery:getHeatedItem()
            local currentTemp = heated and (heated.data.currentTemperature or 0) or 0
            local safeTemp = PotteryDamage.getSafePickupTemperature(Campfire.STAGES.firing.minTemp)
            if currentTemp > safeTemp then
                tes3.messageBox("It is too hot to pick up.")
                return false
            end
        end
    end
end

function UnfiredPottery.resetAnimationTime(root)
    local now = tes3.getSimulationTimestamp(false)
    for node in table.traverse{root} do
        if node.controller then
            logger:debug("Resetting controller for %s", node.name)
            node.controller.phase = -now + 1.667
        end
    end
end



return UnfiredPottery