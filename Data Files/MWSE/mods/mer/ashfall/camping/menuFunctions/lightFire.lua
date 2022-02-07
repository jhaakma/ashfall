local common = require ("mer.ashfall.common.common")
local DURATION_COST = 10

local function isBlacklisted(e)
    return common.staticConfigs.lightFireBlacklist[e.item.id:lower()] ~= nil
end

local function hasDuration(e)
    return (not e.itemData)
        or e.itemData and e.itemData.timeLeft
        and e.itemData.timeLeft > DURATION_COST
end

local function isLight(e)
    return e.item.objectType == tes3.objectType.light
        and hasDuration(e)
end

local function isFireStarter(e)
    return common.staticConfigs.firestarters[e.item.id:lower()] ~= nil
end


local function filterFireStarter(e)
    if isBlacklisted(e) then
        return false
    end
    return isLight(e) or isFireStarter(e)
end


local menuConfig = {
    text = "Light Fire",
    showRequirements = function(campfire)
        return (
            not campfire.data.isLit and
            campfire.data.fuelLevel and
            campfire.data.fuelLevel > 0.5
        )
    end,
    callback = function(campfire)
        timer.delayOneFrame(function()
            common.log:debug("Opening Inventory Select Menu")
            tes3ui.showInventorySelectMenu{
                title = "Select Firestarter",
                noResultsText = "You do not have anything to light the fire.",
                filter = filterFireStarter,
                callback = function(e)
                    if e.item then
                        common.log:debug("showInventorySelectMenu Callback")
                        event.trigger("Ashfall:fuelConsumer_Alight", { fuelConsumer = campfire, lighterData = e.itemData})
                    end
                end,
            }
        end)
    end,
}

return menuConfig