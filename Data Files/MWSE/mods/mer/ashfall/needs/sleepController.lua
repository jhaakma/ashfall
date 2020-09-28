local common = require("mer.ashfall.common.common")
local needsUI = require("mer.ashfall.needs.needsUI")
local this = {}
local statsEffect = require("mer.ashfall.needs.statsEffect")

local interruptText = ""
local isUsingBed
local isWaiting
local werewolfSleepMulti = 0.6
local bedTempMulti = 0.8

local temperatureController = require("mer.ashfall.temperatureController")
--temperatureController.registerInternalHeatSource({ id = "bedTemp", coldOnly = true })
temperatureController.registerBaseTempMultiplier{ id = "bedTempMulti"}

local conditionConfig = common.staticConfigs.conditionConfig
local coldRestLimit = conditionConfig.temp.states.veryCold.min
local hotRestLimit = conditionConfig.temp.states.veryHot.max
local hunger = conditionConfig.hunger
local thirst = conditionConfig.thirst
local tiredness = conditionConfig.tiredness

local function setInBed(inBed)
    common.data.usingBed = inBed
    common.data.bedTempMulti = inBed and bedTempMulti or 1.0
end


local function setRestValues(e)
    if not common.data then return end
    --scripted means the player has activated a bed or bedroll
    isUsingBed = e.scripted
    isWaiting = not e.allowRest
    --Set interrupt text
    local tempLimit = common.data.tempLimit
    local tempText = ( tempLimit < 0 ) and "cold" or "hot"
    local restText = ( e.allowRest ) and "rest" or "wait"

    interruptText = string.format("It is too %s to %s, you must find shelter!", tempText, restText)

end
event.register("uiShowRestMenu", setRestValues )


local function hideSleepItems(restMenu)
    local hiddenList = {}
    hiddenList.scrollbar = restMenu:findChild( tes3ui.registerID("MenuRestWait_scrollbar") )
    hiddenList.hourText = restMenu:findChild( tes3ui.registerID("MenuRestWait_hour_text") )
    hiddenList.hourActualText = hiddenList.hourText.parent.children[2]
    hiddenList.untilHealed = restMenu:findChild( tes3ui.registerID("MenuRestWait_untilhealed_button") )
    hiddenList.wait = restMenu:findChild( tes3ui.registerID("MenuRestWait_wait_button") )
    hiddenList.rest = restMenu:findChild( tes3ui.registerID("MenuRestWait_rest_button") )

    for _, element in pairs(hiddenList) do
        element.visible = false
    end
end

local function forceWait(restMenu)
    restMenu:findChild( tes3ui.registerID("MenuRestWait_wait_button") ).visible = true
    restMenu:findChild( tes3ui.registerID("MenuRestWait_untilhealed_button") ).visible = false
    restMenu:findChild( tes3ui.registerID("MenuRestWait_rest_button") ).visible = false
end

--Prevent tiredness if ENVIRONMENT is too cold/hot
--We do this by tapping into the Rest Menu,
--replacing the text and removing rest/wait buttons
local function activateRestMenu (e)
    if not common.data then return end

    if isUsingBed then
        --manually update tempLimit so you can see what it will be with the bedTemp added

        --common.data.bedTemp = bedWarmth
        common.data.bedTempMulti = bedTempMulti
        --common.data.tempLimit = common.data.tempLimit + bedWarmth
        event.trigger("Ashfall:updateTemperature", { source = "activateRestMenu"})
        common.log:debug("Is Scripted: adding warmth")
    end

    local tempLimit = common.data.tempLimit
    local restMenu = e.element
    local labelText = restMenu:findChild( tes3ui.registerID("MenuRestWait_label_text") )

    --Prevent rest if not using a bed
    if not isUsingBed and not common.helper.getInside(tes3.player) then 
        forceWait(restMenu)
        labelText.text = "You must find a bed or go indoors to rest."
    end

    if ( tempLimit < coldRestLimit ) or ( tempLimit > hotRestLimit ) then
        labelText.text = interruptText
        hideSleepItems(restMenu)
    elseif hunger:getValue() > hunger.states.starving.min then
        labelText.text = "You are too hungry to " .. ( isWaiting and "wait." or "rest.")
        hideSleepItems(restMenu)
    elseif thirst:getValue() > thirst.states.dehydrated.min then
        labelText.text = "You are too thirsty to " .. ( isWaiting and "wait." or "rest.")
        hideSleepItems(restMenu)
    elseif tiredness:getValue() > tiredness.states.exhausted.min and isWaiting then
        labelText.text = "You are too tired to wait."
        hideSleepItems(restMenu)
    end

    --Hide "Rest until healed" button if health is not lower than max
    local maxHealth = statsEffect.getMaxStat("health")
    if tes3.mobilePlayer.health.current >= maxHealth then
        e.element:findChild( tes3ui.registerID("MenuRestWait_untilhealed_button") ).visible = false
    end


    needsUI.addNeedsBlockToMenu(e, "tiredness")
    restMenu:updateLayout()

