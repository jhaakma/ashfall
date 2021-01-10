--[[
    Iterates over Fuel Consumers and updates their fuel level
]]

local common = require ("mer.ashfall.common.common")

local fuelDecay = 1.0
local fuelDecayRainEffect = 1.4
local fuelDecayThunderEffect = 1.6
local updateInterval = 0.001

local function updateFuelConsumers(e)
    local function doUpdate(fuelConsumer)
        fuelConsumer.data.lastFuelUpdated = fuelConsumer.data.lastFuelUpdated or e.timestamp
        local difference = e.timestamp - fuelConsumer.data.lastFuelUpdated

        if difference > updateInterval then
            if fuelConsumer.data.isLit then
                fuelConsumer.data.lastFuelUpdated = e.timestamp

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



                fuelConsumer.data.fuelLevel = fuelConsumer.data.fuelLevel - ( difference * fuelDecay * rainEffect )

                --static campfires never go out
                if fuelConsumer.data.dynamicConfig and  fuelConsumer.data.dynamicConfig.campfire == "static" then
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