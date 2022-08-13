local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("ActivatorTooltip")
local uiCommon = require("mer.ashfall.ui.uiCommon")
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")
local ActivatorController = require "mer.ashfall.activators.activatorController"
--[[
    Adds additional tooltips based on what node the player is looking at
]]
local function addAdditionalTooltip(e)
    logger:trace("Activator tooltip")
    local reference = e.reference
    local parentNode = e.parentNode
    if reference then
        local activatorMenuConfig = ActivatorController.getActivatorMenuConfig(reference, parentNode)
        if activatorMenuConfig then
            logger:trace("Found attachment config: %s", activatorMenuConfig.name)
            if activatorMenuConfig.tooltipExtra then
                local tooltipContents = uiCommon.getTooltipContentsBlock()
                activatorMenuConfig.tooltipExtra(reference, tooltipContents)
            end

            local newText = ActivatorController.getAttachmentName(reference, activatorMenuConfig)
            if newText then
                uiCommon.updateTooltipHeader(newText)
            end
        end
    end
    local cursor = tes3ui.findHelpLayerMenu("CursorIcon")
    if cursor then
        logger:trace("Cursor")
        local tile = cursor
            and cursor:getPropertyObject("MenuInventory_Thing", "tes3inventoryTile")
        if tile and e.reference then
            local dropText, hasError =  ActivatorController.getDropText(parentNode, e.reference, tile.item, tile.itemData)
            if dropText then
                logger:trace("Adding drop text")
                uiCommon.addCenterLabel{
                    text = dropText,
                    color = hasError and "negative_color" or "active_color",
                }
            end
        end
    end
end
event.register("Ashfall:Activator_tooltip", addAdditionalTooltip)
