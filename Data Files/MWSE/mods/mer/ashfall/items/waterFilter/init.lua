local common = require("mer.ashfall.common.common")
local logger = common.createLogger("WaterFilter")
local LiquidContainer   = require("mer.ashfall.liquid.LiquidContainer")
local ReferenceController = require("mer.ashfall.referenceController")

local WaterFilter = {}
WaterFilter.filterIDs = {
    --ashfall_water_filter = true
}
local config = {
    updateInterval = 0.001,
    maxWaterAmount = common.staticConfigs.bottleConfig.wooden_bowl.capacity,
    waterFilteredPerHour = 15,
}

function WaterFilter.registerWaterFilter(e)
    common.staticConfigs.bottleList[e.id:lower()] = {
        capacity = e.capacity,
        holdsStew = false,
        waterMaxHeight = e.waterMaxHeight,
        waterMaxScale = e.waterMaxScale,
    }
    common.staticConfigs.activatorConfig.list.waterContainer:addId(e.id)
    WaterFilter.filterIDs[e.id:lower()] = true
end

WaterFilter.registerWaterFilter{
    id = "ashfall_water_filter",
    capacity = config.maxWaterAmount,--sync with wooden bowl
    holdsStew = false,
    waterMaxHeight = 4,
    waterMaxScale = 1.8,
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
    logger:debug("getTotalWaterAmount: %s", totalWater)
    return totalWater
end

function WaterFilter.getUnfilteredCapacityRemaining(reference)
    local unfilteredWater = reference.data.unfilteredWater or 0
    local capacity = math.min(config.maxWaterAmount - unfilteredWater)
    logger:debug("getUnfilteredCapacityRemaining: %s", capacity)
    return capacity
end

---@param filterRef tes3reference
---@param liquidContainer Ashfall.LiquidContainer
function WaterFilter.transferWater(filterRef, liquidContainer)
    local waterAmount = liquidContainer.waterAmount
    local capacity = WaterFilter.getUnfilteredCapacityRemaining(filterRef)
    local waterToTransfer = math.min(waterAmount, capacity)

    if waterAmount < 1 then
        tes3.messageBox("No water to transfer.")
        return 0
    end

    if waterToTransfer < 1 then
        tes3.messageBox("Water Filter is full.")
        return 0
    end

    liquidContainer:reduce(waterToTransfer)
    filterRef.data.unfilteredWater =  filterRef.data.unfilteredWater or 0
    filterRef.data.unfilteredWater = filterRef.data.unfilteredWater + waterToTransfer
    logger:debug("transferWater: %s", waterToTransfer)
    tes3.messageBox("Filled Water Filter with dirty water.")
    tes3.playSound{ sound = "ashfall_water"}
    return waterToTransfer
end


event.register("simulate", function(e)
    ReferenceController.iterateReferences("waterFilter", function(reference)
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
                event.trigger("Ashfall:UpdateAttachNodes", { reference = reference})
            end
            reference.data.lastWaterFilterUpdated = e.timestamp
        end
    end)
end)

function WaterFilter.hasRoomToFilter(e)
    local reference = e.reference
    local unfilteredWater = reference.data.unfilteredWater or 0
    logger:debug("unfilteredWater: %s", unfilteredWater)
    return unfilteredWater <= config.maxWaterAmount - 1
end

function WaterFilter.hasWaterToCollect(e)
    local reference = e.reference
    local filteredWater = reference.data.waterAmount or 0
    return filteredWater >= 1
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
        logger:error("doFilterWater: No liquid container found.")
        return
    end
    WaterFilter.transferWater(waterFilterRef, liquidContainer)
end

function WaterFilter.filterWaterCallback(filterWaterParams)
    local safeRef = tes3.makeSafeObjectHandle(filterWaterParams.reference)
    timer.delayOneFrame(function()
        if not (safeRef and safeRef:valid()) then return end
        local waterFilterRef = safeRef:getObject()
        common.helper.showInventorySelectMenu{
            title = "Select Water Container",
            noResultsText = "You have no dirty water to filter.",
            filter = WaterFilter.refHasDirtyWater,
            callback = function(inventorySelectEventData)
                local item = inventorySelectEventData.item
                if not item then return end
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



function WaterFilter.collectWaterCallback(collectWaterParams)
    local safeRef = tes3.makeSafeObjectHandle(collectWaterParams.reference)
    timer.delayOneFrame(function()
        if not (safeRef and safeRef:valid()) then return end
        local filterRef = safeRef:getObject()
        common.helper.showInventorySelectMenu{
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
                    local liquidContainer = LiquidContainer.createFromInventoryWithItemData{
                        item = e.item,
                        itemData = e.itemData,
                        reference = e.reference
                    }
                    local filterRefContainer = LiquidContainer.createFromReference(filterRef)
                    if not liquidContainer then return end
                    if not filterRefContainer then return end

                    local amount, errorMsg = filterRefContainer:transferLiquid(liquidContainer, filterRefContainer.waterAmount)
                    if amount then
                        tes3.playSound{ sound = "ashfall_water"}
                        --tes3.messageBox("You collect %d from %s.", amount, e.item.name)
                    elseif errorMsg then
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
        tooltip = function()
            return common.helper.showHint("You can filter water by dropping a water-filled container directly onto the water filter.")
        end,
        callback = WaterFilter.filterWaterCallback
    },
    collectWater = {
        text = "Collect Water",
        enableRequirements = WaterFilter.hasWaterToCollect,
        tooltipDisabled = { text = "There is no water to collect." },
        tooltip = function()
            return common.helper.showHint(string.format(
                "You can collect water by dropping a container directly onto the filter while holdind down %s.",
                common.helper.getModifierKeyString()
            ))
        end,
        callback = WaterFilter.collectWaterCallback
    }
}
--[[
    Bushcrafted water filters are controlled through Crafting Framework.
    This handles water filters added via ESP (e.g. as a resource from OAAB).
    So we only activate this if a sourceMod exists on the reference
]]
---@param e activateEventData
local function onActivate(e)
    logger:debug("onActivate: %s", e.target)
    local reference = e.target
    --Only for ESP placed filters
    if reference.data and reference.data.crafted then
        logger:debug("crafted, returning")
        return
    end
    if WaterFilter.filterIDs[e.target.baseObject.id:lower()] then
        logger:debug("is Water Filter, displaying message")
        tes3ui.showMessageMenu{
            message = e.target.object.name,
            buttons = {
                WaterFilter.buttons.filterWater,
                WaterFilter.buttons.collectWater,
            },
            callbackParams = {
                reference = e.target,
            },
            cancels = true
        }
        return false
    end

end
event.register("activate", onActivate, { priority = 50 })


return WaterFilter