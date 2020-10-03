--[[
    Iterates over objects that  and updates their fuel level
]]
local common = require ("mer.ashfall.common.common")
local foodConfig = common.staticConfigs.foodConfig
local hungerController = require("mer.ashfall.needs.hungerController")
local thirstController = require("mer.ashfall.needs.thirstController")
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


local function eatStew(e)
    local stewBuffs = foodConfig.getStewBuffList()
    --remove old sbuffs
    for foodType, buff in pairs(stewBuffs) do
        if e.data.stewLevels[foodType] == nil then
            mwscript.removeSpell{ reference = tes3.player, spell = buff.id }
        end
    end



    --add up ingredients, mulitplying nutrition by % in the pot
    local nutritionLevel = 0
    local maxNutritionLevel = 0
    for foodType, _ in pairs(stewBuffs) do
        local nutrition = foodConfig.getNutritionForFoodType(foodType)
        nutritionLevel = nutritionLevel + ( nutrition * ( e.data.stewLevels[foodType] or 0 ) / 100 )
        maxNutritionLevel = nutritionLevel + nutrition
    end
    local foodRatio = nutritionLevel / maxNutritionLevel
    
    local highestNeed = math.max(common.staticConfigs.conditionConfig.hunger:getValue() / foodRatio, common.staticConfigs.conditionConfig.thirst:getValue())
    local maxDrinkAmount = math.min(e.data.waterAmount, 50, highestNeed )

    local amountAte = hungerController.eatAmount(maxDrinkAmount * foodRatio)
    local amountDrank = thirstController.drinkAmount{amount = maxDrinkAmount, waterType = e.data.waterType}
    


    if amountAte >= 1 or amountDrank >= 1 then
        tes3.playSound{ reference = tes3.player, sound = "Swallow" }
        e.data.waterAmount = math.max( (e.data.waterAmount - amountDrank), 0)
        
        if e.data.waterHeat and e.data.waterHeat >= common.staticConfigs.hotWaterHeatValue then
            common.data.stewWarmEffect = common.helper.calculateStewWarmthBuff(e.data.waterHeat) 
        end
        
        --Add buffs and set duration
        for foodType, ingredLevel in pairs(e.data.stewLevels) do
            --add spell
            local stewBuff = stewBuffs[foodType]
            local effectStrength = common.helper.calculateStewBuffStrength(math.min(ingredLevel, 100), stewBuff.min, stewBuff.max)
            timer.delayOneFrame(function()
                local spell = tes3.getObject(stewBuff.id)
                local effect = spell.effects[1]
                effect.min = effectStrength
                effect.max = effectStrength
                mwscript.addSpell{ reference = tes3.player, spell = spell }
                local ateAmountMulti = amountAte / 100
                tes3.player.data.stewBuffTimeLeft = common.helper.calculateStewBuffDuration() * ateAmountMulti
                common.log:debug("Set stew duration to %s", tes3.player.data.stewBuffTimeLeft)
                event.trigger("Ashfall:registerReference", { reference = tes3.player})
            end)
        end

    else
        tes3.messageBox("You are full.")
    end
end
event.register("Ashfall:eatStew", eatStew)