--move to common---------------------------------
--Also... refactor all temps to point to this----
local common = require("mer.ashfall.common.common")
local hud = require("mer.ashfall.ui.hud")
-------------------------------------------------
--Move to Config file
local INT_MULTI = 100 --Rate of change for player temp
local MAX_DIFFERENCE = 40
local MAX_MULTI = 1--Rate of player temp change
-----------------------------------------------


local this = {}
this.externalHeatSources = {}
this.internalHeatSources = {}
this.baseTempMultipliers = {} --flag: coldOnly and warmOnly
this.rateMultipliers = {} --flags: coolingOnly and warmingOnly

function this.registerExternalHeatSource(heatSource)
    if type(heatSource) == "string" then
        heatSource = { id = heatSource }
    end

    if type(heatSource) == "table" and heatSource.id then
        table.insert(this.externalHeatSources, 
            {
                id = heatSource.id,
                coldOnly = heatSource.coldOnly,
                warmOnly = heatSource.warmOnly
            }
        )
    else
        common.log:error("Incorrect formatting of externalHeatSource")
    end
end

function this.registerInternalHeatSource(heatSource)
    if type(heatSource) == "string" then
        heatSource = { id = heatSource }
    end
    if type(heatSource) == "table" and heatSource.id then
        table.insert(this.internalHeatSources, 
            {
                id = heatSource.id,
                coldOnly = heatSource.coldOnly,
                warmOnly = heatSource.warmOnly
            }
        )
    else
        common.log:error("Incorrect formatting of internalHeatSource")

    end
end

function this.registerBaseTempMultiplier(multiplier)
    if type(multiplier) == "string" then
       multiplier = { id = multiplier }
    end
    if type(multiplier) == "table" and multiplier.id then
        table.insert(this.baseTempMultipliers, 
        {
            id = multiplier.id,
            coldOnly = multiplier.coldOnly,
            warmOnly = multiplier.warmOnly
        }
    )
    else
        common.log:error("Incorrect formatting of baseTempMultiplier: %s", multiplier and multiplier.id or multiplier)
    end
end

function this.registerRateMultiplier(multiplier)
    if type(multiplier) == "string" then
        multiplier = { id = multiplier }
     end
     
     if type(multiplier) == "table" and multiplier.id then
         table.insert(this.rateMultipliers, 
         {
             id = multiplier.id,
             coolingOnly = multiplier.coolingOnly,
             warmingOnly = multiplier.warmingOnly
         }
     )
     else
        common.log:error("Incorrect formatting of rateMultiplier: %s", multiplier and multiplier.id or multiplier)
     end    
end





local function isPlayerHot(thisHeat)
    return common.data.baseTemp + (thisHeat or 0) > 0
end

local function isTempLimitHot(thisHeat)
    return common.data.tempLimit + thisHeat > 0
end


--------------------------------------------------------------------------


local function getExternalHeat()
    local result = 0
    for _, heatSource in ipairs(this.externalHeatSources) do

        local addHeatSource = true--(
        --     --cold and NOT warmOnly
        --     ( 
        --         ( not isTempLimitHot(common.data[heatSource.id]) ) and   
        --         heatSource.warmOnly ~= true 
        --     ) 
            
        --     or 
        --     --warm and not coldOnly
        --     ( 
        --         isTempLimitHot(common.data[heatSource.id]) and             
        --         heatSource.coldOnly ~= true 
        --     )
        -- )
        if addHeatSource then
            if not common.data[heatSource.id] then
                --common.log:error("common.data.%s not found", heatSource.id)
            else
                result = result + common.data[heatSource.id]
            end
        end
    end
    return result
    --[[
        common.data.fireTemp
        common.data.hazardTemp
        common.data.fireDamTemp
        common.data.frostDamTemp
    ]]
end


local function getInternalHeat()
    local result = 0
    for _, heatSource in ipairs(this.internalHeatSources) do

        local addHeatSource = true --(
        --     --cold and NOT warmOnly
        --     ( 
        --         ( not isTempLimitHot(common.data[heatSource.id]) ) and   
        --         heatSource.warmOnly ~= true 
        --     ) 
            
        --     or 
        --     --warm and not ColdOnly
        --     ( 
        --         isTempLimitHot(common.data[heatSource.id]) and             
        --         heatSource.coldOnly ~= true 
        --     )
        -- )
        if addHeatSource then
            if not common.data[heatSource.id] then
                --common.log:error("common.data.%s not found", heatSource.id)
            else
                result = result + common.data[heatSource.id]
            end
        end
    end
    return result

