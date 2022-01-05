
local LiquidContainer = require "mer.ashfall.objects.LiquidContainer"

local this = {}
local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local conditionsCommon = require("mer.ashfall.conditionController")
local statsEffect = require("mer.ashfall.needs.statsEffect")
local temperatureController = require("mer.ashfall.temperatureController")
temperatureController.registerBaseTempMultiplier({ id = "thirstEffect", warmOnly = true })

local heatMulti = 4.0
local dysentryMulti = 5.0
local THIRST_EFFECT_LOW = 1.3
local THIRST_EFFECT_HIGH = 1.0

local conditionConfig = common.staticConfigs.conditionConfig
local thirst = conditionConfig.thirst

function this.handleEmpties(data)
    common.log:trace("handleEmpties")
    if data.waterAmount and data.waterAmount < 1 then
        common.log:debug("handleEmpties: waterAmount < 1, clearing water data")
        event.trigger("Ashfall:Campfire_clear_water_data", {data = data})
        --restack / remove sound
        tes3ui.updateInventoryTiles()
    end
end

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

    local thirstRate = config.thirstRate / 10
    local currentThirst = thirst:getValue()
    local temp = conditionConfig.temp
    --Hotter it gets the faster you become thirsty
    local heatEffect = math.clamp(temp:getValue(), temp.states.warm.min, temp.states.scorching.max )
    heatEffect = math.remap(heatEffect, temp.states.warm.min, temp.states.scorching.max, 1.0, heatMulti)
     --if you have dysentry you get thirsty more quickly
     local dysentryEffect = common.staticConfigs.conditionConfig.dysentery:isAffected() and dysentryMulti or 1.0
    --Calculate thirst

    if common.helper.getIsSleeping() then
        currentThirst = currentThirst + ( scriptInterval * thirstRate * heatEffect * dysentryEffect * config.restingNeedsMultiplier )
    elseif common.helper.getIsTraveling() then
        common.log:debug("Traveling, adding travelling multiplier to thirst")
        currentThirst = currentThirst + ( scriptInterval * thirstRate * heatEffect * dysentryEffect * config.travelingNeedsMultiplier)
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
    return common.staticConfigs.bottleList[id and string.lower(id)]
end


function this.playerHasEmpties()
    for stack in tes3.iterate(tes3.player.object.inventory.iterator) do
        local bottleData = this.getBottleData(stack.object.id)
        if bottleData then
            common.log:trace("Found a bottle")
            if stack.variables then
                common.log:trace("Has data")
                if #stack.variables < stack.count then
                    common.log:trace("Some bottles have no data")
                    return true
                end

                for _, itemData in pairs(stack.variables) do
                    if itemData then
                        common.log:trace("itemData: %s", itemData)
                        common.log:trace("waterAmount: %s", itemData and itemData.data.waterAmount )
                        if itemData.data.waterAmount then
                            if itemData.data.waterAmount < bottleData.capacity then
                                if not itemData.data.stewLevels and not itemData.data.waterType then
                                    --at least one bottle can be filled
                                    common.log:trace("below capacity")
                                    return true
                                end
                            end
                        else
                            --no itemData means empty bottle
                            common.log:trace("no waterAmount")
                            return true
                        end
                    end
                end
            else
                --no itemData means empty bottle
                common.log:trace("no variables")
                return true
            end
        end
    end
    return false
end


local function addDysentry(amountDrank)
    local survival = common.skills.survival.value
    local survivalRoll = math.random(100)
    if survivalRoll < survival then
        common.log:debug("Survival Effect of %s bypassed dysentery with a roll of %s", survival, survivalRoll)
        return
    end

    --determine max added dysentery
    local maxDysentery = math.remap(amountDrank, 0, 100, 85, 120)
    local minDysentery = maxDysentery / 4

    local dysentery = common.staticConfigs.conditionConfig.dysentery
    local dysentryAmount = math.random(minDysentery, maxDysentery)
    common.log:debug("Adding %s dysentery. Max was %s", dysentryAmount, maxDysentery)
    dysentery:setValue(dysentery:getValue() + dysentryAmount)
    common.log:debug("New dysentery amount is %s", dysentery:getValue())
