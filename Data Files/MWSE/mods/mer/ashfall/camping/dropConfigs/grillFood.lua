--TODO
local common = require ("mer.ashfall.common.common")
return {
    canDrop = function(ref, item, itemData)
        local isLit = ref.data.isLit
        local isGrillable = common.staticConfigs.foodConfig.getGrillValues(item)
        local isBurnt = itemData
            and itemData.data.grillState == "burnt"
        return isLit and isGrillable and not isBurnt
    end,
    dropText = function(_campfire, item, itemData)
        return string.format("Cook %s", item.name)
    end,
}