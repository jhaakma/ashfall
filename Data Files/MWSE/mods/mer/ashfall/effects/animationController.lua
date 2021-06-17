local helper = require("mer.ashfall.common.helperFunctions")
local common = require("mer.ashfall.common.common")
local this = {}

local data = {
    mesh = nil, 
    minutes = nil,
    callback = nil,
    previousAnimationMesh = nil,
    fastTimer = nil,
    originalTimeScale = nil,
    speed = nil,
    sleeping = nil,
    collisionRef = nil
}
local animConfig = {
    sitSlave = {
        mesh = "ashfall\\anim\\SlaveSitting.nif",
        group = tes3.animationGroup.idle9
    },
    sitForward = {
        mesh = "ashfall\\anim\\VA_sitting.nif",
        group = tes3.animationGroup.idle5
    },
    sitCrossed = {
        mesh = "ashfall\\anim\\VA_sitting.nif",
        group = tes3.animationGroup.idle4
    },
    layBack = {
        mesh = "ashfall\\anim\\VA_sitting.nif",
        group = tes3.animationGroup.idle9,
    },
    laySide = {
        mesh = "ashfall\\anim\\VA_sitting.nif",
        group = tes3.animationGroup.idle8,
    }
}

function this.sitDown(e)
    table.copy(animConfig.sitCrossed, e)
    this.doAnimation(e)
end

function this.layDown(e)
    table.copy(animConfig.layBack, e)
    this.doAnimation(e)
end

function this.hasAnimFile(animFile)
    local fileToCheck = animFile
    local path = lfs.currentdir() .. "\\Data Files\\meshes\\" .. fileToCheck
    local fileExists = lfs.attributes(path, "mode") == "file"
    return fileExists
end

local function onTabUp()
    common.log:debug("Tab pressed up, back to vanity mode")
    timer.delayOneFrame(function()
        tes3.mobilePlayer.controlsDisabled = true
        tes3.setVanityMode({ enabled = true })
    end)
end

local function onTabDown()
    common.log:debug("Tab pressed down, allowing mouse look")
    timer.delayOneFrame(function()
        tes3.mobilePlayer.controlsDisabled = false
        tes3.setVanityMode({ enabled = false })
    end)
end


--handle keypress to cancel animation
local function checkKeyPress(e)
    if e.keyCode == 183 then return end --allow screenshots
    --If this is tab being pressed down --only for non-location, moving messing up camera
    local inputController = tes3.worldController.inputController
    local togglePovKey = tes3.getInputBinding(tes3.keybind.togglePOV).code

    if e.keyCode == togglePovKey then
        common.log:debug("Pressed toggle POV key")
        onTabDown()
        return
    end
    if inputController:isKeyDown(togglePovKey) then
        return
    end
    common.log:debug("Detected Key Press, cancelling")
    this.cancel()
end

local function blockSave()
    return false
end

local function startAnimation(e)
    if not this.hasAnimFile(e.mesh) then
        common.log:error("missing animation files")
        return
    end
    data.previousAnimationMesh = tes3.player.object.mesh
    tes3.playAnimation({
        reference = tes3.player,
        mesh = e.mesh,
        group = e.group,
        startFlag = 1
    })
    event.trigger("Ashfall:triggerPackUpdate")
end



local function stopAnimation()
    common.log:debug("Cancelling animation")
    tes3.playAnimation({
        reference = tes3.player,
        mesh = data.previousAnimationMesh,
        group = tes3.animationGroup.idle,
        startFlag = 1
    })
    event.trigger("Ashfall:triggerPackUpdate")
    data.previousAnimationMesh = nil
end

local function doSlowTime(e)
    tes3.worldController.deltaTime = e.delta * (data and data.speed or 1)
    if not data then common.log:debug("doSlowTime no data") end
end


local function startFastTime(e)
    local timeScaleMulti = e.timeScaleMulti or 1.0
    local deltaMulti = math.clamp( timeScaleMulti, 1, 4)
    data.speed = deltaMulti

    
    local timeScale = tes3.findGlobal("TimeScale")
    data.originalTimeScale = timeScale.value
    timeScale.value = timeScale.value * timeScaleMulti
    event.register("enterFrame", doSlowTime)

    common.log:debug("Starting Fast Time with timescale at %sx speed, new timescale = %s",
        timeScaleMulti,
        timeScale.value
    )
end

local function stopFastTime()
    common.log:debug("Stopping fast time, setting timescale back to %s", data.originalTimeScale)
    local timeScale = tes3.findGlobal("TimeScale")
    timeScale.value = data.originalTimeScale
    event.unregister("enterFrame", doSlowTime)
end


local function getHoursPassed()
    return ( tes3.worldController.daysPassed.value * 24 ) + tes3.worldController.hour.value
