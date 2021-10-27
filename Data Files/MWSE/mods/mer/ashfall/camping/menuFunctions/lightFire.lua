local common = require ("mer.ashfall.common.common")

local function isLight(item)
    return item.objectType == tes3.objectType.light
end

local function isFireStarter(item)
    return common.staticConfigs.firestarters[item.id:lower()] ~= nil
end

local function filterFireStarter(e)
    return isLight(e.item) or isFireStarter(e.item)
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