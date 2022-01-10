local common = require ("mer.ashfall.common.common")
local uiCommon = require("mer.ashfall.ui.uiCommon")
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")

--[[
    Adds additional tooltips based on what node the player is looking at
]]
local function addAdditionalTooltip(e)
    common.log:trace("Campfire tooltip")
    local campfire = e.reference
    local parentNode = e.parentNode
    if campfire then
    local attachmentConfig = CampfireUtil.getAttachmentConfig(campfire, parentNode)
        if attachmentConfig then
            if attachmentConfig.tooltipExtra then
                local tooltipContents = uiCommon.getTooltipContentsBlock()
                attachmentConfig.tooltipExtra(campfire, tooltipContents)
            end

            local newText = CampfireUtil.getAttachmentName(campfire, attachmentConfig)
            if newText then
                uiCommon.updateTooltipHeader(newText)
            end
        end
    end

    local cursor = tes3ui.findHelpLayerMenu("CursorIcon")
    if cursor then
        local tile = cursor
            and cursor:getPropertyObject("MenuInventory_Thing", "tes3inventoryTile")
        if tile and campfire then
            local dropText, hasError =  CampfireUtil.getDropText(parentNode, campfire, tile.item, tile.itemData)
            if dropText then
                uiCommon.addCenterLabel{
                    text = dropText,
                    color = hasError and "negative_color" or "active_color"
                }
            end
        end
    end
end
event.register("Ashfall:Activator_tooltip", addAdditionalTooltip)