local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("HeatUtil")
local HeatUtil = {}

--[[
    Get heat based on fuel level and modifiers
]]
function HeatUtil.getHeat(reference)
    local data = reference.data
    local bellowsEffect = 1.0
    local bellowsId = data.bellowsId and data.bellowsId:lower()
    local bellowsData = common.staticConfigs.bellows[bellowsId]
    if bellowsData then
        bellowsEffect = bellowsData.heatEffect
    end
    local isLit = data.isLit
    local fuelLevel = data.fuelLevel or 0
    local isWeak = common.staticConfigs.activatorConfig.list.teaWarmer:isActivator(reference)
    local weakEffect = isWeak and 0.1 or 1.0

    if (not isLit) or (fuelLevel <= 0) then
        return 0
    else
        local isColdEffect = data.hasColdFlame and -1 or 1
        local finalHeat = (fuelLevel * bellowsEffect * weakEffect * isColdEffect)
        return finalHeat
    end
end

---Updates the heat of a liquid container, triggering any node updates and sounds if necessary
---@param refData table
---@param newHeat number
---@param reference tes3reference?
function HeatUtil.setHeat(refData, newHeat, reference)
    logger:trace("Setting heat of %s to %s", reference or "[unknown]", newHeat)
    local heatBefore = refData.waterHeat or 0
    refData.waterHeat = math.clamp(newHeat, 0, 100.9)
    local heatAfter = refData.waterHeat
    --add sound if crossing the boiling barrior
    if reference and not reference.disabled then
        if heatBefore < common.staticConfigs.hotWaterHeatValue and heatAfter > common.staticConfigs.hotWaterHeatValue then
            event.trigger("Ashfall:UpdateAttachNodes", { reference = reference})
        end
        --remove boiling sound
        if heatBefore > common.staticConfigs.hotWaterHeatValue and heatAfter < common.staticConfigs.hotWaterHeatValue then
            logger:debug("No longer hot")
            event.trigger("Ashfall:UpdateAttachNodes", { reference = reference})
        end
    end
    if refData.waterHeat == 0 then
        refData.waterHeat = nil
    end
end


local minFuelWaterHeat = 5--min fuel multiplier on water heating
local maxFuelWaterHeat = 10--max fuel multiplier on water heating

---@param liquidContainer Ashfall.LiquidContainer
---@return number heatEffect
local function calculateHeatEffect(liquidContainer)
    local oldHeat = liquidContainer.waterHeat
    local heatEffect = -1--negative if cooling down
        --TODO: Implement heatLossMultiplier based on waterContainer data
    --
    local isNegativeHeat
    logger:trace("Water heat: %s", oldHeat)
    --Check heat sources for reference
    if liquidContainer.reference then
        local ref = liquidContainer.reference
        if ref.data.isLit then--based on fuel if heating up
            local heat = HeatUtil.getHeat(liquidContainer.reference)
            isNegativeHeat = heat < 0
            heat = math.abs(heat)
            heatEffect = math.remap(heat, 0, common.staticConfigs.maxWoodInFire, minFuelWaterHeat, maxFuelWaterHeat)

            logger:trace("BOILER heatEffect: %s", heatEffect)
        else
            logger:trace("Looking for heat source underneath. Strong heat only heats utensils, weak heat doesn't work on pots")
            local heater, heatType = common.helper.getHeatFromBelow(liquidContainer.reference)
            local heaterIsLit = heater and heater.data.isLit
            if heaterIsLit then
                local isUtensil = common.staticConfigs.utensils[ref.object.id:lower()]
                local isCookingPot = common.staticConfigs.cookingPots[ref.object.id:lower()]
                local doStrongHeat = isUtensil and heatType == "strong"
                local doWeakHeat = (not isCookingPot) and heatType == "weak"
                if doStrongHeat then
                    local heat = HeatUtil.getHeat(heater)
                    isNegativeHeat = heat < 0
                    heat = math.abs(heat)
                    heatEffect = math.remap(heat, 0, common.staticConfigs.maxWoodInFire, minFuelWaterHeat, maxFuelWaterHeat)
                elseif doWeakHeat then
                    --Weak flames greatly reduce the rate of heat loss
                    --but not for cooking pots
                    heatEffect = -0.01
                end
            end
        end
    end
    if isNegativeHeat then
        heatEffect = -heatEffect
    end
    return heatEffect
end


local HEAT_LOSS_EMPTY = 2.5
local HEAT_LOSS_FULL = 1.0
local WATER_HEAT_RATE = 40--base water heat/cooling speed
---@param liquidContainer Ashfall.LiquidContainer
function HeatUtil.updateWaterHeat(liquidContainer)
    if liquidContainer.waterAmount == 0 then return end
    local now = tes3.getSimulationTimestamp()
    liquidContainer.lastWaterUpdated = liquidContainer.lastWaterUpdated or now
    local timeSinceLastUpdate = now - liquidContainer.lastWaterUpdated
    liquidContainer.lastWaterUpdated = now
    liquidContainer.waterHeat = liquidContainer.waterHeat or 0
    --Heats up or cools down depending on fuel/is lit
    local heatEffect = calculateHeatEffect(liquidContainer)

    --Amount of water determines how quickly it boils
    --We use a hardcoded value instead of capacity because it doesn't make sense to heat up slower when the container is smaller
    local filledAmount = math.min(liquidContainer.waterAmount / 100, 1)
    logger:trace("BOILER filledAmount: %s", filledAmount)
    local filledAmountEffect = math.remap(filledAmount, 0.0, 1.0, HEAT_LOSS_EMPTY, HEAT_LOSS_FULL)
    logger:trace("BOILER filledAmountEffect: %s", filledAmountEffect)

    --Calculate change
    local heatChange = timeSinceLastUpdate * heatEffect * filledAmountEffect * WATER_HEAT_RATE
    local newHeat = math.max(0, liquidContainer.waterHeat + heatChange)
    HeatUtil.setHeat(liquidContainer.data, newHeat, liquidContainer.reference)
end

return HeatUtil