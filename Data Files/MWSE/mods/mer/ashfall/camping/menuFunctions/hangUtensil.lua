local common = require ("mer.ashfall.common.common")

local function addUtensil(item, campfire, itemData)
    tes3.removeItem{ reference = tes3.player, item = item, itemData = itemData }
    local utensilData = common.staticConfigs.utensils[item.id:lower()]

    tes3.playSound{ reference = tes3.player, sound = "Item Misc Down"  }

    if utensilData.type == "cookingPot" then
        if mwscript.getItemCount{ reference = tes3.player, item = "misc_com_iron_ladle"} > 0 then
            mwscript.removeItem{ reference = tes3.player, item = "misc_com_iron_ladle" }
            campfire.data.ladle = true
        end
    end
    campfire.data.utensil = utensilData.type
    campfire.data.utensilId = item.id:lower()
    campfire.data.utensilPatinaAmount = itemData and itemData.data.patinaAmount
    campfire.data.waterCapacity = utensilData.capacity or 100


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

    common.log:debug("Set water capacity to %s", campfire.data.waterCapacity)
    common.log:debug("Set water heat to %s", campfire.data.waterHeat)
    common.log:debug("Set lastWaterUpdated to %s", campfire.data.lastWaterUpdated)
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
                return common.staticConfigs.utensils[e.item.id:lower()] ~= nil
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
        return (
            campfire.sceneNode:getObjectByName("HANG_UTENSIL") and
            not campfire.data.utensil and
            campfire.data.dynamicConfig and
            (campfire.data.dynamicConfig.kettle == "dynamic"
            or campfire.data.dynamicConfig.cookingPot == "dynamic")
        )
    end,
    enableRequirements = function()
        for id, _ in pairs(common.staticConfigs.utensils) do
            if  mwscript.getItemCount{ reference = tes3.player, item = id} > 0 then
                return true
            end
        end
        return false
    end,
    tooltipDisabled = {
        text = "You don't have any suitable utensils."
    },
    callback = utensilSelect
}