local common = require ("mer.ashfall.common.common")
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")
------------------
--Tooltips
-----------------
function CampfireUtil.addExtraTooltip(attachmentConfig, campfire, tooltip)
    if attachmentConfig.tooltipExtra then
        attachmentConfig.tooltipExtra(campfire, tooltip)
    end
end


local previousParentNode
local function updateTooltip(e)
    common.log:trace("Campfire tooltip")

    local label = e.label
    local labelBorder = e.element
    local campfire = e.reference
    local parentNode = e.parentNode
    local attachmentConfig = CampfireUtil.getAttachmentConfig(parentNode)
    if attachmentConfig and e.reference then
        CampfireUtil.addExtraTooltip(attachmentConfig, campfire, labelBorder)
        label.text = CampfireUtil.getAttachmentName(campfire, attachmentConfig) or label.text
    end

    local cursor = tes3ui.findHelpLayerMenu("CursorIcon")
    if cursor then
        local tile = cursor and cursor:getPropertyObject("MenuInventory_Thing", "tes3inventoryTile")
        if tile then
            -- local dropConfig = CampfireUtil.getDropConfig(parentNode)
            -- if not dropConfig then return end
            local dropText =  CampfireUtil.getDropText(parentNode, campfire, tile.item, tile.itemData)
            if dropText then
                local element = labelBorder:createLabel{ text = dropText }
                element.autoHeight = true
                element.autoWidth = true
                element.wrapText = true
                element.justifyText = "center"
                element.color = tes3ui.getPalette("active_color")
            end
        end
    end
end

event.register("Ashfall:Activator_tooltip", updateTooltip)