--[[
    Iterates over objects that  and updates their fuel level
]]
local common = require ("mer.ashfall.common.common")
local config = require("mer.ashfall.config").config
local logger = common.createLogger("stewerController")
local LiquidContainer = require("mer.ashfall.liquid.LiquidContainer")
local foodConfig = common.staticConfigs.foodConfig
local hungerController = require("mer.ashfall.needs.hungerController")
local thirstController = require("mer.ashfall.needs.thirstController")
local ReferenceController = require("mer.ashfall.referenceController")
local stewCookRate = 40
local STEWER_UPDATE_INTERVAL = 0.001

local staticConfigs = require('mer.ashfall.config.staticConfigs')

ReferenceController.registerReferenceController{
    id = "stewer",
    requirements = function(_, ref)
        local isPot = ref.supportsLuaData
            and ref.data
            and ref.data.utensil == "cookingPot"
            or staticConfigs.cookingPots[ref.object.id:lower()]
        return isPot
    end,
}

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
                    mwscript.removeSpell({ reference = reference, spell = stewBuff.id}) ---@diagnostic disable-line
                end
                tes3.messageBox("Stew effect has worn off.")


                reference.data.stewBuffTimeLeft = nil
                reference.data.lastStewBuffUpdated = nil
            else
                reference.data.lastStewBuffUpdated = e.timestamp
            end
        end
    end
    ReferenceController.iterateReferences("stewBuffedActor", doUpdateBuff)
end



local function updateStewers(e)

    local function doUpdate(stewerRef)
        local liquidContainer = LiquidContainer.createFromReference(stewerRef)
        if not liquidContainer then return end
        if liquidContainer.waterAmount == 0 then return end

        liquidContainer.lastStewUpdated = liquidContainer.lastStewUpdated or e.timestamp
        local difference = e.timestamp - liquidContainer.lastStewUpdated

        if difference < 0 then
            logger:error("STEWER liquidContainer.lastStewUpdated(%.4f) is ahead of e.timestamp(%.4f).",
                liquidContainer.lastStewUpdated, e.timestamp)
            --something fucky happened
            liquidContainer.lastStewUpdated = e.timestamp
        end

        if difference > STEWER_UPDATE_INTERVAL then
            liquidContainer.lastStewUpdated = e.timestamp
            local hasWater = liquidContainer.waterAmount and liquidContainer.waterAmount > 0
            if hasWater then
                liquidContainer.waterHeat = liquidContainer.waterHeat or 0
                local waterIsBoiling = liquidContainer.waterHeat and liquidContainer.waterHeat >= common.staticConfigs.hotWaterHeatValue
                local hasStew = liquidContainer.stewLevels
                if waterIsBoiling and hasStew then
                    --Cook the stew

                    liquidContainer.stewProgress = liquidContainer.stewProgress or 0
                    local waterHeatEffect = common.helper.calculateWaterHeatEffect(liquidContainer.waterHeat)
                    liquidContainer.stewProgress = math.clamp((liquidContainer.stewProgress + ( difference * stewCookRate * waterHeatEffect )), 0, 100)
                else
                    liquidContainer.lastStewUpdated = nil
                end
            end
        end
    end
    ReferenceController.iterateReferences("stewer", doUpdate)
end

 event.register("simulate", function(e)
    updateStewers(e)
    updateBuffs(e)
 end)


local function eatStew(e)
    local stewBuffs = foodConfig.getStewBuffList()

    if (not e.data.stewProgress) or e.data.stewProgress < 100 then
        return
    end

    --add up ingredients, mulitplying nutrition by % in the pot
    local nutritionLevel = 0
    local maxNutritionLevel = 0
    for foodType, data in pairs(stewBuffs) do
        local nutrition = foodConfig.getNutritionForFoodType(foodType) * data.stewNutrition
        nutritionLevel = nutritionLevel + ( nutrition * ( e.data.stewLevels[foodType] or 0 ) / 100 )
        maxNutritionLevel = nutritionLevel + nutrition
    end
    local foodRatio = nutritionLevel / maxNutritionLevel

    --Calculate amount to eat
    local highestAmount
    if config.enableHunger then
        local hunger = common.staticConfigs.conditionConfig.hunger:getValue()
        local thirst = common.staticConfigs.conditionConfig.thirst:getValue()
        logger:debug("hunger: %s", hunger)
        logger:debug("thirst: %s", thirst)

        local highestNeed = math.max(
            hunger / foodRatio,
            thirst
        )
        logger:debug("highestNeed: %s", highestNeed)
        local maxAmount = math.min(e.data.waterAmount, 50, highestNeed )

        local amountAte = hungerController.eatAmount(maxAmount)
        local amountDrank = thirstController.drinkAmount{amount = maxAmount, waterType = e.data.waterType}
        highestAmount = math.max(amountAte, amountDrank)
    else
        highestAmount = common.staticConfigs.DEFAULT_EAT_AMOUNT
    end

    if highestAmount >= 1 then
        --remove old buffs
        for foodType, buff in pairs(stewBuffs) do
            if e.data.stewLevels[foodType] == nil then
                mwscript.removeSpell{ reference = tes3.player, spell = buff.id } ---@diagnostic disable-line
            end
        end
        tes3.playSound{ reference = tes3.player, sound = "Swallow" }
        e.data.waterAmount = math.max( (e.data.waterAmount - highestAmount), 0)
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
                mwscript.addSpell{ reference = tes3.player, spell = spell } ---@diagnostic disable-line
                --Effect maxes out at 10 units, then divide remaining 10 by 10 to get normalised effect
                local ateAmountMulti = math.min(highestAmount, 10) / 10
                logger:debug("ateAmountMulti %s", ateAmountMulti)
                --Give at least half an hour when drinking a small amount
                local timeLeft = math.max(0.5, common.helper.calculateStewBuffDuration(e.data.waterHeat) * ateAmountMulti)
                tes3.player.data.stewBuffTimeLeft = timeLeft
                logger:debug("Set stew duration to %s", tes3.player.data.stewBuffTimeLeft)
                event.trigger("Ashfall:registerReference", { reference = tes3.player})
            end)
        end
    else
        tes3.messageBox("You are full.")
    end
    if e.data.waterAmount and e.data.waterAmount < 1 then
        logger:debug("Clearing data after eating stew")
        LiquidContainer.createFromData(e.data):empty()
    end
end
event.register("Ashfall:eatStew", eatStew)