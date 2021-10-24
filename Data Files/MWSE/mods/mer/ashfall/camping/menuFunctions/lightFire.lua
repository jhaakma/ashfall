local common = require ("mer.ashfall.common.common")
local skillSurvivalLightFireIncrement = 5

local function lightFire(campfire)
    tes3.playSound{ reference = tes3.player, sound = "ashfall_light_fire"  }
    common.log:debug("Lighting Fire %s", campfire.object.id)
    tes3.playSound{ sound = "Fire", reference = campfire, loop = true }
    event.trigger("Ashfall:Campfire_Enablelight", { campfire = campfire})
    campfire.data.fuelLevel = campfire.data.fuelLevel - 0.5
    common.skills.survival:progressSkill( skillSurvivalLightFireIncrement)
    campfire.data.isLit = true
    event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, nodes = true, fire = true, lighting = true})
end

local function reduceLightTime(itemData)
    itemData.timeLeft = math.max(0, itemData.timeLeft - 10)
end

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
                        lightFire(campfire)
                        if isLight(e.item) then
                            reduceLightTime(e.itemData)
                        end
                    end
                end,
            }
        end)
    end,
    dropText = function(item, itemData)
        --Lights for lighting
        if item.objectType == tes3.objectType.light then
            local duration = itemData and itemData.timeLeft
            if duration and duration > 10 then
                return "Light Fire"
            end
        end
        --Firestarters for lighting
        if common.staticConfigs.firestarters[item.id:lower()] then
            return "Light Fire"
        end
    end
}

return menuConfig