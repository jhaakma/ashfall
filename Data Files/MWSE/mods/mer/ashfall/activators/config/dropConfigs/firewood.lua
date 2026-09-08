local common = require ("mer.ashfall.common.common")
local Firewood = require("mer.ashfall.camping.Firewood")

return {
    dropText = function(campfire, item, itemData)
        return "Add firewood"
    end,
    canDrop = function(campfire, item, _itemData)
        local id = item.id:lower()
        local isFirewood = id == common.staticConfigs.objectIds.firewood

        if not isFirewood then
            return false
        end

        local hasRoom = Firewood.canAddFireWoodToCampfire(campfire)
        if not hasRoom then
            return false, "Campfire is full."
        end

        return true
    end,
    onDrop = function(campfire, reference)
        local stackCount = common.helper.getStackCount(reference)
        campfire.data.fuelLevel = campfire.data.fuelLevel or 0
        campfire.data.fuelLevel = campfire.data.fuelLevel + Firewood.getWoodFuel()
        if stackCount == 1 then
            tes3.messageBox("Added firewood.")
            reference:delete()
            tes3.playSound{ reference = tes3.player, sound = "ashfall_add_wood"  }
        else
            reference.attachments.variables.count = reference.attachments.variables.count - 1
            common.helper.pickUp(reference)
            tes3.messageBox("Added firewood.")
            tes3.playSound{ reference = tes3.player, sound = "ashfall_add_wood"  }
        end

        campfire.data.burned = campfire.data.isLit == true
        event.trigger("Ashfall:UpdateAttachNodes", { reference = campfire})
    end
}