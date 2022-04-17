local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("hangUtensil")
local CampfireUtil = require ("mer.ashfall.camping.campfire.CampfireUtil")

local function addUtensil(item, campfire, itemData)
    tes3.removeItem{ reference = tes3.player, item = item, itemData = itemData, playSound = false }
    local utensilData = common.staticConfigs.utensils[item.id:lower()]

    --tes3.playSound{ reference = tes3.player, sound = "Item Misc Down"  }


    campfire.data.utensil = utensilData.type
    campfire.data.utensilId = item.id:lower()
    campfire.data.utensilPatinaAmount = itemData and itemData.data.patinaAmount
    campfire.data.waterCapacity = utensilData.capacity or 100
    campfire.data.ladle = itemData and itemData.data.ladle

    if utensilData.type == "cookingPot" and not campfire.data.ladle then
        for ladleId, _ in pairs(common.staticConfigs.ladles) do
            if tes3.getObject(ladleId) then
                if tes3.getItemCount{ reference = tes3.player, item = ladleId} > 0 then
                    logger:debug("Found ladle in inventory, adding to campfire")
                    tes3.removeItem{ reference = tes3.player, item = ladleId, playSound = false }
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
    event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire})
    --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})

end

local function utensilSelect(campfire)
    timer.delayOneFrame(function()
        tes3ui.showInventorySelectMenu{
            title = "Select Utensil",
            noResultsText = "You do not have any utensils.",
            filter = function(e)
                return CampfireUtil.itemCanBeHanged(e.item) ~= nil
            end,
            callback = function(e)
                if e.item then
                    addUtensil(e.item, campfire, e.itemData)
                end
            end
        }
    end)
end

return {
    text = "Hang Utensil",
    showRequirements = function(campfire)
        return
            campfire.sceneNode:getObjectByName("HANG_UTENSIL")
            and not campfire.data.utensil
    end,
    enableRequirements = function()
        for stack in tes3.iterate(tes3.player.object.inventory.iterator) do
            if common.staticConfigs.utensils[stack.object.id:lower()] then
                if CampfireUtil.itemCanBeHanged(stack.object) then
                    return true
                end
            end
        end
        return false
    end,
    tooltipDisabled = {
        text = "You don't have any suitable utensils."
    },
    callback = utensilSelect
}