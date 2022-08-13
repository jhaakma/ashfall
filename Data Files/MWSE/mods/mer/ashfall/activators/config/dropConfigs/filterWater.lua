local common = require ("mer.ashfall.common.common")
local WaterFilter = require("mer.ashfall.items.waterFilter")

return {
    dropText = function(filterRef, item, itemData)
        return WaterFilter.buttons.filterWater.text
    end,
    canDrop = function(filterRef, item, itemData)
        local filterHasRoom = WaterFilter.hasRoomToFilter({ reference = filterRef})
        local refHasDirtyWater = WaterFilter.refHasDirtyWater{ item = item, itemData = itemData }
        return filterHasRoom and refHasDirtyWater
    end,
    onDrop  = function(filterRef, dropRef)
        WaterFilter.doFilterWater{
            waterFilterRef = filterRef,
            reference = dropRef
        }
        common.helper.pickUp(dropRef)
    end
}