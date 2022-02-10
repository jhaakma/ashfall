
--[[
    When the player looks at a water source (fresh water, wells, etc),
    a tooltip will display, and pressing the activate button will bring up
    a menu that allows the player to drink or fill up a container with water.
]]--


local activatorController = require "mer.ashfall.activators.activatorController"
local LiquidContainer = require "mer.ashfall.objects.LiquidContainer"
local CampfireUtil = require "mer.ashfall.camping.campfire.CampfireUtil"
local thirstController = require("mer.ashfall.needs.thirstController")
local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local brewTea = require("mer.ashfall.camping.menuFunctions.brewTea")
local addIngredient = require("mer.ashfall.camping.menuFunctions.addIngredient")
local foodConfig = common.staticConfigs.foodConfig
local teaConfig = common.staticConfigs.teaConfig
local activatorConfig = common.staticConfigs.activatorConfig

local thirst = common.staticConfigs.conditionConfig.thirst
local hunger = common.staticConfigs.conditionConfig.hunger
local wetness = common.staticConfigs.conditionConfig.wetness

local wetnessPerWater = 5
local function douse(bottleData)
    local amount =  bottleData and bottleData.waterAmount or 1000
    common.log:debug("Douse: amount = %s", amount)
    local currentDryness = 100 - common.data.wetness
    common.log:debug("Douse: currentDryness = %s", currentDryness)
    local waterUsed = math.min(currentDryness/wetnessPerWater, amount)
    common.log:debug("Douse: waterUsed = %s", waterUsed)
    common.data.wetness = common.data.wetness + waterUsed*wetnessPerWater
    event.trigger("Ashfall:updateCondition", { id = "wetness" })


    --handle bottleData if provided
    if bottleData then
        common.log:debug("Douse: Reducing amount in bottle by %s", math.ceil(waterUsed))
        --Reduce liquid in bottleData
        bottleData.waterAmount = bottleData.waterAmount - math.ceil(waterUsed)
        thirstController.handleEmpties(bottleData)
    end

    tes3.playSound{ reference = tes3.player, pitch = 0.8, sound = "Swim Right" }
    tes3.messageBox("You douse yourself with water.")

    return waterUsed
end
event.register("Ashfall:Douse", function(e)
    douse(e.data)
end)


--Create messageBox for water menu
local function callWaterMenu(e)
    e = e or {}
    common.log:debug("callWaterMenu: Water Type: %s", e.waterType)
    common.data.drinkingWaterType = e.waterType
    common.data.drinkingRain = e.rain

    local message = "Water (Clean)"
    if e.waterType == "dirty" then
        message = "Water (Dirty)"
    elseif e.waterType ~= nil then
        local tea = teaConfig.teaTypes[e.waterType]
        if tea and tea.name then
            message = tea.name
        end
    end

    common.helper.messageBox{
        message = message,
        buttons = {
            {
                text = "Drink",
                requirements = function()
                    return thirst:getValue() > 0.1
                end,
                tooltipDisabled = {
                    text = "You are fully hydrated."
                },
                callback = function()
                    thirstController.callWaterMenuAction(function()
                        local waterType = e.waterType
                        thirstController.drinkAmount{amount = 100, waterType = waterType }
                    end)
                end
            },
            {
                text = "Fill Container",
                requirements = thirstController.playerHasEmpties,
                tooltipDisabled = {
                    text = "You have no containers to fill."
                },
                callback = function()
                    local source = LiquidContainer.createInfiniteWaterSource({
                        waterType = e.waterType
                    })
                    thirstController.fillContainer{
                        source = source
                    }
                end
            },
            {
                text = "Douse",
                showRequirements = function()
                    return common.data.wetness <= wetness.states.soaked.min
                        and (e.waterType == "dirty" or not e.waterType)
                        and (not e.stewLevels)
                        and (not e.rain)
                end,
                callback = douse
            }
        },
        doesCancel = true,
    }
    --triple delay frame...
    timer.delayOneFrame(function()timer.delayOneFrame(function()timer.delayOneFrame(function()timer.delayOneFrame(function()
        common.log:debug("common.data.drinkingRain = false drink")
        common.data.drinkingRain = nil
        common.data.drinkingWaterType = nil
    end)end)end)end)
end
event.register("Ashfall:WaterMenu", callWaterMenu)

local function findInnkeeperInCell(cell)
    for ref in cell:iterateReferences(tes3.objectType.npc) do
        if common.isInnkeeper(ref) and ref.mobile and not ref.mobile.isDead then
            return ref
        end
    end
    return false
end

