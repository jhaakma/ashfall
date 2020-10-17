local common = require("mer.ashfall.common.common")
local animCtrl = require("mer.ashfall.effects.animationController")
local skipActivate


local function canRest()
    return (
        tes3.canRest() and
        not tes3.player.cell.restingIsIllegal
    )
end

local function doRestMenu()
    common.log:trace("Setting inTent for covered bedroll to true")
    common.data.insideCoveredBedroll = true
    tes3.showRestMenu()
    event.trigger("Ashfall:CheckForShelter")
    event.trigger("Ashfall:UpdateHud")
    timer.delayOneFrame(function()
        common.log:trace("Setting inTent for covered bedroll to false")
        common.data.insideCoveredBedroll = false
    end)
end

local function bedrollMenu(ref)
    local message = ref.object.name
    local buttons = {
        {
            text = "Sleep",
            callback = doRestMenu,
            requirements = canRest,
            tooltipDisabled = { 
                text = tes3.canRest() and "It is illegal to rest here." or "You can't rest here; enemies are nearby."
            },
        },
        {
            text = "Lay Down",
            requirements = canRest,
            showRequirements = function()
                return common.config.getConfig().devFeatures
            end,
            callback = function()
                tes3.positionCell{
                    cell = ref.cell,
                    reference = tes3.player,
                    position = tes3vector3.new(
                        ref.position.x, 
                        ref.position.y,
                        ref.position.z + 20
                    ),
                    orientation = ref.orientation:copy(),
                }
                animCtrl.layDown()
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
        { text = "Cancel", doesCancel = true}
    }
    common.helper.messageBox{
        message = message, 
        buttons = buttons
    }
end


local function activateBedroll(e)
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
        else
            bedrollMenu(e.target)
            return false
        end
    end
end
event.register("activate", activateBedroll)
