----------------------
--FIREWOOD
----------------------

local common = require ("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local skipActivate
local function pickupFirewood(ref)
    timer.delayOneFrame(function()
        skipActivate = true
        tes3.player:activate(ref)
        skipActivate = false
    end)
end




local function placeCampfire(e)
    --Check how steep the land is
    local maxSteepness = common.staticConfigs.placementConfig.ashfall_firewood.maxSteepness
    local ground = common.helper.getGroundBelowRef({ref = e.target})
    local tooSteep = (
        ground.normal.x > maxSteepness or
        ground.normal.x < -maxSteepness or
        ground.normal.y > maxSteepness or
        ground.normal.y < -maxSteepness
    ) 
    if tooSteep then 
        tes3.messageBox{ message = "The ground is too steep here.", buttons = {tes3.findGMST(tes3.gmst.sOK).value}}
        return
    end

    mwscript.disable({ reference = e.target })

    local campfire = tes3.createReference{
        object = common.staticConfigs.objectIds.campfire,
        position = e.target.position,
        orientation = {
            e.target.orientation.x,
            e.target.orientation.y,
            tes3.player.orientation.z
        },
        scale = 0.8,
        cell = e.target.cell
    }
    common.helper.yeet(e.target)
    campfire:deleteDynamicLightAttachment()
    campfire.data.fuelLevel = e.target.stackSize or 1
end


local function onActivateFirewood(e)
    if not (e.activator == tes3.player) then return end
    if skipActivate then return end
    if tes3.menuMode() then return end
    if string.lower(e.target.object.id) == common.staticConfigs.objectIds.firewood then
        if tes3.player.cell.restingIsIllegal then
            if common.helper.getInside() then
                return
            end
            if not config.canCampInSettlements then
                return
            end
        end
        if common.helper.getRefUnderwater(e.target) then
            return
        end

        common.helper.messageBox({
            message = string.format("You have %d %s.", e.target.stackSize, e.target.object.name),
            buttons = {
                { text = "Create Campfire", callback = function() placeCampfire(e) end },
                { text = "Pick Up", callback = function() pickupFirewood(e.target) end },
            },
            doesCancel = true
        })
        return true
    end
end
event.register("activate", onActivateFirewood )