--Register events
event.register(
    "Ashfall:ActivatorActivated",
    function(e)
        if e.activator.owned then
            local innkeeper = findInnkeeperInCell(e.ref.cell)
            if innkeeper then
                tes3.messageBox("Speak to %s to purchase water.", innkeeper.object.name)
                return
            end
        end
        callWaterMenu()
    end,
    { filter = activatorConfig.types.waterSource }
)

event.register(
    "Ashfall:ActivatorActivated",
    function()
        callWaterMenu({ waterType = "dirty" })
    end,
    { filter = activatorConfig.types.dirtyWaterSource }
)


--Look straight up at the rain and activate to bring up water menu
local function checkDrinkRain()
    if not tes3.player then return end
    --thirst active
    local thirstActive = common.data and config.enableThirst

    --raining
    local weather = tes3.getCurrentWeather()
    local raining = weather and
        (weather.index == tes3.weather.rain
            or weather.index == tes3.weather.thunder)

    local lookingUp = tes3.getCameraVector().z > 0.99
    local uncovered = common.data and not common.data.isSheltered

    local doDrink = (
        thirstActive and
        raining and
        lookingUp and
        uncovered
    )
    if doDrink then
        callWaterMenu({ rain = true })
    end
end
event.register("Ashfall:ActivateButtonPressed", checkDrinkRain )


local function getWaterName(data)
    local waterName = "Water"
    if data.waterType == "dirty" then
        waterName = "Water (Dirty)"
    elseif teaConfig.teaTypes[data.waterType] then
        waterName = teaConfig.teaTypes[data.waterType].teaName
    elseif data.stewLevels then
        waterName = foodConfig.isStewNotSoup(data.stewLevels) and "Stew" or "Soup"
    end
    return waterName
end

--Player activates a bottle with water in it
local function doDrinkWater(bottleData)
    --Only drink as much in bottleData
    local thisSipSize = math.min( 100, bottleData.waterAmount )

    --Only drink as much as player needs
    local hydrationNeeded = thirst:getValue()
    thisSipSize = math.min( hydrationNeeded, thisSipSize)

    local amountDrank = thirstController.drinkAmount{amount = thisSipSize, waterType = bottleData.waterType}
    --Tea and stew effects if you drank enough
    local isThirsty = hydrationNeeded > 0.1
    local isTea = teaConfig.teaTypes[bottleData.waterType]
    local teaIsBrewed = bottleData.teaProgress and bottleData.teaProgress >= 100
    if isThirsty and isTea and teaIsBrewed then
        event.trigger("Ashfall:DrinkTea", { teaType = bottleData.waterType, amountDrank = amountDrank, heat = bottleData.waterHeat})
    end
    --Reduce liquid in bottleData
    bottleData.waterAmount = bottleData.waterAmount - thisSipSize
    thirstController.handleEmpties(bottleData)
end

local function getIsPotion(e)
    return e.item.objectType == tes3.objectType.alchemy
        and not foodConfig.getFoodType(e.item)
        and not mwscript.getScript()
end

