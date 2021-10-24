local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local animCtrl = require("mer.ashfall.effects.animationController")
local skipActivate

local function canRest()
    local allowResting = tes3.canRest{ checkForSolidGround = false } and not tes3.player.cell.restingIsIllegal
    if tes3.player.cell.restingIsIllegal and config.canCampInSettlements then
        allowResting = true
    end
    return allowResting
end

local function doRestMenu(isCoveredBedroll)
    if isCoveredBedroll then
        common.log:debug("Setting inTent for covered bedroll to true")
        common.data.insideCoveredBedroll = true
        event.trigger("Ashfall:SetBedTemp", { isUsingBed = true})
    end
    tes3.showRestMenu{ checkSleepingIllegal = false, resting = canRest(), waiting = not canRest() }
    event.trigger("Ashfall:CheckForShelter")
    event.trigger("Ashfall:UpdateHud")
    timer.delayOneFrame(function()
        common.log:debug("Setting inTent for covered bedroll to false")
        common.data.insideCoveredBedroll = false
        event.trigger("Ashfall:SetBedTemp",  { isUsingBed = false })
    end)
end

local function bedrollMenu(ref)
    local isCoveredBedroll = common.staticConfigs.coveredBedrolls[ref.object.id:lower()]
    local message = ref.object.name
    local buttons = {
        {
            text = "Sleep",
            callback = function()
                doRestMenu(isCoveredBedroll)
            end,
            requirements = canRest,
            tooltipDisabled = {
                text = tes3.canRest{ checkForSolidGround = false } and "It is illegal to rest here." or "You can't rest here; enemies are nearby."
            },
        },
        {
            text = "Lay Down",
            requirements = canRest,
            --showRequirement = function()
            --    return not isCoveredBedroll
            --end,
            callback = function()
                local location
                if isCoveredBedroll then
                    location = {
                        position = tes3vector3.new(
                            ref.position.x,
                            ref.position.y,
                            ref.position.z
                        ),
                        orientation = {
                            0,--ref.orientation.x,
                            0,--ref.orientation.y,
                            ref.orientation.z,
                        },
                        cell = ref.cell
                    }
                else
                    location = {
                        position = tes3vector3.new(
                            ref.position.x,
                            ref.position.y,
                            ref.position.z -- + 12
                        ),
                        orientation = {
                            0,--ref.orientation.x,
                            0,--ref.orientation.y,
                            ref.orientation.z + math.pi,
                        },
                        cell = ref.cell
                    }
                end
                animCtrl.showFastTimeMenu{
                    message = "Lay Down",
                    anim = "layingDown",
                    location = location,
                    recovering = true,
                    sleeping = true,
                    covered = isCoveredBedroll,
                    usingBed = true,
                    speeds = { 5, 10, 20}
                }
            end,
            tooltipDisabled = {
                text = tes3.canRest() and "It is illegal to rest here." or "You can't wait here; enemies are nearby."
            },
        },
        {
            text = "Pick up",
            callback = function()
                timer.delayOneFrame(function()
                    skipActivate = true
                    tes3.player:activate(ref)
                end)
            end
        },
    }
    common.helper.messageBox{
        message = message,
        buttons = buttons,
        doesCancel = true
    }
end


local function activateBedroll(e)
    if not (e.activator == tes3.player) then return end
    --Check if it's a misc tent ref
    if common.staticConfigs.bedrolls[e.target.object.id:lower()] then
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


        bedrollMenu(e.target)
        return false
    end
end
event.register("activate", activateBedroll)
