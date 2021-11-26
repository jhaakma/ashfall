local this = {}
local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local conditionsCommon = require("mer.ashfall.conditionController")

local statsEffect = require("mer.ashfall.needs.statsEffect")

local temperatureController = require("mer.ashfall.temperatureController")
temperatureController.registerBaseTempMultiplier({ id = "hungerEffect", coldOnly = true })

local coldMulti = 4.0
local foodPoisonMulti = 5.0
local HUNGER_EFFECT_LOW = 1.3
local HUNGER_EFFECT_HIGH = 1.0

local hunger = common.staticConfigs.conditionConfig.hunger
local foodConfig = common.staticConfigs.foodConfig



function this.getBurnLimit()
    --TODO: Use survival skill to determine
    local survival = common.skills.survival.value
    if not survival then
        common.log:error("No survival skill found")
        return 150
    end

    local burnLimit = math.remap(survival, common.skillStartValue, 100, 120, 160)
    return burnLimit
end

function this.getNutrition(object, itemData)
    local foodData = foodConfig.getFoodData(object)
    if not foodData then return end

    local foodValue = foodData.nutrition
    --scale by weight
    foodValue = foodValue * math.remap(object.weight, 0, 1, 0.2, 1)

    local cookedAmount = itemData and itemData.data.cookedAmount
    if cookedAmount then
        local survival = common.skills.survival.value
        local survivalEffect = math.remap(
            survival,
            common.skillStartValue, 100,
            foodData.grillValues.min, foodData.grillValues.max
        )

        local min = foodValue
        local max = math.ceil(foodValue * survivalEffect)


        --value based on how cooked it is
        cookedAmount = math.min(cookedAmount, 100)
        foodValue = math.remap(cookedAmount, 0, 100, min, max)
        common.log:trace("foodValue %s", foodValue)
        if itemData.data.grillState == "cooked" then
            foodValue = foodValue * foodConfig.cookedMulti
            common.log:trace("Food is cooked, new foodValue %s", foodValue)
        elseif itemData.data.grillState == "burnt" then
            foodValue = foodValue * foodConfig.burntMulti
            common.log:trace("Food is burnt, new foodValue %s", foodValue)
        end

    end
    return foodValue
end


function this.eatAmount( amount )
    if not config.enableHunger then
        return 0
    end

    local currentHunger = hunger:getValue()
    local amountAte = math.min(amount, currentHunger)

    --Get the health stat before and after applying the hunger
    local before = statsEffect.getMaxStat("health")
    hunger:setValue(currentHunger - amountAte)
    local after = statsEffect.getMaxStat("health")

    --Increase health by how much was gained by eating
    local healthIncrease = after - before
    tes3.modStatistic{
        reference = tes3.mobilePlayer,
        current = healthIncrease,
        name = "health",
    }
    conditionsCommon.updateCondition("hunger")
    this.update()
    event.trigger("Ashfall:updateTemperature", { source = "eatAmount" })
    event.trigger("Ashfall:updateNeedsUI")
    event.trigger("Ashfall:UpdateHud")
    return amountAte
end



function this.processMealBuffs(scriptInterval)
    --decrement buff time
    if common.data.mealTime and common.data.mealTime > 0 then
        common.data.mealTime = math.max(common.data.mealTime - scriptInterval, 0)

    --Time's up, remove buff
    elseif common.data.mealBuff then
        mwscript.removeSpell({ reference = tes3.player, spell = common.data.mealBuff })
        common.data.mealBuff = nil
    end
end


local function checkWerewolfKill()
    --TODO: recover hunger after making a kill as a werewolf
    return
end

