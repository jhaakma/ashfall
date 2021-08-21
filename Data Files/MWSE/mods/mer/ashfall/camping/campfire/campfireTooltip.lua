local common = require ("mer.ashfall.common.common")
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")
------------------
--Tooltips
-----------------
local function updateTooltip(e)
    common.log:trace("Campfire tooltip")

    local label = e.label
    local labelBorder = e.element
    local campfire = e.reference
    local parentNode = e.parentNode
    local attachmentConfig = CampfireUtil.getAttachmentConfig(parentNode)
    CampfireUtil.addExtraTooltip(attachmentConfig, campfire, labelBorder)

    label.text = CampfireUtil.getAttachmentName(campfire, attachmentConfig)
end

event.register("Ashfall:Activator_tooltip", updateTooltip, { filter = "campfire" })