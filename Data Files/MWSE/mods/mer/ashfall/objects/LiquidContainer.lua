--[[
    This class handles the creation and functionality of liquid containers, which can pass various types of
    liquid from one to another. A liquid container can take many forms, each requiring different logic.
    For example, if a liquid container is or is attached to a real-world reference, we need to trigger node updates
    so that steam visuals etc gets updated, whereas if it's in the player's inventory, we need to refresh the UI.

    A liquid container can be one of the following:
    - An in-world reference to a utensil or bottle
    - A campfire with a cooking pot or kettle attached to it
    - An item inside the players inventory
    - A source of water such as a well
]]


local common = require("mer.ashfall.common.common")
local foodConfig = require "mer.ashfall.config.foodConfig"
local teaConfig = require "mer.ashfall.config.teaConfig"

--Types
---@class AshfallLiquidContainerData
---@field waterAmount number
---@field waterHeat number
---@field stewProgress number
---@field teaProgress number
---@field stewLevels table
---@field waterType string
---@field lastWaterUpdated number

---@class AshfallLiquidContainer
---@field data AshfallLiquidContainerData The Reference.data or itemData.data
---@field itemId string The id of the item
---@field reference tes3reference (Optional) if there is a reference, we need it for updating nodes
---@field waterAmount number Amount of water in container. Maps to data.waterAmount
---@field waterHeat number How hot the water is out of 100. Maps to data.waterHeat
---@field stewProgress number How far the stew has cooked
---@field teaProgress number How far the tea has brewed
---@field waterType string Is either the id of the tea used or "dirty"
---@field stewLevels table Data containing stew data
---@field capacity number Maximum water capacity of container
---@field holdsStew boolean Flag whether container is able to hold stew. If it can hold stew, it can't hold tea.
---@field new function constructor
---@field createFromReference function Create a new LiquidContainer from an in-world reference
---@field createFromInventory function Create a new LiquidContainer from an item in the player's inventory
---@field createInfiniteWaterSource function Create a liquidContainer with an infinite water source, such as a well.
---@field transferLiquid function Transfer liquid from one liquidContainer to another
---@field updateHeat function Updates the heat and triggers node updates for steam etc
---@field getLiquidName function Get's a user-facing string for the type of liquid in the container
---@field canTransfer function Returns true if it is possible to transfer liquids between two liquid containers.

local LiquidContainer = {}
local dataValues = {
    waterAmount = {default = 0},
    waterHeat = {default = 0},
    stewProgress = {default = 0},
    stewLevels = {default = nil},
    waterType = {default = nil},
    teaProgress = {default = 0},
    lastWaterUpdated = {default = nil},
}

local meta = {
    ---@param tbl AshfallLiquidContainer
    ---@param key any
    __index = function(tbl, key)
        if LiquidContainer[key] then return LiquidContainer[key] end
        if dataValues[key] then
            local val = tbl.data[key] or dataValues[key].default
            return val
        end
    end,

    ---@param self AshfallLiquidContainer
    ---@param key any
    ---@param val any
    __newindex = function(self, key, val)
        if dataValues[key] then
            self.data[key] = val
        else
            rawset(self, key, val)
        end
    end,

    __tostring = function(self)
        return self.itemId
    end,
}

---@param id string The Object id of the container
---@param dataHolder table Either a reference or an itemData, either way it is how we access data table.
---Data Holder is Optional, but only for using as a filter. Mandatory if you want to actually transfer liquid
---@return AshfallLiquidContainer|boolean liquidContainer
function LiquidContainer.new(id, dataHolder, reference)
    local bottleData = common.staticConfigs.bottleList[id:lower()]
    if bottleData then

        ---@type AshfallLiquidContainer
        local liquidContainer = {}

        setmetatable(liquidContainer, meta )

        ---@type AshfallLiquidContainerData
        liquidContainer.data = dataHolder and dataHolder.data or {}
        liquidContainer.capacity = bottleData.capacity
        liquidContainer.holdsStew = bottleData.holdsStew == true
        liquidContainer.reference = reference
        liquidContainer.itemId = id
        if liquidContainer.stewLevels then liquidContainer.waterType = "stew" end
        return liquidContainer
    end
    --Not a valid liquidContainer