function this.calculate(scriptInterval, forceUpdate)
    if scriptInterval == 0 and not forceUpdate then return end

    --Check Ashfall disabled
    if not hunger:isActive() then
        hunger:setValue(0)
        return
    end
    if common.data.blockNeeds == true then
        return
    end
    if common.data.blockHunger == true then
        return
    end

    local hungerRate = config.hungerRate / 10

    local newHunger = hunger:getValue()

    local temp = common.staticConfigs.conditionConfig.temp

    --Colder it gets, the faster you grow hungry
    local coldEffect = math.clamp(temp:getValue(), temp.states.freezing.min, temp.states.chilly.max)
    coldEffect = math.remap( coldEffect, temp.states.freezing.min,  temp.states.chilly.max, coldMulti, 1.0)

     --if you have food poisoning you get hungry more quickly
    local foodPoisonEffect = common.staticConfigs.conditionConfig.foodPoison:isAffected() and foodPoisonMulti or 1.0

    if common.helper.getIsSleeping() then
        newHunger = newHunger + ( scriptInterval * hungerRate * coldEffect * foodPoisonEffect * config.restingNeedsMultiplier )
    elseif common.helper.getIsTraveling() then
        common.log:debug("Travelling, adding travel multiplier to hunger")
        newHunger = newHunger + ( scriptInterval * hungerRate * coldEffect * foodPoisonEffect * config.travelingNeedsMultiplier )
    else
        newHunger = newHunger + ( scriptInterval * hungerRate * coldEffect * foodPoisonEffect )
    end
    hunger:setValue(newHunger)

    checkWerewolfKill()


    --The hungrier you are, the more extreme cold temps are
    local hungerEffect = math.remap( newHunger, 0, 100, HUNGER_EFFECT_HIGH, HUNGER_EFFECT_LOW )
    common.data.hungerEffect = hungerEffect
end

function this.update()
    this.calculate(0, true)
end

local function addFoodPoisoning(e)
    --Check for food poisoning
    if foodConfig.getFoodType(e.item) == foodConfig.type.meat then

        --survival affect gives chance to bypass completely
        local survival = common.skills.survival.value
        local survivalRoll = math.random(100)
        if survivalRoll < survival then
            common.log:debug("Survival Effect of %s bypassed food poisoning with a roll of %s",survival, survivalRoll)
            return
        end

        local foodPoison = common.staticConfigs.conditionConfig.foodPoison
        local cookedAmount = e.itemData and e.itemData.data.cookedAmount or 0
        local cookedEffect = math.remap(
            cookedAmount,
            0, 100,--min in, max in
            1.0, 0.0
        )
        local minPoison = 50
        local maxPoison = 120
        local poisonAmount = math.random(minPoison, maxPoison) * cookedEffect
        common.log:debug("Adding %s food poisoning. Min/Max: %s/%s", poisonAmount, minPoison, maxPoison)
        foodPoison:setValue(foodPoison:getValue() + poisonAmount)
    end
end

local function addDisease(e)
    if config.enableDiseasedMeat then
        common.log:debug("addDisease()")
        if e.itemData then
            common.log:debug("has data")
            local diseaseData = e.itemData.data.mer_disease
            if diseaseData ~= nil then
                common.log:debug("Trying to contract %s", diseaseData.id)
                common.helper.tryContractDisease(diseaseData.id)
            end
        end
    end
end

local function onEquipFood(e)
    common.log:trace("onEquipFood")
    if common.getIsBlocked(e.item) then
        common.log:debug("onEquipFood: Is Blocked")
        return
    end
    local nutrition = this.getNutrition(e.item, e.itemData)
    if nutrition then
        common.log:debug("onEquipFood: Is ingredient")
        this.eatAmount(nutrition)
        addFoodPoisoning(e)
        addDisease(e)
    end
end

event.register("equip", onEquipFood, { filter = tes3.player, priority = -100 } )


local function onShiftActivateFood(e)
    local nutrition = this.getNutrition(e.target.object, e.target.itemData)
    if nutrition then
        local inputController = tes3.worldController.inputController
        local isModifierKeyPressed = (
            inputController:isKeyDown(config.modifierHotKey.keyCode)
        )
        local hasAccess = tes3.hasOwnershipAccess{ target = e.target }
        if hasAccess and isModifierKeyPressed then
            common.log:debug("Shift Activated %s has nutrition of %s", e.target, nutrition)
            local eventData = {
                item = e.target.object,
                itemData = e.target.itemData,
                reference = tes3.player
            }
            tes3.playSound{ reference = tes3.player, sound = "Swallow" }
            common.helper.yeet(e.target)
            onEquipFood(eventData)
            e.block = true
        end
    end
end
event.register("activate", onShiftActivateFood, { filter = tes3.player, priority = -100})

--Interop eat event
local function onEat(e)
    if e.reference == tes3.player then
        this.eatAmount(e.amount)
    end
end
event.register("Ashfall:Eat", onEat)

return this