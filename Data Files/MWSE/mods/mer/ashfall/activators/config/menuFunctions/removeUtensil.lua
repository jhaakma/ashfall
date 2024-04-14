local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("removeUtensil")

local function isStaticCampfire(campfire)
    return campfire.data.dynamicConfig and campfire.data.dynamicConfig[campfire.data.utensil] == "static"
end

return  {
    text = function(reference)

        if not reference.supportsLuaData then return false end
        local utensilId = reference.data.utensilId
        if utensilId then
            logger:debug("utensilId: %s", utensilId)
            local utensil = tes3.getObject(utensilId)
            return string.format("Remove %s", common.helper.getGenericUtensilName(utensil) or "Utensil")
        end
    end,
    showRequirements = function(reference)
        if isStaticCampfire(reference) then
            logger:debug("It's a static campfire, can not remove")
            return false
        else
            return  reference.data.utensilId ~= nil
        end
    end,
    tooltipDisabled = {
        text = "Cannot remove while stew or tea is in progress."
    },
    tooltip = function()
        return common.helper.showHint(string.format(
            "You can pick this up directly by holding %s and activating.",
            common.helper.getModifierKeyString()
        ))
    end,
    callback = function(reference)
        --add utensil
        tes3.addItem{
            reference = tes3.player,
            item = reference.data.utensilId,
            count = 1,
            playSound = false
        }
        --add patina data
        local itemData
        if reference.data.utensilPatinaAmount then
            itemData = tes3.addItemData{
                to = tes3.player,
                item = reference.data.utensilId,
            }
            itemData.data.patinaAmount = reference.data.utensilPatinaAmount
        end

        --If reference has water, initialise the bottle with it
        if reference.data.waterAmount then
            itemData = itemData or tes3.addItemData{
                to = tes3.player,
                item = reference.data.utensilId,
            }
            itemData.data.waterAmount = reference.data.waterAmount
            itemData.data.stewLevels = reference.data.stewLevels
            itemData.data.stewProgress = reference.data.stewProgress
            itemData.data.teaProgress = reference.data.teaProgress
            itemData.data.waterType = reference.data.waterType
            itemData.data.waterHeat = reference.data.waterHeat
            itemData.data.lastWaterUpdated = reference.data.lastWaterUpdated
            itemData.data.lastBrewUpdated = reference.data.lastBrewUpdated
            itemData.data.lastStewUpdated = reference.data.lastStewUpdated
        end
        if reference.data.ladle then
            itemData = itemData or tes3.addItemData{
                to = tes3.player,
                item = reference.data.utensilId,
            }
            itemData.data.ladle = reference.data.ladle
        end
        --clear data and trigger updates
        event.trigger("Ashfall:Campfire_clear_utensils", { campfire = reference, removeUtensil = true})
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Up" }
    end
}