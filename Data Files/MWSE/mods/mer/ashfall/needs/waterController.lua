
--[[
    When the player looks at a water source (fresh water, wells, etc), 
    a tooltip will display, and pressing the activate button will bring up
    a menu that allows the player to drink or fill up a container with water.
]]--
 

local thirstController = require("mer.ashfall.needs.thirstController")
local common = require("mer.ashfall.common.common")
local foodConfig = common.staticConfigs.foodConfig
local teaConfig = common.staticConfigs.teaConfig
local activatorConfig = common.staticConfigs.activatorConfig

local thirst = common.staticConfigs.conditionConfig.thirst
local hunger = common.staticConfigs.conditionConfig.hunger

local buttons = {}
local bDrink = "Drink"
local bFillBottle = "Fill bottle"
local bNothing = "Nothing"

local function menuButtonPressed(e)
    local buttonIndex = e.button + 1
    --Drink
    if buttons[buttonIndex] == bDrink then
        if thirst:getValue() <= 0.1 then
            tes3.messageBox("You are fully hydrated.")
        else
            thirstController.callWaterMenuAction(function()
                thirstController.drinkAmount{amount = 100, waterType = common.data.drinkingDirtyWater}
            end)
        end
    --refill
    elseif buttons[buttonIndex] == bFillBottle then
        thirstController.fillContainer()
        return
    end
    common.data.drinkingRain = false
    common.data.drinkingDirtyWater = false
end


--Create messageBox for water menu
local function callWatermenu()
    buttons = { bDrink, bFillBottle, bNothing }
    tes3.messageBox{
        message = "What would you like to do?",
        buttons = buttons,
        callback = menuButtonPressed
    }
end


--Register events
event.register(
    "Ashfall:ActivatorActivated", 
    function()
        common.log:debug("CLEAN water")
        common.data.drinkingDirtyWater = false
        callWatermenu()
    end,
    { filter = activatorConfig.types.waterSource } 
)

event.register(
    "Ashfall:ActivatorActivated", 
    function()
        common.log:debug("DIRTY water")
        common.data.drinkingDirtyWater = true
        callWatermenu()
    end, 
    { filter = activatorConfig.types.dirtyWaterSource } 
)


--Look straight up at the rain and activate to bring up water menu
local function checkDrinkRain()
    --thirst active
    local thirstActive = common.data and common.config.getConfig().enableThirst
    --activate button
    local inputController = tes3.worldController.inputController
    local pressedActivate = inputController:keybindTest(tes3.keybind.activate)
    --raining
    local weather = tes3.getCurrentWeather()
    local raining = (
            weather and weather.index == tes3.weather.rain or 
            weather and weather.index == tes3.weather.thunder
            
    )
    --looking up
    local lookingUp = (
        tes3.getCameraVector().z > 0.99
    )
    --uncovered
    local uncovered = common.data and not common.data.isSheltered


    local doDrink = (
        thirstActive and
        pressedActivate and 
        raining and 
        lookingUp and 
        uncovered
    )
    if doDrink then
        common.log:debug("common.data.drinkingRain = true")
        common.data.drinkingRain = true
        callWatermenu()
    end
end
event.register("keyDown", checkDrinkRain )


local function handleEmpties(data)
    if data.waterAmount and data.waterAmount <= 0 then
        data.waterType = nil
        data.waterAmount = nil
        data.stewLevels = nil
        --restack
        tes3ui.updateInventoryTiles()
    end
end


--Player activates a bottle with water in it
local function doDrinkWater(data)
    --Only drink as much in bottle
    local thisSipSize = math.min( 100, data.waterAmount )

    --Only drink as much as player needs
    local hydrationNeeded = thirst:getValue()
    thisSipSize = math.min( hydrationNeeded, thisSipSize)

    local amountDrank = thirstController.drinkAmount{amount = thisSipSize, waterType = data.waterType}
    --Tea and stew effects if you drank enough
    if hydrationNeeded > 0.1 then
        if teaConfig.teaTypes[data.waterType] then
            event.trigger("Ashfall:DrinkTea", { teaType = data.waterType, amountDrank = amountDrank})
        elseif data.stewLevels then
            event.trigger("Ashfall:eatStew",{data = data})
        end
    end
    --Reduce liquid in bottle
    data.waterAmount = data.waterAmount - thisSipSize
    handleEmpties(data)
end


