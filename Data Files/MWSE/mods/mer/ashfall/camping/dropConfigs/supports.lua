local common = require ("mer.ashfall.common.common")
return {
    dropText = function(campfire, item, itemData)
        return string.format("Attach %s", common.helper.getGenericUtensilName(item))
    end,
    canDrop = function(campfire, item, itemData)
        local canAttachSupports = campfire.sceneNode:getObjectByName("ATTACH_SUPPORTS")
        if not canAttachSupports then
            return false
        end
        local id = item.id:lower()
        local isSupports = common.staticConfigs.supports[id]
        if not isSupports then
            return false
        end
        local hasSupports = campfire.data.supportsId
        if hasSupports then
            return false, "Campfire already has supports."
        end

        return true
    end,
    onDrop = function(campfire, reference)
        local id = reference.object.id:lower()
        --attach supports
        campfire.data.supportsId = id
        local remaining = common.helper.reduceReferenceStack(reference, 1)
        if remaining > 0 then
            common.helper.pickUp(reference)
        end
        tes3.messageBox("Added %s", common.helper.getGenericUtensilName(reference.object))
        event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire})
    end
}