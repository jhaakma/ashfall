local common = require("mer.ashfall.common.common")
local logger = common.createLogger("FiredPottery")
local ItemInstance = require("CraftingFramework.carryableContainers.components.ItemInstance")
local PotteryRecipe = require("mer.ashfall.clay.PotteryRecipe")
local PotteryBreaking = require("mer.ashfall.clay.PotteryBreaking")
local Campfire = require("mer.ashfall.camping.campfire.Campfire")
local HeatedItem = require("mer.ashfall.clay.HeatedItem")
local PotteryDamage = require("mer.ashfall.clay.PotteryDamage")
local HeatUtil = require("mer.ashfall.heat.HeatUtil")
local HeatCurve = require("mer.ashfall.heat.HeatCurve")

-- While a heat source is present, do not apply thermal shock for gradual
-- cooldown (fuel consumption). Only consider thermal shock if the heat source
-- temperature drops abruptly to near-ambient (e.g. doused/extinguished).
local THERMAL_SHOCK_MIN_ABRUPT_TARGET_DROP_FACTOR = 0.80
local THERMAL_SHOCK_MAX_TARGET_AFTER_ABRUPT_DROP_FACTOR = 0.05

---Class for managing instances of fired pottery items
---@class Ashfall.FiredPottery : ItemInstance
---@field data Ashfall.FiredPotteryData
local FiredPottery = {
    ---The rate at which temperature changes per hour (degrees per hour)
    TEMP_CHANGE_RATE = 5,
}

---@class Ashfall.FiredPotteryData
---@field cracked boolean? Whether the pottery is cracked
---@field quality number? (optional) Copied from unfired pottery on successful firing.
---@field tempered boolean? (optional) Copied from unfired pottery on successful firing.

---Construct from reference
---@param e ItemInstance.new.params
---@return Ashfall.FiredPottery?
function FiredPottery:new(e)
    if e.reference and not e.reference.supportsLuaData then return end

    local item = e.item or e.reference.baseObject

    logger:trace("FiredPottery:new() called for reference: %s", item.id)
    if not FiredPottery.isFiredItem(item) then
        logger:error("Attempted to create FiredPottery from non-fired item: " .. item.id)
        return nil
    end
    local firedPottery = ItemInstance:new{
        item = item,
        itemData = e.itemData,
        reference = e.reference,
        dataKey = "Ashfall_FiredPottery",
    }
    setmetatable(firedPottery, self)
    self.__index = self
    return firedPottery --[[@as Ashfall.FiredPottery]]
end

---Get the shared heated-item state for this pottery.
---@return Ashfall.Clay.HeatedItem?
function FiredPottery:getHeatedItem()
    return HeatedItem:new{
        item = self.item,
        itemData = self.dataHolder,
        reference = self.reference,
        tempChangeRate = self.TEMP_CHANGE_RATE,
    }
end

---@param heated Ashfall.Clay.HeatedItem
---@return Ashfall.Clay.HeatedItem.UpdateOptions
function FiredPottery:getHeatUpdateOptions(heated)
    return {
        onHeatUpdated = function(h)
            h:updateGlow()
        end
    }
end

---Updates the diffuse material color from white to red based on temperature
function FiredPottery:updateGlow()
    logger:trace("FiredPottery:updateGlow() called")
    if not self.reference then
        logger:warn("FiredPottery:updateGlow() called but no reference present")
        return
    end
    local heated = self:getHeatedItem()
    if heated then
        heated:updateGlow()
    end
end

---Reset the last temperature update to nil
function FiredPottery:resetLastTemperatureUpdate()
    logger:trace("FiredPottery:resetLastTemperatureUpdate() called")
    local heated = self:getHeatedItem()
    if heated then
        heated:resetLastTemperatureUpdate()
    end
end

---Calculate what the new temperature would be given a target temperature
---@param targetTemperature number
---@return number
function FiredPottery:calculateNewTemperature(targetTemperature)
    local heated = self:getHeatedItem()
    if not heated then
        return 0
    end
    return heated:calculateNewTemperature(targetTemperature)
end

---Set the temperature of the pottery item
---@param newTemperature number
function FiredPottery:setTemperature(newTemperature)
    local heated = self:getHeatedItem()
    if heated then
        heated:setTemperature(newTemperature)
    end
end

