local helper = require("mer.ashfall.common.helperFunctions")
local this = {}
local nifName = "VA_sitting.nif"

function this.hasAnimFiles()
    local path = lfs.currentdir() .. "\\Data Files\\meshes\\" .. nifName
    local fileExists = lfs.attributes(path, "mode") == "file"
    return fileExists
end

local anims = {
    sitForward = tes3.animationGroup.idle5,
    sitCrossed = tes3.animationGroup.idle4,
    sitSide = tes3.animationGroup.idle3,
    layDownLeft = tes3.animationGroup.idle7,
    layDownRight = tes3.animationGroup.idle8,
    layDownBack = tes3.animationGroup.idle9
}

local function doAnimation(animGroup)
    if not this.hasAnimFiles() then
        error("[Ashfall] ERROR - missing animation files")
    end
    tes3.player.data.Ashfall.previousAnimationMesh = tes3.player.mesh
    tes3.playAnimation({
        reference = tes3.player,
        mesh = nifName,
        group = animGroup,
        startFlag = 1
    })
    tes3.setVanityMode({ enabled = true })
    helper.disableControls()

    --handle keypress to cancel animation
    local function checkKeyPress(e)
        if e.keyCode == 183 then return end
        this.cancelAnimation()
        event.unregister("keyDown", checkKeyPress)
    end
    event.register("keyDown", checkKeyPress)
end

function this.sitDown()
    doAnimation(anims.sitForward)
end

function this.layDown()
    doAnimation(anims.layDownBack)
end

function this.cancelAnimation()
    tes3.playAnimation({
        reference = tes3.player,
        mesh = tes3.player.data.Ashfall.previousAnimationMesh,
        group = tes3.animationGroup.idle,
        startFlag = 1
    })
    helper.enableControls()
    tes3.setVanityMode({ enabled = false })
end

return this