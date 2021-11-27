--[[
    Iterates over Fuel Consumers and updates their fuel level
]]

local common = require ("mer.ashfall.common.common")

local fuelDecay = 1.0
local fuelDecayRainEffect = 1.4
local fuelDecayThunderEffect = 1.6
local FUEL_UPDATE_INTERVAL = 0.001

local function updateFuelConsumers(e)
    local function doUpdate(fuelConsumer)
        fuelConsumer.data.lastFuelUpdated = fuelConsumer.data.lastFuelUpdated or e.timestamp
        local difference = e.timestamp - fuelConsumer.data.lastFuelUpdated

        if difference < 0 then
            common.log:error("FUELCONSUMER fuelConsumer.data.lastFuelUpdated(%.4f) is ahead of e.timestamp(%.4f).",
                fuelConsumer.data.lastFuelUpdated, e.timestamp)
            --something fucky happened
            fuelConsumer.data.lastFuelUpdated = e.timestamp
        end

        if difference > FUEL_UPDATE_INTERVAL then
            fuelConsumer.data.lastFuelUpdated = e.timestamp
            if fuelConsumer.data.isLit then
                local bellowsEffect = 1.0
                local bellowsId = fuelConsumer.data.bellowsId and fuelConsumer.data.bellowsId:lower()
                local bellowsData = common.staticConfigs.bellows[bellowsId]
                if bellowsData then
                    bellowsEffect = bellowsData.burnRateEffect
                end

                local rainEffect = 1.0
                if not common.helper.checkRefSheltered(fuelConsumer) then
                    --raining and fuelConsumer exposed
                    if tes3.getCurrentWeather().index == tes3.weather.rain then
                        rainEffect = fuelDecayRainEffect
                    --thunder and fuelConsumer exposed
                    elseif tes3.getCurrentWeather().index == tes3.weather.thunder then
                        rainEffect = fuelDecayThunderEffect
                    end
                end

                fuelConsumer.data.fuelLevel = fuelConsumer.data.fuelLevel - ( difference * fuelDecay * rainEffect * bellowsEffect )

                --static campfires never go out
                local isInfinite = fuelConsumer.data.infinite
                    or (fuelConsumer.data.dynamicConfig
                        and fuelConsumer.data.dynamicConfig.campfire.static
                    )
                if isInfinite then
                    fuelConsumer.data.fuelLevel = math.max(fuelConsumer.data.fuelLevel, 1)
                end

                if fuelConsumer.data.fuelLevel <= 0 then
                    fuelConsumer.data.fuelLevel = 0
                    local playSound = difference < 0.01
                    event.trigger("Ashfall:fuelConsumer_Extinguish", {fuelConsumer = fuelConsumer, playSound = playSound})
                end
            else
                fuelConsumer.data.lastFuelUpdated = nil
            end
        end
    end
    common.helper.iterateRefType("fuelConsumer", doUpdate)
end

 event.register("simulate", updateFuelConsumers)