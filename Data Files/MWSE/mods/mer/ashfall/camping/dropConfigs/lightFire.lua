local common = require ("mer.ashfall.common.common")
local DURATION_COST = 10

local function isBlacklisted(e)
    return common.staticConfigs.lightFireBlacklist[e.item.id:lower()] ~= nil
end

local function hasDuration(e)
    return e.itemData and e.itemData.timeLeft
        and e.itemData.timeLeft > DURATION_COST
end

local function isLight(e)
    return e.item.objectType == tes3.objectType.light
end

local function isFireStarter(e)
    return common.staticConfigs.firestarters[e.item.id:lower()] ~= nil
end


return {
    dropText = function(campfire, item, itemData)
        return "Light Fire"
    end,
    canDrop = function(campfire, item, itemData)
        local id = item.id:lower()
        local e = {
            item = item,
            itemData = itemData,
        }

        if isBlacklisted{ item = item, itemData = itemData } then
            return false
        end

        local fireLit = campfire.data.isLit

        if isLight(e) then
            if not hasDuration(e) then
                return false, "Not enough time left on light."
            end
            if fireLit then
                return false, "Campfire is already lit."
            end
            return true
        end

        if isFireStarter(e) then
            if fireLit then
                return false, "Campfire is already lit."
            end
            return true
        end

        return false
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