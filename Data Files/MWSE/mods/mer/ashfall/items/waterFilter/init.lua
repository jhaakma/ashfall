local common = require("mer.ashfall.common.common")
local log = common.createLogger("WaterFilter")
local LiquidContainer   = require("mer.ashfall.objects.LiquidContainer")
local WaterFilter = {}

local config = {
    updateInterval = 0.001,
    maxWaterAmount = common.staticConfigs.bottleList.ashfall_water_filter.capacity,
    waterFilteredPerHour = 15,
}

function WaterFilter.refHasDirtyWater(e)
    local waterContainer = LiquidContainer.createFromInventory(e.item, e.itemData)
    if waterContainer then
        local hasWater = waterContainer.waterAmount
        local waterIsDirty = waterContainer:getLiquidType() == "dirty"
        if hasWater and waterIsDirty then return true end
    end
    return false
end

function WaterFilter.getTotalWaterAmount(reference)
    local unfilteredWater = reference.data.unfilteredWater or 0
    local filteredWater = reference.data.waterAmount or 0
    local totalWater = unfilteredWater + filteredWater
    log:debug("getTotalWaterAmount: %s", totalWater)
    return totalWater
end

function WaterFilter.getUnfilteredCapacityRemaining(reference)
    local unfilteredWater = reference.data.unfilteredWater or 0
    local capacity = math.min(config.maxWaterAmount - unfilteredWater)
    log:debug("getUnfilteredCapacityRemaining: %s", capacity)
    return capacity
end

---@param filterRef tes3reference
---@param liquidContainer AshfallLiquidContainer
function WaterFilter.transferWater(filterRef, liquidContainer)
    local waterAmount = liquidContainer.waterAmount
    local capacity = WaterFilter.getUnfilteredCapacityRemaining(filterRef)
    local waterToTransfer = math.min(waterAmount, capacity)
    if waterToTransfer > 0 then
        local target = LiquidContainer.createInfiniteWaterSource()
        local amount, errorMsg = liquidContainer:transferLiquid(target, waterToTransfer)
        if errorMsg then
            log:error("transferWater: %s", errorMsg)
        end
        if amount then
            filterRef.data.unfilteredWater =  filterRef.data.unfilteredWater or 0
            filterRef.data.unfilteredWater = filterRef.data.unfilteredWater + waterToTransfer
            log:debug("transferWater: %s", amount)
            tes3.messageBox("Filled Water Filter with dirty water.")
            tes3.playSound{ sound = "Swim Right"}
        end
        return amount
    end
    tes3.messageBox("Water Filter is full.")
    log:debug("No water to transfer")
    return 0
end


event.register("simulate", function(e)
    common.helper.iterateRefType("waterFilter", function(reference)
        reference.data.lastWaterFilterUpdated = reference.data.lastWaterFilterUpdated or e.timestamp
        local timeSinceLastUpdate = e.timestamp - reference.data.lastWaterFilterUpdated
        if timeSinceLastUpdate > config.updateInterval then
            local hasDirtyWater = reference.data.unfilteredWater
                and reference.data.unfilteredWater > 0
            if hasDirtyWater then
                reference.data.waterAmount = reference.data.waterAmount or 0
                local filteredWaterCapacity = config.maxWaterAmount -  reference.data.waterAmount

                local waterFilteredAmount = math.min(
                    config.waterFilteredPerHour * timeSinceLastUpdate,
                    reference.data.unfilteredWater,
                    filteredWaterCapacity
                )

                reference.data.unfilteredWater = reference.data.unfilteredWater - waterFilteredAmount
                reference.data.waterAmount = reference.data.waterAmount + waterFilteredAmount
                reference.data.lastWaterFilterUpdated = e.timestamp
                tes3ui.refreshTooltip()
                event.trigger("Ashfall:UpdateAttachNodes", { campfire = reference})
            end
            reference.data.lastWaterFilterUpdated = e.timestamp
        end
    end)
end)

function WaterFilter.hasRoomToFilter(e)
    local reference = e.reference
    local unfilteredWater = reference.data.unfilteredWater or 0
    log:debug("unfilteredWater: %s", unfilteredWater)
    return unfilteredWater < config.maxWaterAmount
end

function WaterFilter.hasWaterToCollect(e)
    local reference = e.reference
    local filteredWater = reference.data.waterAmount or 0
    return filteredWater > 0
end

function WaterFilter.doFilterWater(e)
    local waterFilterRef = e.waterFilterRef
    local item = e.item
    local itemData = e.itemData
    local reference = e.reference
    local liquidContainer
    if item and itemData then
        liquidContainer = LiquidContainer.createFromInventory(item, itemData)
    elseif reference then
        liquidContainer = LiquidContainer.createFromReference(reference)
    end
    if not liquidContainer then
        log:error("doFilterWater: No liquid container found.")
        return
    end
    WaterFilter.transferWater(waterFilterRef, liquidContainer)
end

function WaterFilter.filterWaterCallback(e)
    local safeRef = tes3.makeSafeObjectHandle(e.reference)
    timer.delayOneFrame(function()
        if not safeRef:valid() then return end
        local waterFilterRef = safeRef:getObject()
        tes3ui.showInventorySelectMenu{
            title = "Select Water Container",
            noResultsText = "You have no dirty water to filter.",
            filter = WaterFilter.refHasDirtyWater,
            callback = function(inventorySelectEventData)
                local item = inventorySelectEventData.item
                local itemData = inventorySelectEventData.itemData
                WaterFilter.doFilterWater{
                    waterFilterRef = waterFilterRef,
                    item = item,
                    itemData = itemData,
                }
            end
        }
    end)
end



function WaterFilter.collectWaterCallback(e)
    local safeRef = tes3.makeSafeObjectHandle(e.reference)
    timer.delayOneFrame(function()
        if not safeRef:valid() then return end
        local filterRef = safeRef:getObject()
        tes3ui.showInventorySelectMenu{
            title = "Select Water Container",
            noResultsText = "You have no containers to fill.",
            filter = function(e)
                local waterContainer = LiquidContainer.createFromInventory(e.item, e.itemData)
                if not waterContainer then return false end
                local isWater = waterContainer:getLiquidType() == "clean"
                    or waterContainer:getLiquidType() == "dirty"
                local hasRoom = waterContainer.waterAmount < waterContainer.capacity
                return isWater and hasRoom
            end,
            callback = function(e)
                if e.item then
                    local liquidContainer = LiquidContainer.createFromInventoryInitItemData(e.item, e.itemData)
                    local filterRefContainer = LiquidContainer.createFromReference(filterRef)
                    local amount, errorMsg = filterRefContainer:transferLiquid(liquidContainer, filterRefContainer.waterAmount)
                    if amount then
                        tes3.playSound{ sound = "Swim Right"}
                        tes3.messageBox("You collect %G from %s.", amount, e.item.name)
                    else
                        tes3.messageBox(errorMsg)
                    end
                end
            end
        }
    end)
end



WaterFilter.buttons = {
    filterWater = {
        text = "Filter Water",
        enableRequirements = WaterFilter.hasRoomToFilter,
        tooltipDisabled = { text = "Water Filter is full." },
        callback = WaterFilter.filterWaterCallback
    },
    collectWater = {
        text = "Collect Water",
        enableRequirements = WaterFilter.hasWaterToCollect,
        tooltipDisabled = { text = "You have no water to collect." },
        callback = WaterFilter.collectWaterCallback
    }
}

return WaterFilter