--[[
    Adds functionality for a custom wait menu. Instead of fading out 
    like the vanilla wait menu, it instead goes into vanity/3rd person
    camera mode and speeds up time. Can wait for up to one hour in this mode. 

]]


local this = {}
local common = require("mer.ashfall.common.common")
local currentSpeed = 1

local DELTA_MIN = 2.0
local DELTA_MAX = 2.5
local TIMESCALE_MIN = 30
local TIMESCALE_MAX = 150

local originalTimeScale
local cancelTimer
local function cancelWait()
    if currentSpeed ~= 1 then
        tes3.runLegacyScript({command = "TVM"})
        tes3.mobilePlayer.controlsDisabled = false
        tes3.mobilePlayer.mouseLookDisabled = false
        currentSpeed = 1
        tes3.findGlobal("TimeScale").value = originalTimeScale
    end
end

local function updateDelta(e)
    if currentSpeed ~= 1 then
        tes3.worldController.deltaTime = e.delta * currentSpeed
    end
end
event.register("enterFrame", updateDelta)


local function checkKeyPress()
    if currentSpeed ~= 1 then
        cancelWait()
        cancelTimer:cancel()
    end
end
event.register("keyDown", checkKeyPress)


local function startFastTime(durationMinutes, newSpeed)
    local timeScale = tes3.findGlobal("TimeScale")
    if newSpeed == 1 then
        newSpeed = 1.1
    end

    tes3.runLegacyScript({command = "TVM"})
    tes3.mobilePlayer.controlsDisabled = true
    tes3.mobilePlayer.mouseLookDisabled = true
    if newSpeed then
        currentSpeed = newSpeed
    else
        currentSpeed = math.remap(durationMinutes, 1, 60, DELTA_MIN, DELTA_MAX)
    end
    originalTimeScale = timeScale.value
    timeScale.value = math.remap(durationMinutes, 1, 60, TIMESCALE_MIN, TIMESCALE_MAX)
    cancelTimer = timer.start({
        type = timer.game,
        duration = durationMinutes / 60,
        callback = function()
            cancelWait()
        end
    })
end


local waitValHolder = { minutesToWait = 30 }
function this.showFastTimeMenu()
    if tes3.mobilePlayer.inCombat then
        tes3.messageBox("You are in combat.")
    else
        common.helper.createSliderPopup{
            label = "Wait for: %s minutes",
            min = 1,
            max = 60,
            varId = "minutesToWait",
            table = waitValHolder,
            okayCallback = function()
                startFastTime(waitValHolder.minutesToWait)
            end
        }
    end

end

return this