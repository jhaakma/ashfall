local common = require ("mer.ashfall.common.common")
return {
    dropText = function(campfire, item, itemData)
        return string.format("Attach %s", common.helper.getGenericUtensilName(item))
    end,
    canDrop = function(campfire, item, itemData)
        local canAttachGrill = campfire.sceneNode:getObjectByName("ATTACH_GRILL") ~= nil
        local canAttachBellows = campfire.sceneNode:getObjectByName("ATTACH_BELLOWS") ~= nil
        local id = item.id:lower()

        local isGrill = common.staticConfigs.grills[id]
        local isBellows = common.staticConfigs.bellows[id]

        if isGrill then
            if canAttachGrill then
                if campfire.data.grillId then
                    return false, "Campfire already has a grill."
                end
            else
                return false
            end
        elseif isBellows then
            if canAttachBellows then
                if campfire.data.bellowsId then
                    return false, "Campfire already has a bellows."
                end
            else
                return false
            end
        else
            return false
        end
        return true
    end,
    onDrop = function(campfire, reference)
        local id = reference.baseObject.id:lower()
        --Utensil
        if common.staticConfigs.grills[id] then
            --local grillData = common.staticConfigs.grills[item.id:lower()]
            campfire.data.hasGrill = true
            campfire.data.grillId = id
            campfire.data.grillPatinaAmount = reference.data.patinaAmount
        elseif common.staticConfigs.bellows[id] then
            campfire.data.bellowsId = id
        end
        local remaining = common.helper.reduceReferenceStack(reference, 1)
        if remaining > 0 then
            common.helper.pickUp(reference)
        end
        tes3.messageBox("Attached %s", common.helper.getGenericUtensilName(reference.object))
        event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire})
    end
}