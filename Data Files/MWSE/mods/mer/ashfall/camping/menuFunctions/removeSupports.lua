local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("removeSupports")
return {
    text = "Remove Supports",
    showRequirements = function(campfire)
        return (
            campfire.sceneNode:getObjectByName("ATTACH_SUPPORTS")
            and campfire.data.supportsId
            and campfire.data.dynamicConfig
            and campfire.data.dynamicConfig.supports == "dynamic"
        )
    end,
    enableRequirements = function(campfire)
        return campfire.data.utensil == nil
    end,
    tooltipDisabled = {
        text = "Utensil must be removed first."
    },
    tooltip = function()
        return common.helper.showHint(string.format(
            "You can pick this up directly by holding %s and activating.",
            common.helper.getModifierKeyString()
        ))
    end,
    callback = function(campfire)
        local supports = campfire.data.supportsId
        local data = common.staticConfigs.supports[supports:lower()]

        logger:debug("Removing supports %s", supports)
        if data.materials then
            for id, count in pairs(data.materials ) do
                local item = tes3.getObject(id)
                tes3.addItem{ reference = tes3.player, item = item, count = count, playSound = false}
                tes3.messageBox(tes3.findGMST(tes3.gmst.sNotifyMessage61).value, count, item.name)
            end
        else
            tes3.addItem{ reference = tes3.player, item = campfire.data.supportsId, count = 1, playSound = false}
            tes3.messageBox(tes3.findGMST(tes3.gmst.sNotifyMessage61).value, 3, tes3.getObject(campfire.data.supportsId).name)
        end
        campfire.data.supportsId = nil
        common.helper.playDeconstructionSound()
        event.trigger("Ashfall:UpdateAttachNodes", { campfire = campfire})
    end
}