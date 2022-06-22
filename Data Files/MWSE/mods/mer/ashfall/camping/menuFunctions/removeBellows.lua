local common = require ("mer.ashfall.common.common")

return  {
    text = "Remove Bellows",
    showRequirements = function(campfire)
        return not not campfire.data.bellowsId
    end,
    tooltip = function()
        return common.helper.showHint(string.format(
            "You can pick this up directly by holding %s and activating.",
            common.helper.getModifierKeyString()
        ))
    end,
    callback = function(campfire)
        tes3.addItem{ reference = tes3.player, item = campfire.data.bellowsId, playSound = false}
        campfire.data.bellowsId = nil
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
        event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire})
    end
}