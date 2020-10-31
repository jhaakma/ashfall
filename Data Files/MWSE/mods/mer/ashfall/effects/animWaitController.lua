local helper = require("mer.ashfall.common.helperFunctions")
local log = require("mer.ashfall.common.logger")
local common = require("mer.ashfall.common.common")

local DELTA_MIN = 2.0
local DELTA_MAX = 2.5
local TIMESCALE_MIN = 30
local TIMESCALE_MAX = 150
local cancelTimer
local currentSpeed = 1
local originalTimeScale

local function hasAnimFile(animFile)
    local fileToCheck = animFile
    local path = lfs.currentdir() .. "\\Data Files\\meshes\\" .. fileToCheck
    local fileExists = lfs.attributes(path, "mode") == "file"
    return fileExists
end

local function doAnimation(anim)
    if not hasAnimFile(anim.mesh) then
        log:error("missing animation files")
        return
    end
    tes3.player.data.Ashfall.previousAnimationMesh = tes3.player.mesh
    tes3.playAnimation({
        reference = tes3.player,
        mesh = anim.mesh,
        group = anim.group,
        startFlag = 1
    })
end

local function updateDelta(e)
    tes3.worldController.deltaTime = e.delta * currentSpeed
end

local function cancel()
    cancelTimer:cancel()
    event.unregister("enterFrame", updateDelta)
    tes3.findGlobal("TimeScale").value = originalTimeScale
end


local function doAnimWait(e)
    local minutes = e.minutes --optional, if set wait this many minutes
    local anim = e.anim --{ group, mesh } optional, if set play this animation
    local location = e.location --optional, if set move here during animation
    local doRecover = e.doRecover --optional, recover fatigue while waiting

    if anim then
        doAnimation(anim)
    end

    if minutes then
        local timeScale = tes3.findGlobal("TimeScale")
        originalTimeScale = timeScale.value
        currentSpeed = math.remap(minutes, 1, 60, DELTA_MIN, DELTA_MAX)
        cancelTimer = timer.start{
            type = timer.game,
            duration = minutes / 60,
            iterations = 1,
            callback = cancel
        }
        event.register("enterFrame", updateDelta)
    end
end

event.register("Ashfall:AnimWait", doAnimWait)