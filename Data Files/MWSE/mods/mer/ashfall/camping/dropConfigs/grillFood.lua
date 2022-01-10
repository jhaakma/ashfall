--TODO
local common = require ("mer.ashfall.common.common")
return {
    dropText = function(campfire, item, itemData)
        return string.format("Cook %s", item.name)
    end,
    canDrop = function(ref, item, itemData)
        --grillable?
        local isGrillable = common.staticConfigs.foodConfig.getGrillValues(item)
        if not isGrillable then
            return false
        end
        --burnt?
        local isBurnt = itemData
        and itemData.data.grillState == "burnt"
        if isBurnt then
            return false
        end
        --fire lit?
        local isLit = ref.data.isLit
        if not isLit then
            return false
        end

        return true
    end,
}