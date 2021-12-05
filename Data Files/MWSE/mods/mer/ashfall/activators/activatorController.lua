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
local id_indicator = tes3ui.registerID("Ashfall:activatorTooltip")
local id_label = tes3ui.registerID("Ashfall:activatorTooltipLabel")
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
    element.justifyText = "center"
end

local function doActivate()
    return (
        this.current and
        config[this.getCurrentActivator().mcmSetting] ~= false
    )
end

local function createActivatorIndicator()
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    if menu then
        ---@type tes3uiElement
        local mainBlock = menu:findChild(id_indicator)

        if doActivate() then
            if mainBlock then
                mainBlock:destroy()
            end

            mainBlock = menu:createBlock({id = id_indicator })

            mainBlock.absolutePosAlignX = 0.5
            mainBlock.absolutePosAlignY = 0.03
            mainBlock.autoHeight = true
            mainBlock.autoWidth = true


            local labelBackground = mainBlock:createRect({color = {0, 0, 0}})
            --labelBackground.borderTop = 4
            labelBackground.autoHeight = true
            labelBackground.autoWidth = true

            local labelBorder = labelBackground:createThinBorder({})
            labelBorder.autoHeight = true
            labelBorder.autoWidth = true
            labelBorder.paddingAllSides = 10
            labelBorder.flowDirection = "top_to_bottom"

            local text = this.list[this.current].name or ""
            local label = labelBorder:createLabel{ id=id_label, text = text}
            label.color = tes3ui.getPalette("header_color")
            centerText(label)

            local eventData = {
                label = label,
                parentNode = this.parentNode,
                element = labelBorder,
                reference = this.currentRef
            }
            event.trigger("Ashfall:Activator_tooltip", eventData, {filter = this.current })
            if label.text == "" then
                mainBlock.visible = false
            end
        else
            if mainBlock then
                mainBlock.visible = false
            end
        end
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
    if (not tes3ui.menuMode()) and doActivate() and not isBlocked then

        local eventData = {
            activator = this.list[this.current],
            ref = this.currentRef,
            node = this.parentNode
        }
        common.log:debug("triggering activator filtering on %s", eventData.activator.type)
        event.trigger("Ashfall:ActivatorActivated", eventData, { filter = eventData.activator.type })
    end
end

event.register("Ashfall:ActivateButtonPressed", doTriggerActivate)

return this