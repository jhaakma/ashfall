local common = require ("mer.ashfall.common.common")
return {
    canDrop = function(campfire, item, itemData)
        local id = item.id:lower()
        if not campfire.data.grillId then
            if common.staticConfigs.grills[id] then
                return true
            end
        end
        if not campfire.data.bellowsId then
            if common.staticConfigs.bellows[id] then
                return true
            end
        end
        return false
    end,
    dropText = function(campfire, item, itemData)
        return string.format("Attach %s", common.helper.getGenericUtensilName(item))
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