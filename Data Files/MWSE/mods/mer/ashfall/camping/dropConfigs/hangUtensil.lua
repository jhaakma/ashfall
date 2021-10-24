local common = require ("mer.ashfall.common.common")

return {
    dropText = function(campfire, item, itemData)
        return string.format("Attach %s", common.helper.getGenericUtensilName(item))
    end,
    canDrop = function(campfire, item, itemData)
        common.log:debug("item: %s", item)
        local isUtensil = common.staticConfigs.utensils[item.id:lower()]
        local campfireHasRoom = not campfire.data.utensilId
        common.log:debug("isUtensil: %s", isUtensil)
        common.log:debug("campfireHasRoom: %s", campfireHasRoom)
        return isUtensil and campfireHasRoom
    end,
    onDrop = function(campfire, reference)
        local utensilData = common.staticConfigs.utensils[reference.object.id:lower()]
        if utensilData.type == "cookingPot" then
            if tes3.getItemCount{ reference = tes3.player, item = "misc_com_iron_ladle"} > 0 then
                tes3.removeItem{ reference = tes3.player, item = "misc_com_iron_ladle", playSound = false }
                campfire.data.ladle = true
            end
        end
        campfire.data.utensil = utensilData.type
        campfire.data.utensilId = reference.object.id:lower()
        campfire.data.utensilPatinaAmount = reference.data and reference.data.patinaAmount
        campfire.data.waterCapacity = utensilData.capacity or 100


        --If utensil has water, initialise the campfire with it
        if reference.data and reference.data.waterAmount then
            campfire.data.waterAmount =  reference.data.waterAmount
            campfire.data.stewLevels =  reference.data.stewLevels
            campfire.data.stewProgress = reference.data.stewProgress
            campfire.data.teaProgress = reference.data.teaProgress
            campfire.data.waterType =  reference.data.waterType
            campfire.data.waterHeat = reference.data.waterHeat or 0
            campfire.data.lastWaterUpdated = nil
        end

        local remaining = common.helper.reduceReferenceStack(reference, 1)
        if remaining > 0 then
            common.helper.pickUp(reference)
        end
        tes3.messageBox("Attached %s", common.helper.getGenericUtensilName(reference.object))

        common.log:debug("Set water capacity to %s", campfire.data.waterCapacity)
        common.log:debug("Set water heat to %s", campfire.data.waterHeat)
        common.log:debug("Set lastWaterUpdated to %s", campfire.data.lastWaterUpdated)
        event.trigger("Ashfall:registerReference", { reference = campfire})
        event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire})
    end
}