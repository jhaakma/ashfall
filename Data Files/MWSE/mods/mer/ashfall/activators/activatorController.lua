--[[
    DEPRECATED: This file is a compatibility wrapper.
    All functionality has been moved to Activator.lua
    New code should use Activator directly instead of ActivatorController
]]--

local Activator = require("mer.ashfall.activators.Activator")
local activatorConfig = require("mer.ashfall.activators.config.activatorConfig")
local config = require("mer.ashfall.config").config
local common = require("mer.ashfall.common.common")
local logger = common.createLogger("activatorController")
local uiCommon = require("mer.ashfall.ui.uiCommon")
local ActivatorMenuConfig = require "mer.ashfall.activators.config.ActivatorMenuConfig"
local DropConfig = require "mer.ashfall.activators.config.DropConfig"

-- Compatibility wrapper - redirects to Activator
local ActivatorController = setmetatable({}, {
    __index = function(self, key)
        -- Redirect property access to Activator
        if key == "list" then
            return Activator.registeredActivators
        elseif key == "current" then
            return Activator.current
        elseif key == "currentRef" then
            return Activator.currentRef
        elseif key == "parentNode" then
            return Activator.parentNode
        end
        return rawget(self, key)
    end,
    __newindex = function(self, key, value)
        -- Redirect property writes to Activator
        if key == "current" then
            Activator.current = value
        elseif key == "currentRef" then
            Activator.currentRef = value
        elseif key == "parentNode" then
            Activator.parentNode = value
        else
            rawset(self, key, value)
        end
    end
})

--- @deprecated Use Activator.get() instead
function ActivatorController.getActivator(id)
    return Activator.get(id)
end

--- @deprecated Use Activator:new() instead
function ActivatorController.registerActivator(activator)
    assert(activator.id, "Activator must have an id")
    assert(activator.type, "Activator must have a type")
    return Activator:new(activator)
end

---@param nodeName string
---@param activatorMenuConfig Ashfall.Activator.ActivatorMenuConfig
function ActivatorController.registerActivationNode(nodeName, activatorMenuConfig)
    ActivatorMenuConfig.nodeMapping[nodeName] = activatorMenuConfig
end

--- @deprecated Use Activator.getCurrent() instead
function ActivatorController.getCurrentActivator()
    return Activator.getCurrent()
end

--- @deprecated Use Activator.getCurrentReference() instead
---@return tes3reference | nil
function ActivatorController.getCurrentActivatorReference()
    return Activator.getCurrentReference()
end

--- @deprecated Use Activator.getCurrentType() instead
function ActivatorController.getCurrentType()
    return Activator.getCurrentType()
end

--- @deprecated Use Activator.getForReference() instead
function ActivatorController.getRefActivator(reference)
    local activator = Activator.getForReference(reference)
    if activator then
        logger:trace("Activator: %s", activator.type)
    end
    return activator
end

function ActivatorController.getActivatorMenuConfig(reference, node)
    local activatorMenuConfig
    -- Check Nodes
    if node then
        while node.parent do
            if ActivatorMenuConfig.nodeMapping[node.name] then
                activatorMenuConfig = ActivatorMenuConfig.nodeMapping[node.name]
                break
            end
            node = node.parent
        end
    end
    --Check Activator
    if not activatorMenuConfig then
        local activator = Activator.getForReference(reference)
        if activator then
            activatorMenuConfig = activator.menuConfig
        end
    end

    return activatorMenuConfig
end

function ActivatorController.getDropConfig(reference, node)
    --default campfire
    local dropConfig
    while node.parent do
        if DropConfig.node[node.name] then
            dropConfig = DropConfig.node[node.name]
            break
        end
        node = node.parent
    end
    if not dropConfig then
        if common.staticConfigs.bottleList[reference.object.id:lower()] then
            return DropConfig.waterContainer
        end
    end
    return dropConfig
end