local function drinkFromContainer(e)

    if common.getIsBlocked(e.item) then return end
    if not config.enableThirst then return end
    --First check potions, gives a little hydration
    if getIsPotion(e) and config.potionsHydrate then
        local thisSipSize = common.staticConfigs.capacities.potion
        thisSipSize = math.min( thirst:getValue(), thisSipSize)
        thirstController.drinkAmount{amount = thisSipSize}
    else
        local liquidLevel = e.itemData and e.itemData.data.waterAmount
        if not liquidLevel then return end

        --If fully hydrated, bring up option to empty bottle
        local isStew = e.itemData.data.stewLevels
        local hungerFull = hunger:getValue() < 1
        local thirstFull = thirst:getValue() < 1

        local doPrompt
        if isStew then
            doPrompt = hungerFull and thirstFull
        else
            doPrompt = thirstFull
        end
        if tes3.worldController.inputController:isKeyDown(config.modifierHotKey.keyCode) then
            doPrompt = true
        end

        if doPrompt then
            local waterName = getWaterName(e.itemData.data)

            local currentAmount = e.itemData.data.waterAmount
            local maxAmount = thirstController.getBottleData(e.item.id).capacity
            local message = string.format("%s (%d/%d)", waterName, currentAmount, maxAmount)


            common.helper.messageBox{
                message = message,
                buttons = {
                    {
                        text = "Drink",
                        showRequirements = function()
                            return e.itemData.data.stewLevels == nil
                        end,
                        callback = function()
                            doDrinkWater(e.itemData.data)
                        end
                    },
                    {
                        text = "Eat",
                        showRequirements = function()
                            return e.itemData.data.stewLevels ~= nil
                        end,
                        requirements = function()
                            return e.itemData.data.stewProgress >= 100
                        end,
                        tooltipDisabled = {
                            text = "You must finish cooking the stew."
                        },
                        callback = function()
                            event.trigger("Ashfall:eatStew", { data = e.itemData.data})
                        end
                    },
                    {
                        text = "Douse",
                        showRequirements = function()
                            return common.data.wetness <= wetness.states.soaked.min
                                and (e.itemData.data.waterType == "dirty" or not e.itemData.data.waterType)
                                and (not e.itemData.data.stewLevels)
                                and (not e.itemData.data.waterHeat or e.itemData.data.waterHeat < common.staticConfigs.hotWaterHeatValue)
                        end,
                        callback = function()
                            douse(e.itemData.data)
                        end
                    },
                    {
                        text = "Fill Container",
                        requirements = thirstController.playerHasEmpties,
                        tooltipDisabled = {
                            text = "You have no containers to fill."
                        },
                        callback = function()
                            local source = LiquidContainer.createFromInventory(e.item, e.itemData)
                            thirstController.fillContainer{
                                source = source
                            }
                        end
                    },
                    {
                        text = "Empty",
                        callback = function()
                            e.itemData.data.waterAmount = 0
                            thirstController.handleEmpties(e.itemData.data)
                            tes3.playSound({reference = tes3.player, sound = "Swim Left"})
                        end
                    },
                },
                doesCancel = true,
            }
        --If water is dirty, give option to drink or empty
        elseif e.itemData.data.waterType == "dirty" then
            local currentAmount = e.itemData.data.waterAmount
            local maxAmount = thirstController.getBottleData(e.item.id).capacity
            local message = string.format("Dirty Water (%d/%d)", currentAmount, maxAmount)

            common.helper.messageBox{
                message = message,
                buttons = {
                    -- {
                    --     text = "Drink",
                    --     callback = function() doDrinkWater(e.itemData.data) end
                    -- },
                    {
                        text = "Drink",
                        showRequirements = function()
                            return e.itemData.data.stewLevels == nil
                        end,
                        callback = function()
                            doDrinkWater(e.itemData.data)
                        end
                    },
                    {
                        text = "Eat",
                        showRequirements = function()
                            return e.itemData.data.stewLevels ~= nil
                        end,
                        requirements = function()
                            return e.itemData.data.stewProgress >= 100
                        end,
                        tooltipDisabled = {
                            text = "You must finish cooking the stew."
                        },
                        callback = function()
                            event.trigger("Ashfall:eatStew", { data = e.itemData.data})
                        end
                    },
                    {
                        text = "Douse",
                        showRequirements = function()
                            return common.data.wetness <= wetness.states.soaked.min
                                and (e.itemData.data.waterType == "dirty" or not e.itemData.data.waterType)
                                and (not e.itemData.data.stewLevels)
                                and (not e.itemData.data.waterHeat or e.itemData.data.waterHeat < common.staticConfigs.hotWaterHeatValue)
                        end,
                        callback = function()
                            douse(e.itemData.data)
                        end
                    },
                    {
                        text = "Fill Container",
                        requirements = thirstController.playerHasEmpties,
                        tooltipDisabled = {
                            text = "You have no containers to fill."
                        },
                        callback = function()
                            local source = LiquidContainer.createFromInventory(e.item, e.itemData)
                            thirstController.fillContainer{
                                source = source
                            }
                        end
                    },
                    {
                        text = "Empty",
                        callback = function()
                            e.itemData.data.waterAmount = 0
                            thirstController.handleEmpties(e.itemData.data)
                            tes3.playSound({reference = tes3.player, sound = "Swim Left"})
                        end
                    }
                },
                doesCancel = true
            }
        --Otherwise drink straight away
        else
            if e.itemData.data.stewLevels then
                event.trigger("Ashfall:eatStew", { data = e.itemData.data})
            else
                doDrinkWater(e.itemData.data)
            end
        end
    end
end
event.register("equip", drinkFromContainer, { filter = tes3.player, priority = -100 } )


