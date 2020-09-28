local waterMulti = 5.0
local cookedMulti = 1.2
local common = require ("mer.ashfall.common.common")
local teaConfig = common.staticConfigs.teaConfig

local function calcItemDataPrice(e)
    if e.itemData then
        
        local waterPrice = 1

        --Price scaled to water amount
        local waterAmount = e.itemData.data.waterAmount
        if waterAmount then
            local multi = math.remap(waterAmount, 0, 100, 1.0, waterMulti)
            waterPrice = math.max(1, waterPrice * multi)
        end

        --Dirty water is worthless
        if e.itemData.data.waterType == "dirty" then
            waterPrice = math.max(1, waterPrice * 0.2)
        end

        --Tea costs more
        local teaData = teaConfig.teaTypes[e.itemData.data.waterType]
        if teaData then
            local teaMulti = teaData.priceMultiplier or 4.0
            waterPrice = math.max(1, waterPrice * teaMulti)
        end

        local cookedAmount = e.itemData.data.cookedAmount
        if cookedAmount then
            local multi = math.remap(cookedAmount, 0, 100, 1.0, cookedMulti)
            waterPrice = math.max(1, waterPrice * multi)
        end

        common.log:trace("priceController.lua - Water Price: %s", waterPrice)
        e.price = e.price + waterPrice
    end
end

event.register("calcBarterPrice", calcItemDataPrice)