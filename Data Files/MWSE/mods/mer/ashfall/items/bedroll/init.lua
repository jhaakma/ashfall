local BedRoll = {}
local common = require("mer.ashfall.common.common")
local logger = common.createLogger("bedroll")
local bedConfig = require("mer.ashfall.items.bedroll.config")
local config = require("mer.ashfall.config").config
local animCtrl = require("mer.ashfall.animation.animationController")
local skipActivate

local function setBedTempValues(ref)
    common.data.currentBedData = bedConfig.beds[ref.object.id:lower()]
    logger:debug("Setting currentBedData to: %s", json.encode(common.data.currentBedData, { indent = true }))
end

local function canRest()
    local allowResting = tes3.canRest{ checkForSolidGround = false } and not tes3.player.cell.restingIsIllegal
    if tes3.player.cell.restingIsIllegal and config.canCampInSettlements then
        allowResting = true
    end
    return allowResting
end

local function doRestMenu(bedRef, isCoveredBedroll)

    if isCoveredBedroll then
        logger:debug("Setting inTent for covered bedroll to true")
        common.data.insideCoveredBedroll = true
        event.trigger("Ashfall:SetBedTemp", { isUsingBed = true})
    end


    tes3.showRestMenu{ checkSleepingIllegal = false, resting = canRest(), waiting = not canRest() }
    event.trigger("Ashfall:CheckForShelter", {reference = bedRef})
    timer.delayOneFrame(function()
        logger:debug("Setting inTent for covered bedroll to false")
        common.data.insideCoveredBedroll = false
        event.trigger("Ashfall:SetBedTemp",  { isUsingBed = false })
    end)
end
event.register("Ashfall:RestMenu", doRestMenu)

---@param ref tes3reference
local function getSleepingLocation(ref)
    local sleepingPositionNode = ref.sceneNode:getObjectByName("SleepingPosition")
    if not sleepingPositionNode then
        return {
            position = ref.position:copy(),
            orientation = ref.orientation:copy(),
            cell = ref.cell
        }
    end
    return {
        position = sleepingPositionNode.worldTransform.translation:copy(),
        orientation = sleepingPositionNode.worldTransform.rotation:copy(),
        cell = ref.cell
    }
end

BedRoll.buttons = {
    sleep = {
        text = "Sleep",
        callback = function(e)
            local ref = e.reference
            local bedData = bedConfig.beds[ref.object.id:lower()]
            local isCovered = bedData and bedData.isCovered
            setBedTempValues(ref)
            doRestMenu(ref, isCovered)
        end,
        enableRequirements = canRest,
        tooltipDisabled = function()
            return {
                text = tes3.canRest{ checkForSolidGround = false } and "It is illegal to rest here." or "You can't rest here; enemies are nearby."
            }
        end,
    },
    layDown = {
        text = "Lay Down",
        enableRequirements = canRest,
        callback = function(e)
            local ref = e.reference
            local bedData = bedConfig.beds[ref.object.id:lower()]
            setBedTempValues(ref)
            local isCovered = bedData and bedData.isCovered
            local location = getSleepingLocation(ref)
            animCtrl.showFastTimeMenu{
                message = "Lay Down",
                anim = "layingDown",
                location = location,
                recovering = true,
                sleeping = true,
                covered = isCovered,
                usingBed = true,
                speeds = { 5, 10, 20}
            }
        end,
        tooltipDisabled = function()
            return {
                text = tes3.canRest{} and "It is illegal to rest here." or "You can't wait here; enemies are nearby."
            }
        end,
    },
    pickUp = {
        text = "Pick up",
        showRequirements = function(e)
            return e.reference.sourceMod == nil
        end,
        callback = function(e)
            local ref = e.reference
            timer.delayOneFrame(function()
                skipActivate = true
                tes3.player:activate(ref)
            end)
        end
    },
}

function BedRoll.bedrollMenu(ref)
    local message = ref.object.name
    local buttons = {
        BedRoll.buttons.sleep,
        BedRoll.buttons.layDown,
        BedRoll.buttons.pickUp
    }

    tes3ui.showMessageMenu{
        message = message,
        buttons = buttons,
        cancels = true,
        callbackParams = { reference = ref }
    }
end

local function activateBedroll(e)
    if not (e.activator == tes3.player) then return end
    --Check if it's a bed
    if bedConfig.beds[e.target.object.id:lower()] ~= nil then
        setBedTempValues(e.target)
        --Skip if picking up
        if skipActivate then
            skipActivate = false
            return
        end
        --Pick up if activating while in inventory
        if tes3ui.menuMode() then
            return
        end
        --Pick up if underwater
        if common.helper.getRefUnderwater(e.target) then
            return
        end
        BedRoll.bedrollMenu(e.target)
        logger:debug("Returning false on activate event")
        return false
    end
end
event.register("activate", activateBedroll)

return BedRoll