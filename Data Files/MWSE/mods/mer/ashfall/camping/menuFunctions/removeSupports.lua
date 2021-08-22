local common = require ("mer.ashfall.common.common")
return {
    text = "Remove Supports",
    showRequirements = function(campfire)
        return campfire.data.dynamicConfig
            and campfire.data.dynamicConfig.supports == "dynamic"
            and campfire.data.supportsId
    end,
    enableRequirements = function(campfire)
        return campfire.data.utensil == nil
    end,
    tooltipDisabled = {
        text = "Utensil must be removed first."
    },
    callback = function(campfire)
        local supports = campfire.data.supportsId
        local data = common.staticConfigs.supports[supports:lower()]

        common.log:debug("Removing supports %s", supports)
        if data.materials then
            for id, count in pairs(data.materials ) do
                local item = tes3.getObject(id)
                tes3.addItem{ reference = tes3.player, item = item, count = count}
                tes3.messageBox(tes3.findGMST(tes3.gmst.sNotifyMessage61).value, 3, item.name)
            end
        else
            tes3.addItem{ reference = tes3.player, item = campfire.data.supportsId, count = 1}
            tes3.messageBox(tes3.findGMST(tes3.gmst.sNotifyMessage61).value, 3, tes3.getObject(campfire.data.supportsId).name)
        end
        campfire.data.supportsId = nil
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }

        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
        event.trigger("Ashfall:UpdateAttachNodes", { campfire = campfire})
    end
}