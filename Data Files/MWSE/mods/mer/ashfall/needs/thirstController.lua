
local this = {}
local common = require("mer.ashfall.common.common")
local teaConfig = common.staticConfigs.teaConfig
local conditionsCommon = require("mer.ashfall.conditionController")
local hud = require("mer.ashfall.ui.hud")
local statsEffect = require("mer.ashfall.needs.statsEffect")
local temperatureController = require("mer.ashfall.temperatureController")
temperatureController.registerBaseTempMultiplier({ id = "thirstEffect", warmOnly = true })

local heatMulti = 4.0
local dysentryMulti = 5.0
local THIRST_EFFECT_LOW = 1.3
local THIRST_EFFECT_HIGH = 1.0
local restMultiplier = 1.0

local conditionConfig = common.staticConfigs.conditionConfig
local thirst = conditionConfig.thirst

function this.calculate(scriptInterval, forceUpdate)
    if  scriptInterval == 0 and not forceUpdate then return end
    
    if not thirst:isActive() then
        thirst:setValue(0)
        return
    end
    if common.data.drinkingRain then
        return
    end
    if common.data.blockNeeds == true then
        return
    end
    if common.data.blockThirst == true then
        return
    end

    local thirstRate = common.config.getConfig().thirstRate / 10
    local currentThirst = thirst:getValue()
    local temp = conditionConfig.temp

    --Hotter it gets the faster you become thirsty
    local heatEffect = math.clamp(temp:getValue(), temp.states.warm.min, temp.states.scorching.max )
    heatEffect = math.remap(heatEffect, temp.states.warm.min, temp.states.scorching.max, 1.0, heatMulti)
    
     --if you have dysentry you get thirsty more quickly
     local dysentryEffect = common.staticConfigs.conditionConfig.dysentery:isAffected() and dysentryMulti or 1.0

    --Calculate thirst
    local resting = (
        tes3.mobilePlayer.sleeping or
        tes3.menuMode()
    )
    if resting then
        currentThirst = currentThirst + ( scriptInterval * thirstRate * heatEffect * dysentryEffect * restMultiplier )
    else
        currentThirst = currentThirst + ( scriptInterval * thirstRate * heatEffect * dysentryEffect )
    end
    currentThirst = math.clamp(currentThirst, 0, 100) 

    thirst:setValue(currentThirst)

    --The thirstier you are, the more extreme heat temps are
    local thirstEffect = math.remap(currentThirst, 0, 100, THIRST_EFFECT_HIGH, THIRST_EFFECT_LOW)
    common.data.thirstEffect = thirstEffect
end

function this.update()
    this.calculate(0, true)
end


function this.getBottleData(id)
    return common.staticConfigs.bottleList[string.lower(id)]
end


local function addDysentry()
    local dysentery = common.staticConfigs.conditionConfig.dysentery
    local dysentryAmount = math.random(100)
    dysentery:setValue(dysentery:getValue() + dysentryAmount)
end

function this.drinkAmount( amount, waterType )
    if not conditionConfig.thirst:isActive() then return end
    local currentThirst = thirst:getValue()
    
    if currentThirst <= 0.1 then
        tes3.messageBox("You are fully hydrated.")
        return 0
    end
    local amountDrank = math.min( currentThirst, amount )

    local before = statsEffect.getMaxStat("magicka")
    thirst:setValue(currentThirst - amountDrank)
    local after = statsEffect.getMaxStat("magicka")

    --local magickaIncrease = tes3.mobilePlayer.magicka.base * ( amountDrank / 100 )
    local magickaIncrease = after - before
    tes3.modStatistic{
        reference = tes3.mobilePlayer,
        current = magickaIncrease,
        name = "magicka",
    }
    conditionsCommon.updateCondition("thirst")
    this.update()
    event.trigger("Ashfall:updateTemperature", { source = "drinkAmount" } )
    event.trigger("Ashfall:updateNeedsUI")
    hud.updateHUD()

    tes3.playSound({reference = tes3.player, sound = "Drink"})

    if waterType == "dirty" then
        addDysentry()
    end
    return amountDrank
