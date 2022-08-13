local ActivatorController = {}

--[[
    This script determines what static activator is being looked at, and
    creates the tooltip for it.
    Other scripts can see what the player is looking at by checking
    ActivatorController.getCurrentActivator()
]]--
local Activator = require("mer.ashfall.activators.Activator")
local activatorConfig = require("mer.Ashfall.activators.config.activatorConfig")
local config = require("mer.ashfall.config").config
local common = require("mer.ashfall.common.common")
local logger = common.createLogger("activatorController")
local uiCommon = require("mer.ashfall.ui.uiCommon")
local ActivatorMenuConfig = require "mer.ashfall.activators.config.ActivatorMenuConfig"
local DropConfig = require "mer.ashfall.activators.config.DropConfig"
local itemTooltips = require("mer.ashfall.ui.itemTooltips")
ActivatorController.list = activatorConfig.list
ActivatorController.current = nil
ActivatorController.currentRef = nil
ActivatorController.parentNode = nil
ActivatorController.subTypes = {}


function ActivatorController.registerActivator(activator)
    assert(activator.type ~= nil)
    activatorConfig.types[activator.type] = activator.type
    ActivatorController.list[activator.id] = Activator:new(activator)
    ActivatorController.subTypes[activator.id] = activator.id
end

---comment
---@param nodeName string
---@param activatorMenuConfig Ashfall.Activator.ActivatorMenuConfig
function ActivatorController.registerActivationNode(nodeName, activatorMenuConfig)
    ActivatorMenuConfig.nodeMapping[nodeName] = activatorMenuConfig
end

function ActivatorController.getCurrentActivator()
    return ActivatorController.list[ActivatorController.current]
end

---@return tes3reference | nil
function ActivatorController.getCurrentActivatorReference()
    return ActivatorController.currentRef
end

function ActivatorController.getCurrentType()
    local currentActivator = ActivatorController.getCurrentActivator()
    if currentActivator then
        return currentActivator.type
    end
end

function ActivatorController.getRefActivator(reference)
    for _, activator in pairs(ActivatorController.list) do
        if activator:isActivator(reference) then
            logger:trace("Activator: %s", activator.type)
            return activator
        end
    end
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
        local activator = ActivatorController.getRefActivator(reference)
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
        local objId = reference.data[activatorMenuConfig.idPath]
        if objId then
            local obj = tes3.getObject(objId)
            return common.helper.getGenericUtensilName(obj)
        end
    elseif reference.object.name and reference.object.name ~= "" then
        return reference.object.name
    elseif ActivatorController.getRefActivator(reference) then
        return ActivatorController.getRefActivator(reference).name
    end
    --fallback
    return nil
end



local function doActivate()
    return (not tes3.mobilePlayer.werewolf)
        and ActivatorController.current
        and config[ActivatorController.getCurrentActivator().mcmSetting] ~= false
end

local function getActivatorName()
    local activator = ActivatorController.list[ActivatorController.current]
    if activator then
        if activator.name and activator.name ~= "" then
            logger:trace("returning activator name: %s", activator.name)
            return activator.name
        elseif ActivatorController.currentRef then
            logger:trace("returning activator ref name: %s", ActivatorController.currentRef.object.name)
            return ActivatorController.currentRef.object.name
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
        local hasIcon = ActivatorController.currentRef
            and ActivatorController.currentRef.object.icon
            and ActivatorController.currentRef.object.icon ~= ""
        if hasIcon then
            uiCommon.addIconToHeader(ActivatorController.currentRef.object.icon)
        end
        local eventData = {
            parentNode = ActivatorController.parentNode,
            reference = ActivatorController.currentRef
        }
        event.trigger("Ashfall:Activator_tooltip", eventData, {filter = ActivatorController.current })
    else
        uiCommon.disableTooltipMenu()
    end
end


--[[
    Every frame, check whether the player is looking at
    a static activator
]]--
function ActivatorController.callRayTest()
    --if not tes3ui.menuMode() then
        ActivatorController.current = nil
        ActivatorController.currentRef = nil
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
        ActivatorController.currentRef = targetRef
        ActivatorController.parentNode = result.object.parent
        for activatorId, activator in pairs(ActivatorController.list) do
            if activator:isActivator(targetRef) then
                ActivatorController.current = activatorId
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
                ActivatorController.current = "water"
            end
        end
    end

    createActivatorIndicator()
end

--[[
    triggerActivate:
    When player presses the activate key, if they are looking
    at an activator static then fire an event
]]--
function ActivatorController.doTriggerActivate()
    logger:debug("ActivatorController.doTriggerActivate")
    if (not tes3ui.menuMode()) and doActivate() then
        logger:debug("Do activate")
        local currentActivator = ActivatorController.list[ActivatorController.current]
        if currentActivator then
            logger:debug("Current activator: %s", currentActivator.type)
            local eventData = {
                activator = currentActivator,
                ref = ActivatorController.currentRef,
                node = ActivatorController.parentNode
            }
            logger:debug("triggering activator filtering on %s", eventData.activator.type)
            event.trigger("Ashfall:ActivatorActivated", eventData, { filter = eventData.activator.type })
        end
    end
end

return ActivatorController