end

---@param reference tes3reference
---@return AshfallLiquidContainer liquidContainer
function LiquidContainer.createFromReference(reference)
    local id = (reference.data and reference.data.utensilId) or reference.baseObject.id
    return LiquidContainer.new(id, reference, reference)
end

---@param item tes3object
---@param itemData tes3itemData
---@return AshfallLiquidContainer liquidContainer
function LiquidContainer.createFromInventory(item, itemData)
    return LiquidContainer.new(item.id, itemData)
end

function LiquidContainer.createInfiniteWaterSource(data, reference)
    data = data or {}
    data.waterAmount = data.waterAmount or math.huge
    return LiquidContainer.new('_infinite_water_source', {data = data}, reference)
end


---@param from AshfallLiquidContainer
---@param to AshfallLiquidContainer
function LiquidContainer.canTransfer(from, to)
    --If to is a reference stack, then can't transfer
    if to.reference and to.reference.attachments.variables.count > 1 then
        common.log:debug("tried transfering to ref stack")
        return false
    end

    --If both have a waterType, can't mix
    if from.waterType and to.waterType then
        if from.waterType ~= to.waterType then return false end
    end
    -- --For now, can't mix stews
    -- if from.stewLevels and to.stewLevels then
    --     return false
    -- end
    -- Target must have some room to add water
    if to.capacity - to.waterAmount < 1 then
        return false
    end
    -- Source must have some water to transfer
    if from.waterAmount < 1 then
        return false
    end
    --If transfering stew, target must have holdsStew flag
    if from.stewLevels and not to.holdsStew then
        return false
    end

    --If mixing stew with water, must be attached to campfire
    if from.stewLevels or to.stewLevels then
        if (not from.stewLevels) or (not to.stewLevels) then
            if to.data.waterCapacity == nil and to.waterAmount and to.waterAmount > 0 then
                return false
            end
        end
    end

    --If transferring tea, target must NOT have holdsStew flag
    local fromIsTea = teaConfig.teaTypes[from.waterType]
    local toIsTea = teaConfig.teaTypes[to.waterType]
    if fromIsTea and to.holdsStew then
        return false
    end
    --if one is a tea, both must be same tea
    if fromIsTea or toIsTea then
        if to.waterAmount and to.waterAmount > 1 then
            if from.waterType ~= to.waterType then
                return false
            end
        end
    end
    common.log:debug("Can transfer from %s to %s", from, to)
    return true
end

