
--[[
    When the player looks at a water source (fresh water, wells, etc),
    a tooltip will display, and pressing the activate button will bring up
    a menu that allows the player to drink or fill up a container with water.
]]--
local LiquidContainer = require "mer.ashfall.liquid.LiquidContainer"
local thirstController = require("mer.ashfall.needs.thirstController")
local common = require("mer.ashfall.common.common")
local logger = common.createLogger("waterController")
local config = require("mer.ashfall.config").config
local foodConfig = common.staticConfigs.foodConfig
local teaConfig = common.staticConfigs.teaConfig
local activatorConfig = common.staticConfigs.activatorConfig

local thirst = common.staticConfigs.conditionConfig.thirst
local hunger = common.staticConfigs.conditionConfig.hunger
local wetness = common.staticConfigs.conditionConfig.wetness

local wetnessPerWater = 5
local function douse(bottleData)
    local amount =  bottleData and bottleData.waterAmount or 1000
    logger:debug("Douse: amount = %s", amount)
    local currentDryness = 100 - common.data.wetness
    logger:debug("Douse: currentDryness = %s", currentDryness)
    local waterUsed = math.min(currentDryness/wetnessPerWater, amount)
    logger:debug("Douse: waterUsed = %s", waterUsed)
    common.data.wetness = common.data.wetness + waterUsed*wetnessPerWater
    event.trigger("Ashfall:updateCondition", { id = "wetness" })


    --handle bottleData if provided
    if bottleData then
        logger:debug("Douse: Reducing amount in bottle by %s", math.ceil(waterUsed))
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
    logger:debug("callWaterMenu: Water Type: %s", e.waterType)
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
    local source = LiquidContainer.createInfiniteWaterSource({
        waterType = e.waterType
    })

    tes3ui.showMessageMenu{
        message = message,
        buttons = {
            {
                text = "Drink",
                enableRequirements = function()
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
                enableRequirements = function()
                    return thirstController.playerHasEmpties(source)
                end,
                tooltipDisabled = {
                    text = common.messages.noContainersToFill
                },
                callback = function()
                    thirstController.fillContainer{
                        source = source
                    }
                end
            },
            {
                text = "Douse",
                showRequirements = function()
                    return common.data.wetness <= wetness.states.soaked.min
                        and source:isWater()
                        and (not e.rain)
                end,
                callback = douse
            }
        },
        cancels = true,
    }
    --triple delay frame...
    timer.delayOneFrame(function()timer.delayOneFrame(function()timer.delayOneFrame(function()timer.delayOneFrame(function()
        logger:debug("common.data.drinkingRain = false drink")
        common.data.drinkingRain = nil
        common.data.drinkingWaterType = nil
    end)end)end)end)
end
event.register("Ashfall:WaterMenu", callWaterMenu)

local function findInnkeeperInCell(cell)
    for ref in cell:iterateReferences(tes3.objectType.npc) do
        if common.helper.isInnkeeper(ref) and ref.mobile and not ref.mobile.isDead then
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

    if common.helper.getIsBlocked(e.item) then return end
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
        ---@type AshfallLiquidContainer
        local source = LiquidContainer.createFromInventory(e.item, e.itemData)

        local doPrompt
        if isStew then
            doPrompt = hungerFull and thirstFull
        else
            doPrompt = thirstFull
        end
        if tes3.worldController.inputController:isKeyDown(config.modifierHotKey.keyCode) then
            doPrompt = true
        end
        if source:getLiquidType() == "dirty" then
            doPrompt = true
        end

        if doPrompt then
            local waterName = source:getLiquidName()
            local currentAmount = e.itemData.data.waterAmount
            local maxAmount = thirstController.getBottleData(e.item.id).capacity
            local message = string.format("%s (%d/%d)", waterName, currentAmount, maxAmount)
            tes3ui.showMessageMenu{
                message = message,
                buttons = {
                    {
                        text = "Drink",
                        showRequirements = function()
                            return source:getLiquidType() ~= "stew"
                        end,
                        callback = function()
                            doDrinkWater(e.itemData.data)
                        end
                    },
                    {
                        text = "Eat",
                        showRequirements = function()
                            return source:getLiquidType() == "stew"
                        end,
                        enableRequirements = function()
                            return source:isCookedStew()
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
                            local playerPartiallyDry = common.data.wetness <= wetness.states.soaked.min
                            local waterTooHot = source:getHeat() >= common.staticConfigs.hotWaterHeatValue
                            return playerPartiallyDry
                                and source:isWater()
                                and not waterTooHot
                        end,
                        callback = function()
                            douse(e.itemData.data)
                        end
                    },
                    {
                        text = "Fill Container",
                        enableRequirements = function()
                            return thirstController.playerHasEmpties(source)
                        end,
                        tooltipDisabled = {
                            text = common.messages.noContainersToFill
                        },
                        callback = function()
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
                cancels = true,
            }
        --If water is dirty, give option to drink or empty
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

---@param e itemDroppedEventData
local function clearDataOnDrop(e)
    if e.reference.data then
        e.reference.data.lastWaterUpdated = nil
        e.reference.data.lastBrewUpdated = nil
        e.reference.data.lastStewUpdated = nil
        e.reference.data.lastWaterHeatUpdated = nil
    end
end
event.register("itemDropped", clearDataOnDrop)