local skipActivate
local function onShiftActivateWater(e)
    common.log:debug("onShiftActivateWater")
    if tes3ui.menuMode() then return end
    if not (e.activator == tes3.player) then return end
    -- if activatorController.currentRef == e.target then
    --     common.log:debug("Ignoring Activator")
    --     --Activators handled elsewhere
    --     return
    -- end
    if skipActivate then
        skipActivate = false
        return
    end
    if e.target.data and e.target.data.waterAmount and e.target.data.waterAmount > 0 then
        local inputController = tes3.worldController.inputController
        local isModifierKeyPressed = common.helper.isModifierKeyPressed()

        if isModifierKeyPressed then
            local message = getWaterName(e.target.data)
            local bottleType = common.staticConfigs.bottleList[e.target.object.id:lower()]
            message = string.format("%s (%d/%d)", message, math.ceil(e.target.data.waterAmount), bottleType.capacity)
            local buttons = {
                {
                    text = brewTea.text,
                    showRequirements = function()
                        return brewTea.showRequirements(e.target)
                    end,
                    callback = function()
                        brewTea.callback(e.target)
                    end
                },
                {
                    text = addIngredient.text,
                    showRequirements = function()
                        return addIngredient.showRequirements(e.target)
                    end,
                    requirements = function()
                        return addIngredient.enableRequirements(e.target)
                    end,
                    tooltipDisabled = addIngredient.tooltipDisabled,
                    callback = function()
                        addIngredient.callback(e.target)
                    end
                },
                {
                    text = "Drink",
                    showRequirements = function()
                        return e.target.data.stewLevels == nil
                    end,
                    callback = function()
                        doDrinkWater(e.target.data)
                        event.trigger("Ashfall:UpdateAttachNodes", {campfire = e.target})
                    end
                },
                {
                    text = "Eat",
                    showRequirements = function()
                        return e.target.data.stewLevels ~= nil
                    end,
                    requirements = function()
                        return e.target.data.stewProgress >= 100
                    end,
                    tooltipDisabled = {
                        text = "You must finish cooking the stew."
                    },
                    callback = function()
                        event.trigger("Ashfall:eatStew", { data = e.target.data})
                        event.trigger("Ashfall:UpdateAttachNodes", {campfire = e.target})
                    end
                },
                {
                    text = "Douse",
                    showRequirements = function()
                        return common.data.wetness <= wetness.states.soaked.max
                            and (e.target.data.waterType == "dirty" or not e.target.data.waterType)
                            and (not e.target.data.stewLevels)
                            and (not e.target.data.waterHeat or e.target.data.waterHeat < common.staticConfigs.hotWaterHeatValue)
                    end,
                    callback = function()
                        douse(e.target.data)
                        event.trigger("Ashfall:UpdateAttachNodes", {campfire = e.target})
                    end
                },
                {
                    text = "Fill Container",
                    requirements = thirstController.playerHasEmpties,
                    tooltipDisabled = {
                        text = "You have no containers to fill."
                    },
                    callback = function()
                        local source = LiquidContainer.createFromReference(e.target)
                        thirstController.fillContainer{
                            source = source
                        }
                    end
                },
                {
                    text = "Empty",
                    callback = function()
                        e.target.data.waterAmount = 0
                        thirstController.handleEmpties(e.target.data)
                        tes3.playSound({reference = tes3.player, sound = "Swim Left"})
                        event.trigger("Ashfall:UpdateAttachNodes", {campfire = e.target})
                    end
                },
                {
                    text = "Pick Up",
                    callback = function()
                        timer.delayOneFrame(function()
                            skipActivate = true
                            tes3.player:activate(e.target)
                        end)
                    end
                }
            }
            common.helper.messageBox{ message = message, buttons = buttons, doesCancel = true }
            return true
        end
    end
end
-- event.register("activate", onShiftActivateWater, { filter = tes3.player })



--First time entering a cell, add water to random bottles/containers
local chanceToFill = 0.2
local teaChance = 0.1
local fillMin = 5
local function addWaterToWorld(e)
    local wateredCells = common.data.wateredCells
    local cellId = common.helper.getUniqueCellId(e.cell)
    if not wateredCells[cellId] then
        wateredCells[cellId] = true

        for ref in e.cell:iterateReferences(tes3.objectType.miscItem) do
            local bottleData = thirstController.getBottleData(ref.object.id)
            if bottleData and not ref.data.waterAmount then
                if math.random() < chanceToFill then
                    local fillAmount = math.random(fillMin, bottleData.capacity)
                    ref.data.waterAmount = fillAmount

                    if math.random() < teaChance then
                        local waterType = table.choice(teaConfig.validTeas)
                        --Make sure it's not a tea added by a mod the player doesn't have
                        if tes3.getObject(waterType) then
                            ref.data.waterType = waterType
                            ref.data.teaProgress = 100
                        end
                    end

                    ref.modified = true
                end
            end
        end
    end
end

event.register("cellChanged", addWaterToWorld)