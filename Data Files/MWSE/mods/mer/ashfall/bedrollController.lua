local common = require("mer.ashfall.common.common")

local skipActivate


local function canRest()
    return (
        tes3.canRest() and
        not tes3.player.cell.restingIsIllegal
    )
end

local function doRestMenu()
    common.log:debug("Setting inTent for covered bedroll to true")
    common.data.insideCoveredBedroll = true
    tes3.runLegacyScript{ command = "ShowRestMenu"}
    event.trigger("Ashfall:CheckForShelter")
    event.trigger("Ashfall:UpdateHud")
    timer.delayOneFrame(function()
        common.log:debug("Setting inTent for covered bedroll to false")
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
                text = "You can't rest here."
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
