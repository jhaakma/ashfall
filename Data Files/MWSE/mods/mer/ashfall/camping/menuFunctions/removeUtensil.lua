local common = require ("mer.ashfall.common.common")
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")

local function isStaticCampfire(campfire)
    return campfire.data.dynamicConfig and campfire.data.dynamicConfig[campfire.data.utensil] == "static"
end

return  {
    text = function(campfire)
        local utensilId = campfire.data.utensilId
        if utensilId then
            common.log:debug("utensilId: %s", utensilId)
            local utensil = tes3.getObject(utensilId)
            return string.format("Remove %s", CampfireUtil.getGenericUtensilName(utensil) or "Utensil")
        end
    end,
    showRequirements = function(campfire)
        if isStaticCampfire(campfire) then
            common.log:debug("It's a static campfire, can not remove")
            return false
        elseif campfire.data.stewLevels then
            return (
                campfire.data.stewProgress and
                campfire.data.stewProgress >= 100
            )
        elseif campfire.data.teaProgress then
            return campfire.data.teaProgress >= 100
        else
            return  campfire.data.utensilId ~= nil
        end
    end,
    -- enableRequirements = function(campfire)

    --     else
    --         return true
    --     end
    -- end,
    -- tooltipDisabled = {
    --     text = "Wait until stew/tea has finished cooking/brewing."
    -- },
    callback = function(campfire)
        --add utensil
        tes3.addItem{
            reference = tes3.player,
            item = campfire.data.utensilId,
            count = 1
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
        end

        --add ladle
        if campfire.data.ladle == true then
            mwscript.addItem{ reference = tes3.player, item = "misc_com_iron_ladle" }
        end
        --clear data and trigger updates
        event.trigger("Ashfall:Campfire_clear_utensils", { campfire = campfire, removeUtensil = true})
        event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire,})
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
    end
}