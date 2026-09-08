local common = require("mer.ashfall.common.common")
local logger = common.createLogger("FiredPottery")
local ItemInstance = require("CraftingFramework.carryableContainers.components.ItemInstance")
local PotteryRecipe = require("mer.ashfall.clay.PotteryRecipe")
local PotteryBreaking = require("mer.ashfall.clay.PotteryBreaking")
local PotteryDecals = require("mer.ashfall.clay.Visuals.PotteryDecals")
local Decoration = require("mer.ashfall.clay.Decoration.Decoration")
local Campfire = require("mer.ashfall.camping.campfire.Campfire")
local HeatedItem = require("mer.ashfall.clay.HeatedItem")
local PotteryDamage = require("mer.ashfall.clay.PotteryDamage")
local HeatUtil = require("mer.ashfall.heat.HeatUtil")
local HeatCurve = require("mer.ashfall.heat.HeatCurve")
local PotteryTooltips = require("mer.ashfall.clay.PotteryTooltips")
local LiquidContainer = require("mer.ashfall.liquid.LiquidContainer")

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
---@field decorationId string? (optional) The ID of the decoration applied to this pottery.

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

---clear data table if all values are nil or false, to allow inventory stacking
function FiredPottery:clearDataIfEmpty()
    if self.data and (
        self.data.cracked or
        self.data.quality or
        self.data.tempered or
        self.data.decorationId
    ) then
        return
    end
    logger:trace("Clearing empty data table for %s", self.item.id)
    self.dataHolder.data.Ashfall_FiredPottery = nil
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
            h:updateVisuals()
        end
    } --[[@as Ashfall.Clay.HeatedItem.UpdateOptions]]
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
        heated:updateVisuals()
    end
end

---Update decoration visuals on the pottery reference
function FiredPottery:updateDecorationVisuals()
    logger:trace("FiredPottery:updateDecorationVisuals() called")
    if not self.reference then
        logger:warn("FiredPottery:updateDecorationVisuals() called but no reference present")
        return
    end

    if not self.data.decorationId then
        logger:trace("No decoration applied to pottery")
        return
    end

    local decoration = Decoration.getDecoration(self.data.decorationId)
    if not decoration then
        logger:warn("Decoration not found: %s", self.data.decorationId)
        return
    end

    local sceneNode = self.reference.sceneNode
    if not sceneNode then
        logger:warn("Scene node not found for reference")
        return
    end

    logger:debug("Applying fired decoration %s to fired pottery", decoration.id)
    decoration:applyFired(sceneNode)
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

function FiredPottery:hasDecoration()
    return self.data.decorationId ~= nil
end

---Return tooltip labels for this fired pottery item.
---@return (string|{text: string, color: number[]?})[]
function FiredPottery:getTooltips()
    local labels = {}

    local crackedLabel = PotteryTooltips.getCrackedLabel(self.data.cracked, "Cracked")
    if crackedLabel then
        table.insert(labels, crackedLabel)
    end

    local qualityLabel = PotteryTooltips.getQualityLabel(self.data.quality, { includeWhenNil = false })
    if qualityLabel then
        table.insert(labels, qualityLabel)
    end

    --Decoration
    if self:hasDecoration() then
        local decoration = Decoration.getDecoration(self.data.decorationId)
        if decoration then
            table.insert(labels, PotteryTooltips.getDecorationLabel(decoration))
        end
    end

    return labels
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
            logger:trace(
                "FiredPottery heat step: dt=%.3fh oldTemp=%.2f targetHeat=%.2f newTemp=%.2f",
                e.dtHours,
                e.oldTemperature,
                e.targetHeat or 0,
                e.newTemperature
            )



            -- Check if pottery has reached firing temperature and contains liquid
            if e.newTemperature >= Campfire.STAGES.firing.minTemp then
                logger:trace("Boil check: Pottery reached firing temperature: %.2f", e.newTemperature)
                local liquidContainer = LiquidContainer.createFromReference(self.reference)
                if liquidContainer and liquidContainer:hasWater() then
                    logger:debug("Boiling away liquid from pottery at firing temperature (%.2f)", e.newTemperature)
                    liquidContainer:empty()
                    tes3.messageBox("The liquid in the %s boils away completely.", self.reference.baseObject.name or "pottery")
                else
                    logger:trace("Boil check: No liquid to boil away.")
                end
            end

            local hadHeatSourceNow = heatSource ~= nil and heatSource.data.isLit

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
                    decals = self:getDecals(),
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
    heated.data.lastHadHeatSource = heatSource and true or nil
    heated.data.lastHeatSourceSnapshot = heatSource and HeatCurve.snapshotFuelConsumer(heatSource) or nil

    heated:clearDataIfEmpty()
end

---Update heat/glow for fired items that should not retain FiredPottery data.
---Uses HeatedItem only and skips damage/decoration mechanics.
---@param reference tes3reference
---@param heatSource tes3reference|nil
function FiredPottery.updateHeatSimple(reference, heatSource)
    if not reference or not reference.supportsLuaData then
        return
    end

    local heated = HeatedItem:new{
        reference = reference,
        tempChangeRate = FiredPottery.TEMP_CHANGE_RATE,
    }
    if not heated then
        return
    end

    local now = tes3.getSimulationTimestamp()
    local lastUpdate = heated.data.lastTemperatureUpdate or now
    local hoursElapsed = now - lastUpdate
    if hoursElapsed < 0 then
        hoursElapsed = 0
    end

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
        updateOptions = {
            onHeatUpdated = function(h)
                h:updateVisuals()
            end,
        },
        startTimestamp = lastUpdate,
    })

    heated.data.lastHadHeatSource = heatSource and true or nil
    heated.data.lastHeatSourceSnapshot = heatSource and HeatCurve.snapshotFuelConsumer(heatSource) or nil
    heated:clearDataIfEmpty()
end

---@return Ashfall.Clay.PotteryDecals[]
function FiredPottery:getDecals()
    local decals = {}
    if self.data.cracked then
        local cracks = PotteryDecals.get("cracks")
        if cracks then
            table.insert(decals, cracks)
        end
    end

    local decoration = self:hasDecoration() and Decoration.getDecoration(self.data.decorationId) or nil
    if decoration then
        local firedDecal = decoration:getFiredDecal()
        if firedDecal then
            table.insert(decals, firedDecal)
        end
    end

    return decals
end

---Set decals on ref activated
function FiredPottery:setDecals()
    if not self.reference then
        logger:warn("FiredPottery:setDecals() called but no reference present")
        return
    end
    PotteryBreaking.setDecals(self.reference, self.data)
    self:updateDecorationVisuals()
end

---Returns true if item is a fired pottery item
---@param item tes3item
---@return boolean
function FiredPottery.isFiredItem(item)
    logger:trace("FiredPottery.isFiredItem() called for item: %s", item and item.id or "nil")
    local isFired = PotteryRecipe.isFiredPotteryItem(item)
    if isFired then
        local recipe = PotteryRecipe.getRecipeByFiredItemId(item.id)
        if recipe and recipe.isBasic then
            isFired = false
        end
    end
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
    if pottery then
        PotteryTooltips.addLabelsToTooltip(e.tooltip, pottery:getTooltips())
    end
end

return FiredPottery
