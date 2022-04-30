local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("removeUtensil")

local function isStaticCampfire(campfire)
    return campfire.data.dynamicConfig and campfire.data.dynamicConfig[campfire.data.utensil] == "static"
end

return  {
    text = function(campfire)
        local utensilId = campfire.data.utensilId
        if utensilId then
            logger:debug("utensilId: %s", utensilId)
            local utensil = tes3.getObject(utensilId)
            return string.format("Remove %s", common.helper.getGenericUtensilName(utensil) or "Utensil")
        end
    end,
    showRequirements = function(campfire)
        if isStaticCampfire(campfire) then
            logger:debug("It's a static campfire, can not remove")
            return false
        else
            return  campfire.data.utensilId ~= nil
        end
    end,
    tooltipDisabled = {
        text = "Cannot remove while stew or tea is in progress."
    },
    callback = function(campfire)
        --add utensil
        tes3.addItem{
            reference = tes3.player,
            item = campfire.data.utensilId,
            count = 1,
            playSound = false
        }
        --add patina data
        local itemData
        if campfire.data.utensilPatinaAmount then
            itemData = tes3.addItemData{
                to = tes3.player,
                item = campfire.data.utensilId,
            }
            itemData.data.patinaAmount = campfire.data.utensilPatinaAmount
        end

        --If campfire has water, initialise the bottle with it
        if campfire.data.waterAmount then
            itemData = itemData or tes3.addItemData{
                to = tes3.player,
                item = campfire.data.utensilId,
            }
            itemData.data.waterAmount = campfire.data.waterAmount
            itemData.data.stewLevels = campfire.data.stewLevels
            itemData.data.stewProgress = campfire.data.stewProgress
            itemData.data.teaProgress = campfire.data.teaProgress
            itemData.data.waterType = campfire.data.waterType
            itemData.data.waterHeat = campfire.data.waterHeat
            itemData.data.lastWaterUpdated = campfire.data.lastWaterUpdated
            itemData.data.lastBrewUpdated = campfire.data.lastBrewUpdated
            itemData.data.lastStewUpdated = campfire.data.lastStewUpdated
        end
        if campfire.data.ladle then
            itemData = itemData or tes3.addItemData{
                to = tes3.player,
                item = campfire.data.utensilId,
            }
            itemData.data.ladle = campfire.data.ladle
        end
        --clear data and trigger updates
        event.trigger("Ashfall:Campfire_clear_utensils", { campfire = campfire, removeUtensil = true})


        tes3.playSound{ reference = tes3.player, sound = "Item Misc Up" }

    end
}