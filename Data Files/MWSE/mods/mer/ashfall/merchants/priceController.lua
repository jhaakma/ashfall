local waterMulti = 5.0 --per 100 units
local cookedMulti = 1.5
local stewMulti = 2.0
local dirtyMulti = 0.2
local common = require ("mer.ashfall.common.common")
local teaConfig = common.staticConfigs.teaConfig

local function calcItemDataPrice(e)
    if e.itemData then
        
        local itemPrice = 1

        --Water amount
        local waterAmount = e.itemData.data.waterAmount
        if waterAmount then
            local multi = math.remap(waterAmount, 0, 100, 1.0, waterMulti)
            itemPrice = itemPrice * multi
        end

        --Dirty water
        if e.itemData.data.waterType == "dirty" then
            itemPrice = itemPrice * dirtyMulti
        end

        --Tea
        local teaData = teaConfig.teaTypes[e.itemData.data.waterType]
        if teaData then
            local teaMulti = teaData.priceMultiplier or 4.0
            itemPrice = itemPrice * teaMulti
        end

        --Stew
        if e.itemData.data.stewLevels then
            itemPrice = itemPrice * stewMulti
        end

        --Cooked food
        local cookedAmount = e.itemData.data.cookedAmount
        if cookedAmount then
            local multi = math.remap(cookedAmount, 0, 100, 1.0, cookedMulti)
            itemPrice = itemPrice * multi
        end

        common.log:debug("priceController.lua - Water Price: %s", itemPrice)
        e.price = e.price + math.max(1, itemPrice)
    end
end

event.register("calcBarterPrice", calcItemDataPrice)