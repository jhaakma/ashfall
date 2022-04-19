local this = {}

--[[
    This script determines what static activator is being looked at, and
    creates the tooltip for it.
    Other scripts can see what the player is looking at by checking
    this.getCurrentActivator()
]]--

local activatorConfig = require("mer.ashfall.config.staticConfigs").activatorConfig
local config = require("mer.ashfall.config").config
local common = require("mer.ashfall.common.common")
local logger = common.createLogger("activatorController")
local uiCommon = require("mer.ashfall.ui.uiCommon")
this.list = activatorConfig.list
this.current = nil
this.currentRef = nil
this.parentNode = nil

function this.getCurrentActivator()
    return this.list[this.current]
end

---@return tes3reference | nil
function this.getCurrentActivatorReference()
    return this.currentRef
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


local function doActivate()
    return (not tes3.mobilePlayer.werewolf)
        and this.current
        and config[this.getCurrentActivator().mcmSetting] ~= false
end

local function getActivatorName()
    local activator = this.list[this.current]
    if activator then
        if activator.name and activator.name ~= "" then
            logger:trace("returning activator name: %s", activator.name)
            return activator.name
        elseif this.currentRef then
            logger:trace("returning activator ref name: %s", this.currentRef.object.name)
            return this.currentRef.object.name
        else
            logger:trace("No ref found for activator")
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


    --While in the menu, the target is based on cursor position (but only for inventory menu
    --Outside of the menu, the target is based on the player's viewpoint
    if tes3ui.menuMode() then
        local inventory = tes3ui.findMenu("MenuInventory")
        local inventoryVisible = inventory and inventory.visible == true
        if inventoryVisible then
            local cursor = tes3.getCursorPosition()
            local camera = tes3.worldController.worldCamera.camera
            eyePos, eyeVec = camera:windowPointToRay{cursor.x, cursor.y}
        end
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
        logger:debug("triggering activator filtering on %s", eventData.activator.type)
        event.trigger("Ashfall:ActivatorActivated", eventData, { filter = eventData.activator.type })
    end
end

local function onActivateKeyPressed(e)
    if (not tes3ui.menuMode()) and doActivate() then
        doTriggerActivate()
    end
end
event.register("Ashfall:ActivateButtonPressed", onActivateKeyPressed)



return this