end
event.register("uiActivated", activateRestMenu, { filter = "MenuRestWait" })


--Wake up if sleeping and ENVIRONMENT is too cold/hot
local clock = os.clock
local function wait(n)  -- seconds
    local t0 = clock()
    while clock() - t0 <= n do end
end

local function checkSleeping(interval)
    --whether waiting or sleeping, wake up
    local restingOrWaiting = (
        interval > 0 and 
        tes3.menuMode() and 
        common.config.getConfig().enableTemperatureEffects and 
        tes3.player.data.Ashfall.fadeBlock ~= true
    )

    if restingOrWaiting then

        --Slow down real time it takes to wait. This gives us room to breath, 
        -- see the weather change, react to conditions etc.
        --wait(interval * 0.10)

        local tempLimit = common.data.tempLimit
        --Temperature
        if tempLimit < coldRestLimit or tempLimit > hotRestLimit then
            tes3.runLegacyScript({ command = "WakeUpPC" })
            tes3.messageBox({ message = interruptText, buttons = { "Okay" } })

            --needs
        end
        if hunger:getValue() > hunger.states.starving.min then
            --Cap the hunger loss
            hunger:setValue(hunger.states.starving.min)
            --Wake PC
            tes3.runLegacyScript({ command = "WakeUpPC" })
            --Message PC
            tes3.messageBox({ message = "You are starving.", buttons = { "Okay" } }) 
        elseif thirst:getValue() > thirst.states.dehydrated.min then
            --Cap the thirst loss
            tes3.runLegacyScript({ command = "WakeUpPC" })
            --Wake PC
            thirst:setValue(thirst.states.dehydrated.min)
            --Message PC
            tes3.messageBox({ message = "You are dehydrated.", buttons = { "Okay" } }) 
        elseif tiredness:getValue() > tiredness.states.exhausted.min and isWaiting then
            --Cap the tiredness loss
            tiredness:setValue(tiredness.states.exhausted.min)
            --Rouse PC
            tes3.runLegacyScript({ command = "WakeUpPC" })
            --Message PC
            tes3.messageBox({ message = "You are exhausted.", buttons = { "Okay" } }) 
        end

        if tes3.mobilePlayer.sleeping and isUsingBed then
            if not common.data.usingBed then
                common.log:debug("setting inBed to true")
                setInBed(true)
            end
        end 
    end
    if not tes3ui.menuMode() then
        --Reset the bedTemp when player wakes up
        if common.data.usingBed then
            common.log:debug("setting inBed to false")
            setInBed(false) 
        end
     end
end


function this.calculate(scriptInterval, forceUpdate)
    checkSleeping(scriptInterval)

    if scriptInterval == 0 and not forceUpdate then return end
    if not tiredness:isActive() then
        tiredness:setValue(0)
        return
    end
    if common.data.blockNeeds == true then
        return
    end
    if common.data.blockSleepLoss == true then
        return
    end

    local currentTiredness = tiredness:getValue()
    local loseSleepRate = common.config.getConfig().loseSleepRate / 10
    local loseSleepWaiting = common.config.getConfig().loseSleepWaiting / 10
    local gainSleepRate = common.config.getConfig().gainSleepRate / 10  
    local gainSleepBed = common.config.getConfig().gainSleepBed / 10
    
    --slows tiredness drain
    local hackloEffect = common.data.hackloTeaEffect or 1
    --speeds up tiredness recovery while sleeping
    local tramaRootTeaEffect = common.data.tramaRootTeaEffect or 1

    if tes3.mobilePlayer.sleeping then
        local usingBed = common.data.usingBed or false
        if usingBed then
            currentTiredness = currentTiredness - ( scriptInterval * gainSleepBed * tramaRootTeaEffect )
        else
            --Not using bed, gain tiredness slower and can't get below "Rested"
            local newTiredness = currentTiredness - ( scriptInterval * gainSleepRate * tramaRootTeaEffect )
            if newTiredness > tiredness.states.rested.min then
                currentTiredness = newTiredness
            end
        end
    --TODO: traveling isn't working for some reason
    elseif tes3.mobilePlayer.travelling then
        --Traveling: getting some rest but can't get below "Rested"
        if currentTiredness > tiredness.states.rested.min then
            currentTiredness = currentTiredness - ( scriptInterval * gainSleepRate )
        end
    --Waiting
    elseif tes3.menuMode() then
        currentTiredness = currentTiredness + ( scriptInterval * loseSleepWaiting * hackloEffect )
    --Normal time
    else
        currentTiredness = currentTiredness + ( scriptInterval * loseSleepRate * hackloEffect * werewolfSleepMulti )
    end
    currentTiredness = math.clamp(currentTiredness, 0, 100)
    tiredness:setValue(currentTiredness)
end


return this