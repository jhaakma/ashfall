--TODO
local common = require ("mer.ashfall.common.common")
return {
    dropText = function(campfire, item, data)
        if campfire.data.isLit then
            if itemData and itemData.data.teaProgress and itemData.data.teaProgress > 0 then
                return "Heat Tea"
            else
                return "Heat Water"
            end
        end
    end,
    canDrop = function(ref, item, itemData)
        if common.helper.isModifierKeyPressed() then return false end
        local isUtensil = common.staticConfigs.utensils[item.id:lower()]
        if not isUtensil then
            return false
        end
        local hasWater = itemData
        and itemData.data.waterAmount
        and itemData.data.waterAmount > 0
        if not hasWater then
            return false
        end

        return true
    end,

}