local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local needsUI = require("mer.ashfall.needs.needsUI")
local this = {}
local statsEffect = require("mer.ashfall.needs.statsEffect")

local interruptText = ""
local isUsingBed
local mustWait
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

local function setBedTemp(e)
    common.data.usingBed = e.isUsingBed
    common.log:debug("===========================Checking Bed Temp: %s", common.data.usingBed)
    common.data.bedTempMulti = common.data.usingBed and bedTempMulti or 1.0
end
event.register("Ashfall:SetBedTemp", setBedTemp)


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

--Prevent Resting, enable Wait button
local function forceWait(restMenu)
    restMenu:findChild( tes3ui.registerID("MenuRestWait_wait_button") ).visible = true
    restMenu:findChild( tes3ui.registerID("MenuRestWait_untilhealed_button") ).visible = false
    restMenu:findChild( tes3ui.registerID("MenuRestWait_rest_button") ).visible = false
end


local function setRestValues(e)
    if not common.data then return end
    --scripted means the player has activated a bed or bedroll
    isUsingBed = e.scripted
    mustWait = not e.allowRest
    --Set interrupt text
    local tempLimit = common.data.tempLimit
    local tempText = ( tempLimit < 0 ) and "cold" or "hot"
    local restText = ( e.allowRest ) and "rest" or "wait"

    interruptText = string.format("It is too %s to %s, you must find shelter!", tempText, restText)

end
event.register("uiShowRestMenu", setRestValues )

--Prevent tiredness if env is too cold/hot
--We do this by tapping into the Rest Menu,
--replacing the text and removing rest/wait buttons
local function activateRestMenu (e)
    common.log:debug("activateRestMenu")
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
    if isUsingBed ~= true and common.helper.getInside(tes3.player) ~= true then 
        forceWait(restMenu)
        labelText.text = "You must find a bed or go indoors to rest."
    end

    if ( tempLimit < coldRestLimit ) or ( tempLimit > hotRestLimit ) then
        labelText.text = string.format("It is too %s to %s, you must find shelter!", 
            ( tempLimit < 0 and "cold" or "hot"), 
            ( mustWait and "rest" or "wait" )
        )
        hideSleepItems(restMenu)
    elseif hunger:getValue() > hunger.states.starving.min then
        labelText.text = string.format("You are too hungry to %s.", 
            ( mustWait and "wait" or "rest")
        )
        hideSleepItems(restMenu)
    elseif thirst:getValue() > thirst.states.dehydrated.min then
        labelText.text = string.format("You are too thirsty to %s.", 
            ( mustWait and "wait" or "rest")
        )
        hideSleepItems(restMenu)
    elseif tiredness:getValue() > tiredness.states.exhausted.min and mustWait then
        labelText.text = "You are too tired to wait, you must find a bed."
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

local function wakeUp()
    tes3.wakeUp()
    event.trigger("Ashfall:WakeUp")
end

local function getIsSleeping()
    return tes3.mobilePlayer.sleeping or common.data.isSleeping
end
local function getIsWaiting()
    return tes3.mobilePlayer.waiting or common.data.isWaiting
end

local function checkInterruptSleep()
    if getIsSleeping() or getIsWaiting() then
        --wait(interval * 0.10)

        local tempLimit = common.data.tempLimit
        --Temperature
        if tempLimit < coldRestLimit or tempLimit > hotRestLimit then
            wakeUp()
            tes3.messageBox({ message = interruptText, buttons = { "Okay" } })
        end
        --Needs
        if hunger:getValue() >= hunger.states.starving.min - 1 then
            --Cap the hunger loss
            hunger:setValue(hunger.states.starving.min)
            --Wake PC
            wakeUp()
            --Message PC
            tes3.messageBox({ message = "You are starving.", buttons = { "Okay" } }) 
        elseif thirst:getValue() > thirst.states.dehydrated.min - 1  then
            --Cap the thirst loss
            wakeUp()
            --Wake PC
            thirst:setValue(thirst.states.dehydrated.min)
            --Message PC
            tes3.messageBox({ message = "You are dehydrated.", buttons = { "Okay" } }) 
        elseif (tiredness:getValue() > tiredness.states.exhausted.min - 1) and getIsWaiting() then
            --Cap the tiredness loss
            tiredness:setValue(tiredness.states.exhausted.min)
            --Rouse PC
            wakeUp()
            --Message PC
            tes3.messageBox({ message = "You are exhausted.", buttons = { "Okay" } }) 
        end
        
        if tes3.mobilePlayer.sleeping and isUsingBed then
            if not common.data.usingBed then
                common.log:debug("setting inBed to true")
                event.trigger("Ashfall:SetBedTemp", { isUsingBed = true})
            end
        end 
    else
        --Reset the bedTemp when player wakes up
        if common.data.usingBed then
            common.log:debug("setting inBed to false")
            event.trigger("Ashfall:SetBedTemp", { isUsingBed = false})
        end
     end
end


function this.calculate(scriptInterval, forceUpdate)
    checkInterruptSleep()

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
    local loseSleepRate = config.loseSleepRate / 10
    local loseSleepWaiting = config.loseSleepWaiting / 10
    local gainSleepRate = config.gainSleepRate / 10  
    local gainSleepBed = config.gainSleepBed / 10
    
    --slows tiredness drain
    local hackloEffect = common.data.hackloTeaEffect or 1
    --speeds up tiredness recovery while sleeping
    local tramaRootTeaEffect = common.data.tramaRootTeaEffect or 1

    if getIsSleeping() then
        local usingBed = common.data.usingBed or common.data.isSleeping or false
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
    --werewolf
    if tes3.mobilePlayer.werewolf then
        currentTiredness = currentTiredness * werewolfSleepMulti
    end
    currentTiredness = math.clamp(currentTiredness, 0, 100)
    tiredness:setValue(currentTiredness)
end

local function checkTentEnemyPreventRest(e)
    if common.data.insideTent then
        local doAllowRest = (
            e.mobile.inCombat ~= true and
            e.reference.position:distance(tes3.player.position) > 1000
        )
        if doAllowRest then
            return false
        end
    end
end
event.register("preventRest", checkTentEnemyPreventRest)

return this