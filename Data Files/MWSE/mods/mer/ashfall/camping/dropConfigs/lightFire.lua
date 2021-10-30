local common = require ("mer.ashfall.common.common")
DURATION_COST = 10
return {
    canDrop = function(campfire, item, itemData)
        local id = item.id:lower()
        local fireLit = campfire.data.isLit
        if not fireLit then
            --Light item with duration
            if item.objectType == tes3.objectType.light then
                local duration = itemData.timeLeft
                if duration and duration > DURATION_COST then
                    return true
                end
            end
            --Flint and Steel
            if common.staticConfigs.firestarters[id] then
                return true
            end
        end
        return false
    end,
    dropText = function(campfire, item, itemData)
        return "Light Fire"
    end,
    onDrop = function(campfire, reference)
        if campfire.data.fuelLevel > 0.5 then
            event.trigger("Ashfall:fuelConsumer_Alight", { fuelConsumer = campfire, lighterData = reference.itemData})
        else
            tes3.messageBox("You need to add more fuel to the campfire before you can light it.")
        end
        common.helper.pickUp(reference)
    end
}