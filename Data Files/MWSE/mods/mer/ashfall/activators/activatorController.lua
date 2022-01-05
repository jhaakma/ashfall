local this = {}

--[[
    This script determines what static activator is being looked at, and
    creates the tooltip for it.
    Other scripts can see what the player is looking at by checking
    this.getCurrentActivator()
]]--

local activatorConfig = require("mer.ashfall.config.staticConfigs").activatorConfig
local config = require("mer.ashfall.config.config").config
local common = require("mer.ashfall.common.common")
local uiCommon = require("mer.ashfall.ui.uiCommon")
this.list = activatorConfig.list
this.current = nil
this.currentRef = nil
this.parentNode = nil

function this.getCurrentActivator()
    return this.list[this.current]
end

function this.getCurrentType()
    local currentActivator = this.getCurrentActivator()
    if currentActivator then
        return currentActivator.type
    end
end

function this.getRefActivator(reference)
    for _, activator in pairs(this.list) do
        if activator:isActivator(reference.object.id) then
            return activator
        end
    end
end


--[[
    Create a tooltip when looking at an activator
]]--


function this.getActivatorTooltip()
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    if menu then
        return menu:findChild(id_indicator)
    end
end

local function centerText(element)
    element.autoHeight = true
    element.autoWidth = true
    element.wrapText = true
end

local function doActivate()
    return (not tes3.mobilePlayer.werewolf)
        and this.current
        and config[this.getCurrentActivator().mcmSetting] ~= false
end

local function getActivatorName()
    local activator = this.list[this.current]
    if activator then
        if activator.name and activator.name ~= "" then
            common.log:trace("returning activator name: %s", activator.name)
            return activator.name
        elseif this.currentRef then
            common.log:trace("returning activator ref name: %s", this.currentRef.object.name)
            return this.currentRef.object.name
        else
            common.log:trace("No ref found for activator")
        end
    end
end

local function doShowActivator()
    local helpMenu = tes3ui.findHelpLayerMenu(tes3ui.registerID("HelpMenu"))
    return doActivate() and not ( helpMenu and helpMenu.visible)
end

local function createActivatorIndicator()
    if doShowActivator() then
        local headerText = getActivatorName()
        local tooltipMenu = uiCommon.createOrUpdateTooltipMenu(headerText)
        local hasIcon = this.currentRef
            and this.currentRef.object.icon
            and this.currentRef.object.icon ~= ""
        if hasIcon then
            uiCommon.addIconToHeader(this.currentRef.object.icon)
        end
        local eventData = {
            parentNode = this.parentNode,
            reference = this.currentRef
        }
        event.trigger("Ashfall:Activator_tooltip", eventData, {filter = this.current })
    else
        uiCommon.disableTooltipMenu()
    end
end


--[[
    Every frame, check whether the player is looking at
    a static activator
]]--
function this.callRayTest()
    --if not tes3ui.menuMode() then
        this.current = nil
        this.currentRef = nil
    --end

    local eyePos
    local eyeVec


    --While in the menu, the target is based on cursor position
    --Outside of the menu, the target is based on the player's viewpoint
    if tes3ui.menuMode() then
        local cursor = tes3.getCursorPosition()
        local camera = tes3.worldController.worldCamera.camera
        eyePos, eyeVec = camera:windowPointToRay{cursor.x, cursor.y}
    else
        eyePos = tes3.getPlayerEyePosition()
        eyeVec = tes3.getPlayerEyeVector()
    end

    if not (eyePos or eyeVec) then return end

    local activationDistance = tes3.getPlayerActivationDistance()

    local result = tes3.rayTest{
        position = eyePos,
        direction = eyeVec,
        ignore = { tes3.player },
        maxDistance = activationDistance,
    }

    if result and result.reference then
        --Look for activators from list
        local targetRef = result.reference
        this.currentRef = targetRef
        this.parentNode = result.object.parent
        for activatorId, activator in pairs(this.list) do
            if activator:isActivator(targetRef.object.id) then
                this.current = activatorId
                break
            end
        end
    else
        --Special case for looking at water
        local cell =  tes3.player.cell
        local waterLevel = cell.hasWater and cell.waterLevel
        if waterLevel and eyePos.z > waterLevel then
            local intersection = (result and result.intersection) or (eyePos + eyeVec * activationDistance)
            if waterLevel >= intersection.z then
                this.current = "water"
            end
        end
    end

    createActivatorIndicator()
end

local isBlocked
local function blockScriptedActivate(e)
    isBlocked = e.doBlock
end
event.register("BlockScriptedActivate", blockScriptedActivate)

event.register("loaded", function() isBlocked = false end)
--[[
    triggerActivate:
    When player presses the activate key, if they are looking
    at an activator static then fire an event
]]--
local function doTriggerActivate()
    if this.list[this.current] and not isBlocked then

        local eventData = {
            activator = this.list[this.current],
            ref = this.currentRef,
            node = this.parentNode
        }
        common.log:debug("triggering activator filtering on %s", eventData.activator.type)
        event.trigger("Ashfall:ActivatorActivated", eventData, { filter = eventData.activator.type })
    end
end

local function onActivateKeyPressed(e)
    if (not tes3ui.menuMode()) and doActivate() then
        doTriggerActivate()
    end
end
event.register("Ashfall:ActivateButtonPressed", onActivateKeyPressed)


local function onLeftClickInMenuPressed(e)
    --block if not in menu mode
    if not tes3ui.menuMode() then return end
    --block if holding something
    local cursor = tes3ui.findHelpLayerMenu("CursorIcon")
    if cursor then return end

    --block if not clicking the left button
    if not (e.button == 0) then return end

    --Trigger activate
    timer.frame.delayOneFrame(function()
        --block if another menu is sitting on top
        local topMenu = tes3ui.getMenuOnTop()
        local acceptableMenus = {
            [tes3ui.registerID("MenuMulti")] = true,
            [tes3ui.registerID("MenuStat")] = true,
            [tes3ui.registerID("MenuMagic")] = true,
            [tes3ui.registerID("MenuMap")] = true,
            [tes3ui.registerID("MenuInventory")] = true,
        }
        local topMenuIsAcceptable = acceptableMenus[topMenu.id]
        if not topMenuIsAcceptable then return end
        doTriggerActivate()
    end)
end
--Too buggy
--event.register("mouseButtonUp", onLeftClickInMenuPressed)

return this