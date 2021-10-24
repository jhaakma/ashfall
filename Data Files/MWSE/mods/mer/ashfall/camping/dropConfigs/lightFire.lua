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
        if reference.object.objectType == tes3.objectType.light then
            common.log:debug("Lighting fire")
            reference.itemData.timeLeft = reference.itemData.timeLeft - DURATION_COST
        else
            common.log:debug("Lighting fire with firestarter")
        end

        event.trigger("Ashfall:fuelConsumer_Alight", { fuelConsumer = campfire})
        common.helper.pickUp(reference)
    end
}