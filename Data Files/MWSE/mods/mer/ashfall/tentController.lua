local common = require("mer.ashfall.common.common")

local this = {}
local temperatureController = require("mer.ashfall.temperatureController")
--temperatureController.registerExternalHeatSource{ id = "tentTemp" }
temperatureController.registerBaseTempMultiplier{ id = "tentTempMulti"}
local skipActivate

--When sleeping in a tent, you can't be woken up by creatures
local function calcRestInterrupt(e)
    if common.helper.getInTent()  then
        e.count = 0
    end
end

event.register("calcRestInterrupt", calcRestInterrupt)


local function getPlacementBlocked()
    return (
        tes3.player.cell.restingIsIllegal or
        common.helper.getInside(tes3.player)
    )
end

local function unpackTent(miscRef)
    --Can't unpack in towns/indoors
    if getPlacementBlocked() then
        tes3.messageBox("You can't do that here, resting is illegal.")
        return
    else
        timer.delayOneFrame(function()
            tes3.createReference {
                object = common.helper.getTentActiveFromMisc(miscRef),
                position = {
                    miscRef.position.x,
                    miscRef.position.y,
                    miscRef.position.z - 10,
                },
                orientation = miscRef.orientation:copy(),
                cell = miscRef.cell
            }
        
            tes3.runLegacyScript{ command = 'Player->Drop "ashfall_resetlight" 1'}

            common.helper.yeet(miscRef)
        end) 
    end
end

local function packTent(activeRef)
    timer.delayOneFrame(function()
        -- tes3.createReference {
        --     object = common.helper.getTentMiscFromActive(activeRef),
        --     position = activeRef.position:copy(),
        --     orientation = activeRef.orientation:copy(),
        --     cell = activeRef.cell
        -- }
        -- tes3.runLegacyScript{ command = 'Player->Drop "ashfall_resetlight" 1'}
        mwscript.addItem{
            reference = tes3.player,
            item = common.helper.getTentMiscFromActive(activeRef),
            count =  1
        }
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
        common.helper.yeet(activeRef)
    end)
end


local function packedTentMenu(miscRef)
    local message = miscRef.object.name
    local buttons = {
        {
            text = "Unpack",
            callback = function()
                unpackTent(miscRef)
            end
        },
        {
            text = "Pick Up",
            callback = function()
                timer.delayOneFrame(function()
                    skipActivate = true
                    tes3.player:activate(miscRef)
                end)
            end
        },
        { text = "Do Nothing"}
    }
    common.helper.messageBox{
        message = message, 
        buttons = buttons
    }
end

local function activeTentMenu(activeRef)
    local message = activeRef.object.name
    local buttons = {
        -- { 
        --     text = "Sleep",
        --     callback = callRestMenu
        -- },
        {
            text = "Pack Up",
            callback = function() packTent(activeRef) end
        },
        { text = "Do Nothing"}
    }
    common.helper.messageBox{
        message = message, 
        buttons = buttons
    }
end



local function activateTent(e)
    --Check if it's a misc tent ref
    if common.helper.getTentActiveFromMisc(e.target) then
        --Skip if picking up
        if skipActivate then
            skipActivate = false
            return
        end
        --Pick up if activating while in inventory
        if tes3ui.menuMode() then
            return
        else
            packedTentMenu(e.target)
            return false
        end
    --Check if it's an activator tent ref
    elseif common.helper.getTentMiscFromActive(e.target) then
        activeTentMenu(e.target)
        return false
    end
end
event.register("activate", activateTent)

local tent
local function setTent(e)
    local insideTent = e.insideTent
    if e.tent then tent = e.tent end
    if (not tent) or (not tent.sceneNode) then tent = nil end

    tes3.player.data.Ashfall.tentTempMulti = insideTent and 0.7 or 1.0
    
    if tent then
        local switchNode = tent.sceneNode:getObjectByName("SWITCH_CANVAS")
        if switchNode then
        
            switchNode.switchIndex = insideTent and 1 or 0
        end
    end
end
event.register("Ashfall:SetTent", setTent)

return this
