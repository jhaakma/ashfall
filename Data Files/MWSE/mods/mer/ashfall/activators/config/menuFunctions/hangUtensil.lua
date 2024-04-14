local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("hangUtensil")
local CampfireUtil = require ("mer.ashfall.camping.campfire.CampfireUtil")


local function addUtensil(reference, item, campfire, itemData)
    tes3.removeItem{ reference = reference, item = item, itemData = itemData, playSound = false }
    local utensilData = common.staticConfigs.utensils[item.id:lower()]

    --tes3.playSound{ reference = tes3.player, sound = "Item Misc Down"  }

    campfire.data.utensil = utensilData.type
    campfire.data.utensilId = item.id:lower()
    campfire.data.utensilPatinaAmount = itemData and itemData.data.patinaAmount
    campfire.data.waterCapacity = utensilData.capacity or 100
    campfire.data.ladle = itemData and itemData.data.ladle

    if utensilData.type == "cookingPot" and not campfire.data.ladle then
        for ladleId, _ in pairs(common.staticConfigs.ladles) do
            local ladle = tes3.getObject(ladleId)
            if ladle then
                if common.helper.getItemCount{ reference = tes3.player, item = ladle} > 0 then
                    logger:debug("Found ladle in inventory, adding to campfire")
                    common.helper.removeItem{ reference = tes3.player, item = ladleId, playSound = false }
                    campfire.data.ladle = ladleId:lower()
                    break
                end
            end
        end
    end

    --If utensil has water, initialise the campfire with it
    if itemData and itemData.data.waterAmount then
        campfire.data.waterAmount =  itemData.data.waterAmount
        campfire.data.stewLevels =  itemData.data.stewLevels
        campfire.data.stewProgress = itemData.data.stewProgress
        campfire.data.teaProgress = itemData.data.teaProgress
        campfire.data.waterType =  itemData.data.waterType
        campfire.data.waterHeat = itemData.data.waterHeat or 0
        campfire.data.lastWaterUpdated = nil
    end

    logger:debug("Set water capacity to %s", campfire.data.waterCapacity)
    logger:debug("Set water heat to %s", campfire.data.waterHeat)
    logger:debug("Set lastWaterUpdated to %s", campfire.data.lastWaterUpdated)
    event.trigger("Ashfall:registerReference", { reference = campfire})
    event.trigger("Ashfall:UpdateAttachNodes", { reference = campfire})
    --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})

end

local function utensilSelect(campfire)
    timer.delayOneFrame(function()
        common.helper.showInventorySelectMenu{
            title = "Select Utensil",
            noResultsText = "You do not have any utensils.",
            filter = function(e)
                return CampfireUtil.itemCanBeHanged(e.item)
            end,
            callback = function(e)
                if e.item then
                    addUtensil(e.reference, e.item, campfire, e.itemData)
                end
            end
        }
    end)
end

return {
    text = "Hang Utensil",
    showRequirements = function(reference)
        if not reference.supportsLuaData then return false end
        return
            reference.sceneNode:getObjectByName("HANG_UTENSIL")
                and not reference.data.utensil
    end,
    enableRequirements = function()
        for id in pairs(common.staticConfigs.utensils) do
            local utensil = tes3.getObject(id)
            if utensil then
                if common.helper.getItemCount{ reference = tes3.player, item = utensil} > 0 then
                    return true
                end
            end
        end
        return false
    end,
    tooltip = function()
        return common.helper.showHint("You can hang a utensil by dropping it directly onto the supports.")
    end,
    tooltipDisabled = {
        text = "You don't have any suitable utensils."
    },
    callback = utensilSelect
}