---@param from AshfallLiquidContainer
---@param to AshfallLiquidContainer
---@param amount number
function LiquidContainer.transferLiquid(from, to, amount)
    common.log:debug("Transferring %s from %s to %s", amount, from, to)
    if not from:canTransfer(to) then
        common.log:debug("Failed to transfer")
        return 0
    end
    amount = amount or math.huge
    ---Fill amount is limited by how much space there is in the target, and how much liquid the source has
    local targetRemainingCapacity = to.capacity - to.waterAmount
    local fillAmount = math.min(from.waterAmount, targetRemainingCapacity, amount)
    --Early exit if there's nothing to fill
    if fillAmount < 1 then return 0 end
    -- waterHeat
    local fromHeat = from.waterHeat or 0
    local toHeat = to.waterHeat or 0
    local newHeat =
        (fromHeat*fillAmount + toHeat*to.waterAmount)
        / (fillAmount + to.waterAmount)
    to:updateHeat(newHeat)

    -- stewProgress
    to.stewProgress = (from.stewProgress*fillAmount + to.stewProgress*to.waterAmount)
        / (fillAmount + to.waterAmount)
    --water type
    to.waterType = from.waterType or to.waterType
    --tea progress
    to.teaProgress = (from.teaProgress*fillAmount + to.teaProgress*to.waterAmount)
        / (fillAmount + to.waterAmount)
    common.log:debug("from.teaProgress: %s", from.teaProgress)
    common.log:debug("fillAmount: %s", fillAmount)
    common.log:debug("to.teaProgress: %s", to.teaProgress)
    common.log:debug("to.waterAmount: %s", to.waterAmount)

    -- waterAmount
    local targetWaterBefore = to.waterAmount
    from.waterAmount = from.waterAmount - fillAmount
    to.waterAmount = to.waterAmount + fillAmount
    local targetWaterAfter = to.waterAmount
    -- stewLevels
    if from.stewLevels or to.stewLevels then
        local fromStew = table.copy(from.stewLevels or {}, {
            [foodConfig.type.meat] = 0,
            [foodConfig.type.vegetable] = 0,
            [foodConfig.type.mushroom] = 0,
            [foodConfig.type.seasoning] = 0,
            [foodConfig.type.herb] = 0,
        })
        local toStew = table.copy(to.stewLevels or {}, {
            [foodConfig.type.meat] = 0,
            [foodConfig.type.vegetable] = 0,
            [foodConfig.type.mushroom] = 0,
            [foodConfig.type.seasoning] = 0,
            [foodConfig.type.herb] = 0,
        })

        to.stewLevels = {}
        for name, _ in pairs(fromStew) do
            local newStewLevel = (fromStew[name]*fillAmount + toStew[name]*targetWaterBefore) / targetWaterAfter
            to.stewLevels[name] = newStewLevel > 0 and newStewLevel or nil
        end
    end

    -- lastWaterUpdated
    to.lastWaterUpdated = nil
    --Clear empty from
    if from.waterAmount < 1 then
        for key, _ in pairs(dataValues) do
            from[key] = nil
        end
        from:updateHeat(0)
    end
    --Trigger node updates
    if from.reference then
        event.trigger("Ashfall:UpdateAttachNodes", {campfire = from.reference})
    end
    if to.reference then
        event.trigger("Ashfall:UpdateAttachNodes", {campfire = to.reference})
        event.trigger("Ashfall:registerReference", { reference = to.reference})
    end
    tes3ui.updateInventoryTiles()
    tes3.playSound({reference = tes3.player, sound = "Swim Left", volume = 2.0})
    --Show message
    local item =  tes3.getObject(to.itemId)
    if item and item.name then
        tes3.messageBox('%s filled with %s.', common.helper.getGenericUtensilName(item), to:getLiquidName())
    end
    common.log:debug("Transferred %s", fillAmount)
    common.log:debug("New water amount: %s", to.waterAmount)
    return fillAmount
end

---@param self AshfallLiquidContainer
function LiquidContainer.getLiquidName(self)
    if self.waterType == "dirty" then
        return "dirty water"
    elseif teaConfig.teaTypes[self.waterType] then
        return teaConfig.teaTypes[self.waterType].teaName
    elseif self.stewLevels then
        return foodConfig.isStewNotSoup(self.stewLevels) and "stew" or "soup"
    else
        return "water"
    end
end

---Updates the heat of a liquid container, triggering any node updates and sounds if necessary
---@param self AshfallLiquidContainer
---@param newHeat number
function LiquidContainer.updateHeat(self, newHeat)
    local heatBefore = self.data.waterHeat or 0
    self.waterHeat = math.clamp(newHeat, 0, 100)
    local heatAfter = self.waterHeat
    --add sound if crossing the boiling barrior
    if self.reference and not self.reference.disabled then
        if heatBefore < common.staticConfigs.hotWaterHeatValue and heatAfter > common.staticConfigs.hotWaterHeatValue then
            event.trigger("Ashfall:UpdateAttachNodes", {campfire = self.reference})
        end
        if heatBefore > common.staticConfigs.hotWaterHeatValue and heatAfter < common.staticConfigs.hotWaterHeatValue then
            common.log:debug("No longer hot")
            event.trigger("Ashfall:UpdateAttachNodes", {campfire = self.reference})
        end
    end
end



return LiquidContainer