end


local function onDrink(e)
    this.drinkAmount( e.amount, e.waterType )
end
event.register("Ashfall:Drink", onDrink, {reference = tes3.player})

function this.callWaterMenuAction(callback)
    common.log:debug("if common.data.drinkingRain then")
    if common.data.drinkingRain then
        common.data.drinkingRain = false
        common.helper.fadeTimeOut( 0.25, 2, callback )
    else
        callback()
    end
    common.data.drinkingDirtyWater = nil
end

--Fill a bottle to max water capacity
function this.fillContainer(params)
    params = params or {}
    local cost = params.cost
    local source = params.source
    local callback = params.callback
    local teaType = params.teaType
    timer.delayOneFrame(function()
        local noResultsText = "You have no containers to fill."
        if teaType then
            noResultsText = "You have no empty containers to fill."
        end
        tes3ui.showInventorySelectMenu{
            title = "Select Water Container",
            noResultsText = noResultsText,
            filter = function(e)

                --Can only fill empty bottles with tea
                if teaType and e.itemData and e.itemData.data.waterAmount and e.itemData.data.waterAmount > 0 then 
                    return false 
                end

                --Can't fill bottles that already have tea
                if e.itemData and teaConfig.teaTypes[e.itemData.data.waterType] then
                    return false
                end

                local bottleData = this.getBottleData(e.item.id)
                if bottleData then
                    local capacity = bottleData.capacity
                    local currentAmount = e.itemData and e.itemData.data.waterAmount or 0
                    return currentAmount < capacity
                else
                    return false
                end
            end,
            callback = function(e)
                if e.item then 
                    this.callWaterMenuAction(function()
                        --initialise itemData
                        local itemData = e.itemData
                        if not itemData then
                            itemData = tes3.addItemData{ 
                                to = tes3.player, 
                                item = e.item,
                                updateGUI = true
                            }
                        end

                        --dirty container if drinking from raw water
                        if common.data.drinkingDirtyWater == true then
                            common.log:debug("Fill water DIRTY")
                            itemData.data.waterType = "dirty"
                            common.data.drinkingDirtyWater = nil
                        end
                        local fillAmount
                        local bottleData = this.getBottleData(e.item.id)

                        itemData.data.waterAmount = itemData.data.waterAmount or 0
                        
                        if source then
                            if source.data.waterType then
                                itemData.data.waterType = source.data.waterType
                            end

                            fillAmount = math.min(
                                bottleData.capacity - itemData.data.waterAmount,
                                source.data.waterAmount
                            )
                            common.helper.transferQuantity(source.data, itemData.data, "waterAmount", "waterAmount", fillAmount)

                            --clean source if empty
                            if source.data.waterAmount == 0 then
                                source.data.waterType = nil
                            end
                        else
                            itemData.data.waterAmount = bottleData.capacity
                        end

                        tes3ui.updateInventoryTiles()
                        tes3.playSound({reference = tes3.player, sound = "Swim Left"})
                        local contents = "water"
                        if itemData.data.waterType == "dirty" then
                            contents = "dirty water"
                        end
                        if teaConfig.teaTypes[itemData.data.waterType] then
                            contents = teaConfig.teaTypes[itemData.data.waterType].teaName
                        end
                        tes3.messageBox(
                            "%s filled with %s.",
                            e.item.name,
                            contents
                        )

                        if callback then callback() end
                        
                        if cost then
                            mwscript.removeItem({ reference = tes3.player, item = "Gold_001", count = cost})
                            local message = string.format(tes3.findGMST(tes3.gmst.sNotifyMessage63).value, cost, "Gold")
                            tes3.messageBox(message)
                            tes3.playSound{ reference = tes3.player, sound = "Item Gold Down"}
                        end

                    end)
                end
            end
        }
        timer.delayOneFrame(function()
            common.log:debug("common.data.drinkingRain = false fill")
            common.data.drinkingRain = false
            common.data.drinkingDirtyWater = false
        end)
    end)
end

return this
