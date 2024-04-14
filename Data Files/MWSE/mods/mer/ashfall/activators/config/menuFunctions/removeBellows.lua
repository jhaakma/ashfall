local common = require ("mer.ashfall.common.common")

return  {
    text = "Remove Bellows",
    showRequirements = function(reference)

        if not reference.supportsLuaData then return false end
        return not not reference.data.bellowsId
    end,
    tooltip = function()
        return common.helper.showHint(string.format(
            "You can pick this up directly by holding %s and activating.",
            common.helper.getModifierKeyString()
        ))
    end,
    callback = function(reference)
        tes3.addItem{ reference = tes3.player, item = reference.data.bellowsId, playSound = false}
        reference.data.bellowsId = nil
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
        event.trigger("Ashfall:UpdateAttachNodes", { reference = reference})
    end
}