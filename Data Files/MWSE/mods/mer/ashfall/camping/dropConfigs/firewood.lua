local common = require ("mer.ashfall.common.common")
return {
    canDrop = function(campfire, item, itemData)
        local id = item.id:lower()
        local isFirewood = id == common.staticConfigs.objectIds.firewood

        local hasRoom = (not campfire.data.fuelLevel)
        or ( campfire.data.fuelLevel < common.staticConfigs.maxWoodInFire )
        if isFirewood and hasRoom then return true end
    end,
    dropText = function(campfire, item, itemData)
        return "Add firewood"
    end,
    onDrop = function(campfire, reference)
        --Firewood
        local function getWoodFuel()
            local survivalEffect = math.min( math.remap(common.skills.survival.value, 0, 100, 1, 1.5), 1.5)
            return common.staticConfigs.firewoodFuelMulti * survivalEffect
        end
        local stackCount = common.helper.getStackCount(reference)

        campfire.data.fuelLevel = campfire.data.fuelLevel or 0
        campfire.data.fuelLevel = campfire.data.fuelLevel + getWoodFuel()
        if stackCount == 1 then
            tes3.messageBox("Added firewood.")
            common.helper.yeet(reference)
            tes3.playSound{ reference = tes3.player, sound = "ashfall_add_wood"  }
        else
            reference.attachments.variables.count = reference.attachments.variables.count - 1
            common.helper.pickUp(reference)
            tes3.messageBox("Added firewood.")
            tes3.playSound{ reference = tes3.player, sound = "ashfall_add_wood"  }
        end

        campfire.data.burned = campfire.data.isLit == true
        event.trigger("Ashfall:UpdateAttachNodes", { campfire = campfire})
    end
}