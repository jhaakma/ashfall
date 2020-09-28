--[[
    --Handles the heating and cooling of objects that can boil water
]]
local common = require ("mer.ashfall.common.common")

local waterHeatRate = 40--base water heat/cooling speed
local updateInterval = 0.001
local minFuelWaterHeat = 5--min fuel multiplier on water heating
local maxFuelWaterHeat = 10--max fuel multiplier on water heating

local maxSpeedForCapacity = 10.0

local function updateBoilers(e)
    
    local function doUpdate(boilerRef)
        common.log:trace("BOILER updating %s", boilerRef.object.id)
        boilerRef.data.lastWaterUpdated = boilerRef.data.lastWaterUpdated or e.timestamp
        local timeSinceLastUpdate = e.timestamp - boilerRef.data.lastWaterUpdated
        common.log:trace("BOILER timeSinceLastUpdate %s", timeSinceLastUpdate)
        if timeSinceLastUpdate > updateInterval then
            common.log:trace("BOILER interval passed, updating heat")
            local hasFilledPot = (
                boilerRef.data.waterAmount and
                boilerRef.data.waterAmount > 0
            )
            if hasFilledPot then
                common.log:trace("BOILER hasFilledPot")
                boilerRef.data.waterHeat = boilerRef.data.waterHeat or 0
                boilerRef.data.lastWaterUpdated = e.timestamp

                --Heats up or cools down depending on fuel/is lit
                local heatEffect = -1--negative if cooling down
                if boilerRef.data.isLit then--based on fuel if heating up
                    heatEffect = math.remap(boilerRef.data.fuelLevel, 0, common.staticConfigs.maxWoodInFire, minFuelWaterHeat, maxFuelWaterHeat)
                    common.log:trace("BOILER heatEffect: %s", heatEffect)
                end

                --Amount of water determines how quickly it boils
                local filledAmount = boilerRef.data.waterAmount / common.staticConfigs.capacities[boilerRef.data.utensil]
                common.log:trace("BOILER filledAmount: %s", filledAmount)
                local filledAmountEffect = math.remap(filledAmount, 0.0, 1.0, maxSpeedForCapacity, 1.0)
                common.log:trace("BOILER filledAmountEffect: %s", filledAmountEffect)

                --Calculate change
                local heatChange = timeSinceLastUpdate * heatEffect * filledAmountEffect * waterHeatRate
                common.log:trace("BOILER heatChange: %s", heatChange)

                local heatBefore = boilerRef.data.waterHeat
                boilerRef.data.waterHeat = math.clamp((boilerRef.data.waterHeat + heatChange), 0, 100)
                local heatAfter = boilerRef.data.waterHeat
                
                common.log:trace("BOILER heatAfter: %s", heatAfter)

                --add sound if crossing the boiling barrior
                if heatBefore < common.staticConfigs.hotWaterHeatValue and heatAfter > common.staticConfigs.hotWaterHeatValue then
                    tes3.playSound{
                        reference = boilerRef, 
                        sound = "ashfall_boil"
                    }
                end
                --remove boiling sound
                if heatBefore > common.staticConfigs.hotWaterHeatValue and heatAfter < common.staticConfigs.hotWaterHeatValue then
                    tes3.removeSound{
                        reference = boilerRef, 
                        sound = "ashfall_boil"
                    }
                end

                if boilerRef.data.waterHeat > common.staticConfigs.hotWaterHeatValue then
                    --boil dirty water away
                    if boilerRef.data.waterType == "dirty" then
                        boilerRef.data.waterType = nil
                    end
                end
            else
                common.log:trace("BOILER no filled pot, setting waterUpdated to nil")
                boilerRef.data.lastWaterUpdated = nil
            end
        end
    end
    common.helper.iterateRefType("boiler", doUpdate) 
end

 event.register("simulate", updateBoilers)
