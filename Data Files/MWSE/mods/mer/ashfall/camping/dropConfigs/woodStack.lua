local common = require ("mer.ashfall.common.common")
local WoodStack = require("mer.ashfall.items.woodStack")
return {
    dropText = function(targetRef, item, itemData)
        return "Add firewood"
    end,
    ---@param targetRef tes3reference
    canDrop = function(targetRef, item, _itemData)

        local hasNodes = targetRef.sceneNode:getObjectByName("DROP_WOODSTACK")
            and targetRef.sceneNode:getObjectByName("SWITCH_WOODSTACK")
        if not hasNodes then
            return false
        end

        local id = item.id:lower()
        local isFirewood = id == common.staticConfigs.objectIds.firewood

        if not isFirewood then
            return false
        end
        local hasRoom = (not targetRef.data.woodAmount)
            or ( targetRef.data.woodAmount < WoodStack.getCapacity(targetRef.object.id) )
        if not hasRoom then
            return false, string.format("Wood Stack is full.")
        end
        return true
    end,
    onDrop = function(targetRef, reference)

        local stackCount = common.helper.getStackCount(reference)

        targetRef.data.woodAmount = targetRef.data.woodAmount or 0
        local currentCapacity = WoodStack.getCapacity(targetRef.object.id) - targetRef.data.woodAmount

        local woodAdded = math.min(stackCount,currentCapacity)
        local woodRemaining = stackCount - woodAdded

        targetRef.data.woodAmount = targetRef.data.woodAmount + woodAdded
        if woodRemaining == 0 then
            common.helper.yeet(reference)
            tes3.playSound{ reference = tes3.player, sound = "ashfall_add_wood"  }
        else
            reference.attachments.variables.count = reference.attachments.variables.count - woodAdded
            common.helper.pickUp(reference)
            tes3.playSound{ reference = tes3.player, sound = "ashfall_add_wood"  }
        end
        tes3.messageBox("Added firewood.")
        targetRef.data.burned = targetRef.data.isLit == true
        event.trigger("Ashfall:UpdateAttachNodes", { campfire = targetRef})
    end
}