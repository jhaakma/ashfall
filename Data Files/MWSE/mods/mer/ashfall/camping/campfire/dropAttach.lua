--[[
    Controller for dropping items onto a campfire
    Examples include dropping firewood to increase fuel, adding ingredients to stews etc
]]
local CampfireUtil = require "mer.ashfall.camping.campfire.CampfireUtil"
local activatorController = require "mer.ashfall.activators.activatorController"
local common = require("mer.ashfall.common.common")
local logger = common.createLogger("dropAttach")

local function onDrop(e)
    logger:debug("item dropped: %s", e.reference.object.id)
    local target = activatorController.currentRef
    local droppedRef = e.reference

    if not target then
        logger:debug("no target!")
        return
    end
    local node = activatorController.parentNode
    local dropConfig = CampfireUtil.getDropConfig(target, node)

    logger:debug("CurrentRef: %s", target.object.id)

    if not dropConfig then
        logger:debug("No drop config for %s", target.object.id)
        return
    end
    logger:debug("Drop config found")
    for _, optionId in ipairs(dropConfig) do
        logger:debug("optionId: %s", optionId)
        local option = require('mer.ashfall.camping.dropConfigs.' .. optionId)
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
