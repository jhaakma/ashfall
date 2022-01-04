--TODO
local common = require ("mer.ashfall.common.common")
return {
    canDrop = function(ref, item, itemData)
        if common.helper.isModifierKeyPressed() then return end
        local isUtensil = common.staticConfigs.utensils[item.id:lower()]
        local isLit = ref.data.isLit
        local hasWater = itemData
            and itemData.data.waterAmount
            and itemData.data.waterAmount > 0
        return isLit and hasWater and isUtensil
    end,
    dropText = function(_campfire, _item, itemData)
        if itemData and itemData.data.teaProgress and itemData.data.teaProgress > 0 then
            return "Warm Tea"
        else
            return "Warm Water"
        end
    end,
}