---Update temperature (and glow) based on an optional nearby heat source
---@param heatSource tes3reference|nil
function FiredPottery:updateHeat(heatSource)
    logger:trace("FiredPottery:updateHeat() called")
    local heated = self:getHeatedItem()
    if not heated then
        return
    end

    local now = tes3.getSimulationTimestamp()
    local lastUpdate = heated.data.lastTemperatureUpdate or now
    local hoursElapsed = now - lastUpdate
    if hoursElapsed < 0 then
        hoursElapsed = 0
    end

    local recipe = (self.reference and self.reference.baseObject)
        and PotteryRecipe.getRecipeByFiredItemId(self.reference.baseObject.id)
        or nil
    local resistance = recipe and recipe.breakResistance or 0.0

    local updateOptions = self:getHeatUpdateOptions(heated)

    -- Build a target-heat function for this time gap.
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

    local previousTargetHeat = heated.data.targetHeat or 0

    heated:advance(hoursElapsed, {
        stepHours = 0.25,
        targetHeatAt = targetHeatAt,
        updateOptions = updateOptions,
        startTimestamp = lastUpdate,
        onStep = function(_, e)
            if not self.reference then
                return false
            end

            local hadHeatSourceNow = heatSource ~= nil

            -- If a heat source is present, only allow thermal shock for an abrupt extinguish.
            if hadHeatSourceNow then
                local minTemp = Campfire.STAGES.firing.minTemp
                local targetDrop = previousTargetHeat - (e.targetHeat or 0)
                local minDrop = minTemp * THERMAL_SHOCK_MIN_ABRUPT_TARGET_DROP_FACTOR
                local maxTargetAfter = minTemp * THERMAL_SHOCK_MAX_TARGET_AFTER_ABRUPT_DROP_FACTOR

                local isAbruptExtinguish = targetDrop >= minDrop and (e.targetHeat or 0) <= maxTargetAfter
                previousTargetHeat = (e.targetHeat or 0)

                if not isAbruptExtinguish then
                    return true
                end
            else
                previousTargetHeat = (e.targetHeat or 0)
            end

            local ratePerHour = PotteryDamage.calculateThermalShockRatePerHour{
                currentTemperature = e.oldTemperature,
                targetTemperature = e.targetHeat,
                firingMinTemp = Campfire.STAGES.firing.minTemp,
                breakResistance = resistance,
                quality = self.data.quality,
                tempered = self.data.tempered,
            }

            local triggered = PotteryDamage.rollRateOverHours(e.dtHours, ratePerHour)

            logger:trace(
                "Thermal shock cooling roll: dt=%.6fh old=%.2f target=%.2f new=%.2f rate/h=%.4f triggered=%s cracked=%s",
                e.dtHours,
                e.oldTemperature,
                e.targetHeat,
                e.newTemperature,
                ratePerHour,
                tostring(triggered),
                tostring(self.data.cracked)
            )

            if triggered then
                PotteryDamage.applyCrackOrBreak{
                    reference = self.reference,
                    data = self.data,
                    recipe = recipe,
                    shouldNotifyPlayer = true,
                }
                return false
            end

            return true
        end,
    })

    if not self.reference then
        return
    end

    -- Persist heat-source presence/snapshot for the next update.
    heated.data.lastHadHeatSource = heatSource ~= nil
    heated.data.lastHeatSourceSnapshot = heatSource and HeatCurve.snapshotFuelConsumer(heatSource) or nil
end

---Set decals on ref activated
function FiredPottery:setDecals()
    if not self.reference then
        logger:warn("FiredPottery:setDecals() called but no reference present")
        return
    end
    PotteryBreaking.setDecals(self.reference, self.data)
end

---Returns true if item is a fired pottery item
---@param item tes3item
---@return boolean
function FiredPottery.isFiredItem(item)
    logger:trace("FiredPottery.isFiredItem() called for item: %s", item and item.id or "nil")
    local isFired = PotteryRecipe.isFiredPotteryItem(item)
    logger:trace("Is fired pottery: %s", isFired)
    return isFired
end

---If pottery, add cracked status to tooltip
---@param e uiObjectTooltipEventData
function FiredPottery.onUiObjectTooltip(e)
    if not FiredPottery.isFiredItem(e.object) then
        return
    end
    local pottery = FiredPottery:new{ item = e.object, itemData = e.itemData, reference = e.reference }
    if pottery and pottery.data.cracked then
        common.helper.addLabelToTooltip(e.tooltip, "Cracked", {1.0, 0.5, 0.0})
    end
end

---Handle activation of fired pottery.
---Picking up is either blocked (too hot) or safe.
---@param e activateEventData
---@return boolean|nil False to block activation
function FiredPottery.onActivate(e)
    if not e.target or not e.target.baseObject then
        return
    end

    if not FiredPottery.isFiredItem(e.target.baseObject) then
        return
    end

    local pottery = FiredPottery:new{ reference = e.target }
    if not pottery then
        return
    end

    -- Always catch up heat state before deciding if it's safe to pick up.
    -- Time can jump massively (wait/rest) and the periodic controller may not
    -- have ticked yet on the same frame as activation.
    local heatSource = common.helper.getHeatFromBelow(e.target, "strong")
    pottery:updateHeat(heatSource)

    local heated = pottery:getHeatedItem()
    if not heated then
        return
    end

    local currentTemp = heated.data.currentTemperature or 0
    local safeTemp = PotteryDamage.getSafePickupTemperature(Campfire.STAGES.firing.minTemp)
    if currentTemp > safeTemp then
        tes3.messageBox("It is too hot to pick up.")
        return false
    end
end

return FiredPottery
