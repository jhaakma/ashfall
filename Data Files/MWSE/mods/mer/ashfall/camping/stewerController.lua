--[[
    Iterates over objects that  and updates their fuel level
]]
local common = require ("mer.ashfall.common.common")
local foodConfig = common.staticConfigs.foodConfig

local stewCookRate = 40
local updateInterval = 0.001


--Warmth from Stew
local function firstDataLoaded()
    --make sure the value exists first
    common.data.stewWarmEffect = common.data.stewWarmEffect and common.data.stewWarmEffect or 0
    --register stewTemp
    local temperatureController = require("mer.ashfall.temperatureController")
    temperatureController.registerInternalHeatSource("stewWarmEffect")
end
event.register("Ashfall:dataLoadedOnce", firstDataLoaded)


--Update Stew buffs for player and companions
local function updateBuffs(e)
    local function doUpdateBuff(reference)
        if reference.data and reference.data.stewBuffTimeLeft and reference.data.stewBuffTimeLeft > 0 then
            reference.data.lastStewBuffUpdated = reference.data.lastStewBuffUpdated or e.timestamp

            local interval = e.timestamp - reference.data.lastStewBuffUpdated
            reference.data.stewBuffTimeLeft = math.max((reference.data.stewBuffTimeLeft - interval), 0)
            --time's up, remove spells and heat
            if reference.data.stewBuffTimeLeft == 0 then
                common.data.stewWarmEffect = 0 

                common.helper.restoreFatigue()
                for _, stewBuff in pairs(foodConfig.getStewBuffList()) do
                    mwscript.removeSpell({ reference = reference, spell = stewBuff.id})
                end
                tes3.messageBox("Stew effect has worn off.")
                

                reference.data.stewBuffTimeLeft = nil
                reference.data.lastStewBuffUpdated = nil
            else
                reference.data.lastStewBuffUpdated = e.timestamp
            end
        end
    end
    common.helper.iterateRefType("stewBuffedActor", doUpdateBuff)
end

local function updateStewers(e)
    
    local function doUpdate(stewerRef)
        stewerRef.data.lastStewUpdated = stewerRef.data.lastStewUpdated or e.timestamp
        local difference = e.timestamp - stewerRef.data.lastStewUpdated
        
        if difference > updateInterval then
            stewerRef.data.waterHeat = stewerRef.data.waterHeat or 0
            local hasWater = stewerRef.data.waterAmount and stewerRef.data.waterAmount > 0
            local waterIsBoiling = stewerRef.data.waterHeat and stewerRef.data.waterHeat >= common.staticConfigs.hotWaterHeatValue
            local hasStew = stewerRef.data.stewLevels 
            if hasWater and waterIsBoiling and hasStew then
                stewerRef.data.lastStewUpdated = e.timestamp
                --Cook the stew
                stewerRef.data.stewProgress = stewerRef.data.stewProgress or 0
                local waterHeatEffect = common.helper.calculateWaterHeatEffect(stewerRef.data.waterHeat)
                stewerRef.data.stewProgress = math.clamp((stewerRef.data.stewProgress + ( difference * stewCookRate * waterHeatEffect )), 0, 100)
            else
                stewerRef.data.lastStewUpdated = nil
            end
        end
    end
    common.helper.iterateRefType("stewer", doUpdate)
end

 event.register("simulate", function(e)
    updateStewers(e)
    updateBuffs(e)
 end)