end

local function getBaseTempMultiplier()
    
    local function isBaseTempHot()
        return common.data.tempLimit  > 0
    end
    --[[
        both:
            common.data.alcoholEffect
        coldOnly:
            common.data.ResistFrostEffect
            common.data.vampireColdEffect

            common.data.thirstEffect
        warmOnly:
            common.data.resistFireEffect
            common.data.vampireWarmEffect

            common.data.hungerEffect
    ]]

    --multipliers that directly affect temperature
    local result = 1
    for _, multiplier in ipairs(this.baseTempMultipliers) do
        
        
        local addMultiplier = (
            --cold and NOT warmOnly
            ( 
                ( not isBaseTempHot() ) and   
                multiplier.warmOnly ~= true 
            ) 
            
            or 
            --warm and not ColdOnly
            ( 
                isBaseTempHot() and             
                multiplier.coldOnly ~= true 
            )
        )
        if addMultiplier then
            if not common.data[multiplier.id] then
                --common.log:error("common.data.%s not found", multiplier.id)
            else
                result = result * common.data[multiplier.id]
            end
        end
    end
    return result
end

local timeScale
local function getInternalChangeMultiplier(interval)
    timeScale = timeScale or tes3.findGlobal("timeScale")
    --wetness
    --coverage
    --Sleeping?
    local result = 1
    for _, multiplier in ipairs(this.rateMultipliers) do
        local addMultiplier = (
            ( isPlayerHot() and multiplier.coolingOnly ~= true ) or
            ( not isPlayerHot() and multiplier.warmingOnly ~= true )
        )
        if addMultiplier then

            if not common.data[multiplier.id] then
                --common.log:error("common.data.%s not found", multiplier.id)
            else
                result = result * common.data[multiplier.id]
            end
        end
    end

    --Twice as fast movement if moving towards comfortable/warm
    local comfortMulti = 1.0
    local movingTowardsWarm = (
        common.data.temp > common.staticConfigs.conditionConfig.temp.states.warm.min and common.data.temp > common.data.tempLimit
            or
        common.data.temp < common.staticConfigs.conditionConfig.temp.states.warm.max and common.data.temp < common.data.tempLimit
    )
    if movingTowardsWarm then
        comfortMulti = 2.0
    end
    return math.min(comfortMulti * INT_MULTI * interval * result / timeScale.value, 1)
end


function this.calculate(interval, forceUpdate)
    if not forceUpdate and interval == 0 then return end
    
    if not common.data then return end
    if not common.config.getConfig().enableTemperatureEffects then
        common.data.tempLimit = 0
        common.data.baseTemp = 0
        common.data.temp = 0
        hud.updateHUD()
        return
    end
    common.data.tempLimit = common.data.tempLimit or 0
    common.data.baseTemp = common.data.baseTemp or 0
    common.data.temp = common.data.temp or 0

    common.data.tempLimit = getBaseTempMultiplier() * ( getExternalHeat() + getInternalHeat() )

    --subtract previous base temp before adding new base temp
     common.data.temp = common.data.temp - common.data.baseTemp
     common.data.baseTemp = getInternalHeat()
     common.data.temp = common.data.temp + common.data.baseTemp


    --Change temp faster the bigger the difference, up to a max raw amount
    local difference = math.abs(common.data.temp - common.data.tempLimit)
    local differenceMulti = 1
    if not tes3.menuMode() then
        differenceMulti = math.remap(math.clamp(difference, 0, MAX_DIFFERENCE), 0, MAX_DIFFERENCE, 1.0, MAX_MULTI)
    end

    --Move towards external temp
    common.data.temp = (
        common.data.temp + 
        ( common.data.tempLimit - common.data.temp ) * getInternalChangeMultiplier(interval) * differenceMulti
    )

    hud.updateHUD()
end

local function update(e)

    if e.source then
        common.log:debug(e.source)
    end
    if common.data.valuesInitialised then
        this.calculate(0, true)
    end
end
event.register("Ashfall:updateTemperature", update)

return this