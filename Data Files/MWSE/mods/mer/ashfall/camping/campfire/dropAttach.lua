--[[
    Controller for dropping items onto a campfire
    Examples include dropping firewood to increase fuel, adding ingredients to stews etc
]]
local CampfireUtil = require "mer.ashfall.camping.campfire.CampfireUtil"
local activatorController = require "mer.ashfall.activators.activatorController"
local LiquidContainer = require "mer.ashfall.objects.LiquidContainer"
local dropTea = require("mer.ashfall.camping.dropConfigs.tea")
local dropIngredient = require("mer.ashfall.camping.dropConfigs.ingredient")
local dropLadle = require("mer.ashfall.camping.dropConfigs.ladle")
local common = require("mer.ashfall.common.common")

local function onDrop(e)
    common.log:debug("item dropped: %s", e.reference.object.id)
    local target = activatorController.currentRef
    local droppedRef = e.reference

    if not target then
        common.log:debug("no target!")
        return
    end
    local node = activatorController.parentNode
    local dropConfig = CampfireUtil.getDropConfig(target, node)

    common.log:debug("CurrentRef: %s", target.object.id)

    if not dropConfig then
        common.log:debug("No drop config for %s", target.object.id)
        return
    end
    common.log:debug("Drop config found")
    for _, optionId in ipairs(dropConfig) do
        common.log:debug("optionId: %s", optionId)
        local option = require('mer.ashfall.camping.dropConfigs.' .. optionId)
        local canDrop, errorMsg = option.canDrop(target, droppedRef.object, droppedRef.itemData)
        if canDrop then
            common.log:debug("Can drop")
            if option.onDrop then
                option.onDrop(target, droppedRef)
            end
        else
            if errorMsg then
                common.log:debug("Showing can't drop message")
                tes3.messageBox(errorMsg)
                common.helper.pickUp(droppedRef)
            end
            common.log:debug("Can't drop")
        end
    end
end
event.register("itemDropped", onDrop)