function ActivatorController.getDropText(node, reference, item, itemData)
    local dropConfig = ActivatorController.getDropConfig(reference, node)
    if not dropConfig then return end
    for _, optionId in ipairs(dropConfig) do
        local option = require('mer.ashfall.activators.config.dropConfigs.' .. optionId)
        local canDrop, errorMsg = option.canDrop(reference, item, itemData)
        local hasError = (errorMsg ~= nil)
        if canDrop or hasError then
            return option.dropText(reference, item, itemData), hasError
        end
    end
end

function ActivatorController.getAttachmentName(reference, activatorMenuConfig)
    if activatorMenuConfig.name then
        return activatorMenuConfig.name
    elseif activatorMenuConfig.idPath then
        local objId = reference.supportsLuaData and reference.data[activatorMenuConfig.idPath]
        if objId then
            local obj = tes3.getObject(objId)
            return common.helper.getGenericUtensilName(obj)
        end
    elseif reference.object.name and reference.object.name ~= "" then
        return reference.object.name
    else
        local activator = Activator.getForReference(reference)
        if activator then
            return activator.name
        end
    end
    --fallback
    return nil
end

local function doActivate()
    local currentActivator = Activator.getCurrent()
    return (not tes3.mobilePlayer.werewolf)
        and currentActivator
        and config[currentActivator.mcmSetting] ~= false
end

local function getActivatorName()
    local activator = Activator.getCurrent()
    if activator then
        if activator.name and activator.name ~= "" then
            logger:trace("returning activator name: %s", activator.name)
            return activator.name
        elseif Activator.currentRef then
            logger:trace("returning activator ref name: %s", Activator.currentRef.object.name)
            return Activator.currentRef.object.name
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
        local hasIcon = Activator.currentRef
            and Activator.currentRef.object.icon
            and Activator.currentRef.object.icon ~= ""
        if hasIcon then
            uiCommon.addIconToHeader(Activator.currentRef.object.icon)
        end
        local eventData = {
            parentNode = Activator.parentNode,
            reference = Activator.currentRef
        }
        event.trigger("Ashfall:Activator_tooltip", eventData, {filter = Activator.current })
    else
        uiCommon.disableTooltipMenu()
    end
end

--[[
    Every frame, check whether the player is looking at
    a static activator
]]--
local function onIndicator(e)
    if tes3.player.mobile.controlsDisabled then return end
    local eyePos  = tes3.getPlayerEyePosition()
    local eyeVec  = tes3.getPlayerEyeVector()
    local activationDistance = tes3.getPlayerActivationDistance()
    local result = e.rayResult
    Activator.current = nil
    Activator.currentRef = nil
    Activator.parentNode = nil
    if result and result.reference then
        --Look for activators from list
        local targetRef = result.reference
        Activator.currentRef = targetRef
        Activator.parentNode = result.object.parent
        for activatorId, activator in pairs(Activator.registeredActivators) do
            if activator:isActivator(targetRef) then
                Activator.current = activatorId
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
                Activator.current = "water" -- alias for waterDirty
            end
        end
    end
    createActivatorIndicator()
end
event.register("CraftingFramework:StaticActivatorIndicator", onIndicator)

--[[
    triggerActivate:
    When player presses the activate key, if they are looking
    at an activator static then fire an event
]]--
function ActivatorController.doTriggerActivate()
    if not tes3.player then return end
    if tes3.player.mobile.controlsDisabled then return end
    logger:debug("ActivatorController.doTriggerActivate")
    if (not tes3ui.menuMode()) and doActivate() then
        logger:debug("Do activate")
        local currentActivator = Activator.getCurrent()
        if currentActivator then
            logger:debug("Current activator: %s", currentActivator.type)
            local eventData = {
                activator = currentActivator,
                ref = Activator.currentRef,
                node = Activator.parentNode
            }
            logger:debug("triggering activator filtering on %s", eventData.activator.type)
            event.trigger("Ashfall:ActivatorActivated", eventData, { filter = eventData.activator.type })
        end
    end
end

return ActivatorController