local function drinkFromContainer(e)
    
    if common.getIsBlocked(e.item) then return end
    --First check potions, gives a little hydration
    if e.item.objectType == tes3.objectType.alchemy then
        local thisSipSize = common.staticConfigs.capacities.potion
        thisSipSize = math.min( thirst:getValue(), thisSipSize)
        thirstController.drinkAmount{amount = thisSipSize}
    
    else
        local liquidLevel = (
            e.itemData and
            e.itemData.data.waterAmount
        )
        local doDrink = (
            common.config.getConfig().enableThirst and
            liquidLevel
        )
        if doDrink then
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

            if doPrompt then
                local waterName = ""
                if e.itemData.data.waterType == "dirty" then
                    waterName = "Dirty Water"
                elseif teaConfig.teaTypes[e.itemData.data.waterType] then
                    waterName = teaConfig.teaTypes[e.itemData.data.waterType].teaName
                elseif e.itemData.data.stewLevels then
                    waterName = foodConfig.isStewNotSoup(e.itemData.data.stewLevels) and "Stew" or "Soup"
                else
                    waterName = "Water"
                end

                common.helper.messageBox{
                    message = "You are fully hydrated.",
                    buttons = {
                        { 
                            text = string.format("Empty %s", waterName), 
                            callback = function()
                                e.itemData.data.waterAmount = 0
                                handleEmpties(e.itemData.data)
                                tes3.playSound({reference = tes3.player, sound = "Swim Left"})
                            end
                        },
                        { text = tes3.findGMST(tes3.gmst.sCancel).value }
                    }
                }
            --If water is dirty, give option to drink or empty
            elseif e.itemData.data.waterType == "dirty" then
                common.helper.messageBox{
                    message = "Dirty Water",
                    buttons = {
                        { 
                            text = "Drink", 
                            callback = function() doDrinkWater(e.itemData.data) end 
                        },
                        { 
                            text = "Empty", 
                            callback = function()
                                e.itemData.data.waterAmount = 0
                                handleEmpties(e.itemData.data)
                                tes3.playSound({reference = tes3.player, sound = "Swim Left"})
                            end
                        },
                        { text = tes3.findGMST(tes3.gmst.sCancel).value }
                    }
                }
            --Otherwise drink straight away
            else
                doDrinkWater(e.itemData.data)
            end
        end
    end
end
event.register("equip", drinkFromContainer, { filter = tes3.player, priority = -100 } )


local skipActivate
local function onShiftActivateWater(e)
    if skipActivate then
        skipActivate = false
        return
    end
    if e.target.data and e.target.data.waterAmount and e.target.data.waterAmount > 0 then
        local inputController = tes3.worldController.inputController
        local isModifierKeyPressed = (
            inputController:isKeyDown(common.config.getConfig().modifierHotKey.keyCode)
        )
        local hasAccess = tes3.hasOwnershipAccess{ target = e.target }
        if hasAccess and isModifierKeyPressed then
            local message = "Water"
            if e.target.data.waterType == "dirty" then
                message = "Dirty Water"
            elseif teaConfig.teaTypes[e.target.data.waterType] then
                message = teaConfig.teaTypes[e.target.data.waterType].teaName
            end
            local bottleType = common.staticConfigs.bottleList[e.target.object.id:lower()]
            message = string.format("%s (%d/%d)", message, math.ceil(e.target.data.waterAmount), bottleType.capacity)
            local buttons = {
                {
                    text = "Drink",
                    callback = function()
                        doDrinkWater(e.target.data)
                    end
                },
                {
                    text = "Empty",
                    callback = function()
                        e.target.data.waterAmount = 0
                        handleEmpties(e.target.data)
                        tes3.playSound({reference = tes3.player, sound = "Swim Left"})
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
                },
                { text = tes3.findGMST(tes3.gmst.sCancel).value }
            }
            common.helper.messageBox{ message = message, buttons = buttons }
            return true
        end
    end
end
event.register("activate", onShiftActivateWater, { filter = tes3.player })

--First time entering a cell, add water to random bottles/containers
local chanceToFill = 0.2
local teaChance = 0.1
local fillMin = 5
local function addWaterToWorld(e)
    local wateredCells = common.data.wateredCells
    if not wateredCells[string.lower(e.cell.id)] then
        wateredCells[string.lower(e.cell.id)] = true

        for ref in e.cell:iterateReferences(tes3.objectType.miscItem) do
            local bottleData = thirstController.getBottleData(ref.object.id)
            if bottleData and not ref.data.waterAmount then
                if math.random() < chanceToFill then
                    local fillAmount = math.random(fillMin, bottleData.capacity)
                    ref.data.waterAmount = fillAmount
                    
                    if math.random() < teaChance then
                        local teaType = table.choice(teaConfig.validTeas)
                        --Make sure it's not a tea added by a mod the player doesn't have
                        if tes3.getObject(teaType) then
                            ref.data.waterType = teaType
                        end
                    end

                    ref.modified = true
                end
            end
        end
    end
end

event.register("cellChanged", addWaterToWorld)