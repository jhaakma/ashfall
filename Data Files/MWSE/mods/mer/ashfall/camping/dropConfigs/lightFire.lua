local common = require ("mer.ashfall.common.common")
local DURATION_COST = 10
return {
    dropText = function(campfire, item, itemData)
        return "Light Fire"
    end,
    canDrop = function(campfire, item, itemData)
        local id = item.id:lower()

        local isLightWithDuration = item.objectType == tes3.objectType.light
            and itemData and itemData.timeLeft
        if isLightWithDuration then
            if itemData.timeLeft < DURATION_COST then
                return false, "Not enough time left on light."
            end
        end

        local isFlintAndSteel = common.staticConfigs.firestarters[id] ~= nil
        if not (isLightWithDuration or isFlintAndSteel) then
            return false
        end

        local fireLit = campfire.data.isLit
        if  fireLit then
            return false, "Campfire is already lit."
        end
        return true
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