end


local function blockMagickaAtronach()
    common.log:trace("Checking atronach settings")
    if tes3.isAffectedBy{ reference = tes3.player, effect = tes3.effect.stuntedMagicka} then
        common.log:debug("Is an atronach")
        if config.atronachRecoverMagickaDrinking ~= true then
            common.log:debug("blockMagickaAtronach: Blocking atronach from gaining magicka")
            return true
        end
    end
    return false
end


function this.drinkAmount(e)
    common.log:debug("drinkAmount. WaterType: %s", e.waterType)
    local amount = e.amount or 100
    local waterType = e.waterType
    if not conditionConfig.thirst:isActive() then
        return 0
    end

    local currentThirst = thirst:getValue()
    if currentThirst <= 0.1 then
        tes3.messageBox("You are fully hydrated.")
        return 0
    end
    local amountDrank = math.min( currentThirst, amount )

    local before = statsEffect.getMaxStat("magicka")
    thirst:setValue(currentThirst - amountDrank)
    local after = statsEffect.getMaxStat("magicka")

    if not blockMagickaAtronach() then
        --local magickaIncrease = tes3.mobilePlayer.magicka.base * ( amountDrank / 100 )
        local magickaIncrease = after - before
        tes3.modStatistic{
            reference = tes3.mobilePlayer,
            current = magickaIncrease,
            name = "magicka",
        }
    end
    conditionsCommon.updateCondition("thirst")
    this.update()
    event.trigger("Ashfall:updateTemperature", { source = "drinkAmount" } )
    event.trigger("Ashfall:updateNeedsUI")
    event.trigger("Ashfall:UpdateHud")

    tes3.playSound({reference = tes3.player, sound = "Drink"})

    if waterType == "dirty" then
        addDysentry(amountDrank)
    end
    return amountDrank
end

event.register("Ashfall:Drink", this.drinkAmount, {reference = tes3.player})

function this.callWaterMenuAction(callback)
    common.log:debug("calling water menu action")
    if common.data.drinkingRain == true then
        common.log:debug("Drinking rain is true")
        common.data.drinkingRain = nil
        common.helper.fadeTimeOut( 0.25, 2, callback )
    else
        common.log:debug("Drinking rain is false")
        callback()
    end
    common.data.drinkingWaterType = nil
end


--Fill a bottle to max water capacity
function this.fillContainer(params)
    params = params or {}
    local cost = params.cost
    ---@type AshfallLiquidContainer
    local source = params.source or LiquidContainer.createInfiniteWaterSource()
    local callback = params.callback
    timer.delayOneFrame(function()
        local noResultsText =  "You have no containers to fill."
        tes3ui.showInventorySelectMenu{
            title = "Select Water Container",
            noResultsText = noResultsText,
            filter = function(e)
                local to = LiquidContainer.createFromInventory(e.item, e.itemData)
                return to and source:canTransfer(to) or false
            end,
            callback = function(e)
                if e.item then
                    this.callWaterMenuAction(function()
                        if not e.itemData then
                            e.itemData = tes3.addItemData{ item = e.item, to = tes3.player, updateGUI = true}
                        end
                        local to = LiquidContainer.createFromInventory(e.item, e.itemData)
                        source:transferLiquid(to)
                        --add callback
                        if callback then callback() end
                        --add cost
                        if cost then
                            mwscript.removeItem({ reference = tes3.player, item = "Gold_001", count = cost})
                            local message = string.format(tes3.findGMST(tes3.gmst.sNotifyMessage63).value, cost, "Gold")
                            tes3.messageBox(message)
                            tes3.playSound{ reference = tes3.player, sound = "Item Gold Down"}
                        end
                    end )
                end
            end
        }
        timer.delayOneFrame(function()
            common.log:debug("common.data.drinkingRain = false fill")
            common.data.drinkingRain = false
            common.data.drinkingWaterType = nil
        end)
    end)
end



return this
