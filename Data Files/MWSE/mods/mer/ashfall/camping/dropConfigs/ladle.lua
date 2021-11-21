local common = require ("mer.ashfall.common.common")

return {
    dropText = function(campfire, item, itemData)
        return string.format("Add %s", common.helper.getGenericUtensilName(item))
    end,
    canDrop = function(campfire, item, itemData)
        local isLadle = item.id:lower() == "misc_com_iron_ladle"
        local hasLadle = campfire.data.ladle == true
        local hasCookingPot = campfire.data.utensil == "cookingPot"
        return hasCookingPot and not hasLadle and isLadle
    end,
    onDrop = function(campfire, reference)
        campfire.data.ladle = true
        local remaining = common.helper.reduceReferenceStack(reference, 1)
        if remaining > 0 then
            common.helper.pickUp(reference)
        end

        tes3.messageBox("Added %s", common.helper.getGenericUtensilName(reference.object))
        event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire})
    end
}