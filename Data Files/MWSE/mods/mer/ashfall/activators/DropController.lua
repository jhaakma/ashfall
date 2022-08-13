--[[
    Controller for dropping items onto a campfire
    Examples include dropping firewood to increase fuel, adding ingredients to stews etc
]]
local ActivatorController = require "mer.ashfall.activators.activatorController"
local common = require("mer.ashfall.common.common")
local logger = common.createLogger("dropAttach")

local function resolveDropOption(dropOption)
    if type(dropOption) == "string" then
        return require('mer.ashfall.activators.config.dropConfigs.' .. dropOption)
    else
        return dropOption
    end
end

local function onDrop(e)
    logger:debug("item dropped: %s", e.reference.object.id)
    local target = ActivatorController.currentRef
    local droppedRef = e.reference

    if not target then
        logger:debug("no target!")
        return
    end
    local node = ActivatorController.parentNode
    local dropConfig = ActivatorController.getDropConfig(target, node)

    logger:debug("CurrentRef: %s", target.object.id)

    if not dropConfig then
        logger:debug("No drop config for %s", target.object.id)
        return
    end
    logger:debug("Drop config found")
    for _, option in ipairs(dropConfig) do
        option = resolveDropOption(option)
        local canDrop, errorMsg = option.canDrop(target, droppedRef.object, droppedRef.itemData)
        if canDrop then
            logger:debug("Can drop")
            if option.onDrop then
                option.onDrop(target, droppedRef)
            end
        else
            if errorMsg then
                logger:debug("Showing can't drop message")
                tes3.messageBox(errorMsg)
                common.helper.pickUp(droppedRef)
            end
            logger:debug("Can't drop")
        end
    end
end
event.register("itemDropped", onDrop)
