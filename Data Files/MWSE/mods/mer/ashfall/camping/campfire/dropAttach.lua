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
    local target = activatorController.currentRef
    local droppedRef = e.reference
    if target then
        common.log:trace("CurrentRef: %s", target.object.id)
        local node = activatorController.parentNode
        local dropConfig = CampfireUtil.getDropConfig(target, node)
        if not dropConfig then
            common.log:debug("No drop config for %s", target.object.id)
            return
        end
        common.log:trace("Drop config found")
        for _, optionId in ipairs(dropConfig) do
            common.log:trace("optionId: %s", optionId)
            local option = require('mer.ashfall.camping.dropConfigs.' .. optionId)
            if option.canDrop(target, droppedRef.object, droppedRef.itemData) then
                common.log:trace("Can drop")
                if option.onDrop then
                    option.onDrop(target, droppedRef)
                end
            else
                common.log:trace("Can't drop")
            end
        end
    end
end
event.register("itemDropped", onDrop)

local function dropWaterOnWaterContainer(e)
    local target = CampfireUtil.getPlacedOnContainer()
    if not target then return end
    local targetisWaterContainer = activatorController.list.waterContainer:isActivator(target.object.id:lower())
    if not targetisWaterContainer then return end --Handled by dropConfig

    local from = LiquidContainer.createFromReference(e.reference)
    local to = LiquidContainer.createFromReference(target)
    if from and to then
        common.log:debug("dropped water on water container")
        local waterAdded
        local errorMsg
        if common.helper.isModifierKeyPressed() then
            --Move water the other direction if shift is pressed
            waterAdded, errorMsg = to:transferLiquid(from)
        else
            waterAdded, errorMsg = from:transferLiquid(to)
        end
        if waterAdded <= 0 then
            tes3.messageBox(errorMsg or "Unable to transfer liquid.")
        end
        common.helper.pickUp(e.reference)
    end
end
event.register("itemDropped", dropWaterOnWaterContainer)