end
--local wasIn3rdPerson
function this.doAnimation(e)
    common.log:debug("do animation")
    data = e
    if data.collisionRef then
        common.log:debug("Has Collision REF %s, setting NO Collision to TRUE", data.collisionRef )
        data.collisionRef = tes3.makeSafeObjectHandle(data.collisionRef)
        common.log:debug("hasNoCollision before: %s", data.collisionRef:getObject().hasNoCollision)
        data.collisionRef:getObject().hasNoCollision = true
        common.log:debug("hasNoCollision after: %s", data.collisionRef:getObject().hasNoCollision)
    end
    if data.usingBed then
        event.trigger("Ashfall:SetBedTemp", { isUsingBed = true})
    end
    if data.covered then
        common.log:debug("Setting InsideCoveredBedroll to true")
        common.data.insideCoveredBedroll = true
    end
    if data.mesh then
        common.log:debug("mesh: %s, group: %s", data.mesh, data.group)
        startAnimation{ mesh = data.mesh, group = data.group}
    end
    if data.timeScaleMulti or data.deltaMulti  then
        common.log:debug("do fast time")
        startFastTime(data)
    end
    if data.location then
        data.previousLocation = {
            position = tes3.player.position:copy(),
            orientation = tes3.player.orientation:copy(),
            cell = tes3.player.cell
        }
        event.trigger("Ashfall:ToggleTentCollision", {collision = false })
        timer.delayOneFrame(function()
            if not data then
                --may have cancelled immediately
                return
            end
            common.log:debug("found location, moving to %s", data.location.position)
            common.helper.movePlayer(data.location)
        end) 
    end
    if data.recovering then
        common.log:debug("recovering: true")
        local interval = 0.1 --real seconds
        data.lastRecovered = getHoursPassed()
        data.statRecoveryTimer = timer.start{
            duration = interval,
            type = timer.real,
            iterations = -1,
            callback = function()
                local hoursPassed = getHoursPassed()
                data.timeSinceLastRecovered = hoursPassed - data.lastRecovered
                common.helper.recoverStats{ resting = data.sleeping, interval = data.timeSinceLastRecovered }
                data.lastRecovered = hoursPassed
            end
        }
    end

    tes3.setVanityMode({ enabled = true })
    helper.disableControls()
    event.register("save", blockSave)
    event.register("keyUp", onTabUp, { filter = tes3.getInputBinding(tes3.keybind.togglePOV).code })
    event.register("keyDown", checkKeyPress)
    event.register("Ashfall:WakeUp", this.cancel)
    

    if data.sleeping then
        common.log:debug("Enabling isSleeping")
        common.data.isSleeping = true
    else
        common.data.isWaiting = true
    end
end

function this.cancel()
    common.log:debug("Cancelling")
    tes3.runLegacyScript({command = 'DisablePlayerLooking'});
    event.trigger("Ashfall:ToggleTentCollision", {collision = true })
    if data.usingBed then
        event.trigger("Ashfall:SetBedTemp", { isUsingBed = false })
    end
    if data.covered then
        common.log:debug("Setting InsideCoveredBedroll to false")
        common.data.insideCoveredBedroll = false
    end
    if data.mesh then
        common.log:debug("Stopping animation")
        stopAnimation()
    end
    if data.speed then
        common.log:debug("Stopping fast time")
        stopFastTime()
    end
    if data.previousLocation then
        common.log:debug("Returning to previous location")
        common.helper.movePlayer(data.previousLocation)
    end
    if data.recovering then
        common.log:debug("Removing recovery")
        common.data.recoveringFatigue = false
        data.statRecoveryTimer:cancel()
    end
    if data.sleeping then
        common.log:debug("disabling isSleeping")
        common.data.isSleeping = false
    else
        common.data.isWaiting = false
    end
    if data.collisionRef then
        if data.collisionRef and data.collisionRef:valid() then
            common.log:debug("Has Collision Ref, setting hasNoCollision to false")
            data.collisionRef:getObject().hasNoCollision = false
        end
    end
    common.log:debug("Enabling controls and setting vanity to false, unregistering events")
    helper.enableControls()
    tes3.setVanityMode({ enabled = false })
    event.unregister("save", blockSave)
    event.unregister("keyDown", checkKeyPress)
    event.unregister("keyUp", onTabUp, { filter = tes3.getInputBinding(tes3.keybind.togglePOV).code })
    event.unregister("Ashfall:WakeUp", this.cancel)
    
    if data.callback then
        common.log:debug("Callback")
        data.callback()
    end
    data = nil
    tes3.runLegacyScript({command = 'EnablePlayerLooking'});
end



local function buttonPressed(e)
    if e.anim == "sitting" then
        this.sitDown(e)
    elseif e.anim == "layingDown" then
        this.layDown(e)
    else
        this.doAnimation(e)
    end

end
function this.showFastTimeMenu(e)
    if tes3.mobilePlayer.inCombat then
        tes3.messageBox("You are in combat.")
        return
    end
    if not e.speeds then
        this.doAnimation(e)
        return
    end

    local buttons = {
        {
            text = "Real Time",
            callback = function()
                local data = table.copy(e)
                data.timeScaleMulti = 1
                buttonPressed(data)
            end
        }
    }
        
    for _, speed in ipairs(e.speeds)do
        table.insert(buttons, {
            text = string.format("%dx Speed", speed),
            callback = function()
                local data = table.copy(e)
                data.timeScaleMulti = speed
                buttonPressed(data)
            end
        })
    end
    local message = e.message or (e.sleeping and "Resting" or "Waiting" )
    common.helper.messageBox{
        message = message,
        buttons = buttons,
        doesCancel = true,
    }
end

return this