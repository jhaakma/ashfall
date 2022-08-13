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
local logger = common.createLogger("LiquidContainer")
local foodConfig = require "mer.ashfall.config.foodConfig"
local teaConfig = require "mer.ashfall.config.teaConfig"



---@class Ashfall.LiquidContainer.Data
---@field waterAmount number Amount of water in container. Maps to data.waterAmount
---@field waterHeat number How hot the water is out of 100. Maps to data.waterHeat
---@field stewProgress number How far the stew has cooked
---@field teaProgress number How far the tea has brewed
---@field waterType string Is either the id of the tea used or "dirty"
---@field stewLevels table Data containing stew data
---@field lastWaterUpdated number The last time the water was updated
---@field lastStewUpdated number The last time the stew was updated
---@field lastBrewUpdated number The last time the tea was updated
---@field lastWaterHeatUpdated number The last time the water heat was updated
---@field stewBuffs table The stew buffs
---@field ladle boolean A ladle is attached to the cooking pot

---@class Ashfall.LiquidContainer
---@field data Ashfall.LiquidContainer.Data The Reference.data or itemData.data
---@field itemId string The id of the item
---@field reference tes3reference (Optional) if there is a reference, we need it for updating nodes
---@field waterAmount number Amount of water in container. Maps to data.waterAmount
---@field waterHeat number How hot the water is out of 100. Maps to data.waterHeat
---@field stewProgress number How far the stew has cooked
---@field teaProgress number How far the tea has brewed
---@field waterType string Is either the id of the tea used or "dirty"
---@field stewLevels table Data containing stew data
---@field lastWaterUpdated number The last time the water was updated
---@field lastStewUpdated number The last time the stew was updated
---@field lastBrewUpdated number The last time the tea was updated
---@field lastWaterHeatUpdated number The last time the water heat was updated
---@field stewBuffs table The stew buffs
---@field capacity number Maximum water capacity of container
---@field holdsStew boolean Flag whether container is able to hold stew. If it can hold stew, it can't hold tea.
local LiquidContainer = {}

local dataValues = {
    waterAmount = {default = 0},
    waterHeat = {default = 0},
    stewProgress = {default = 0},
    stewLevels = {default = nil},
    waterType = {default = nil},
    teaProgress = {default = 0},
    lastWaterUpdated = {default = nil},
    lastStewUpdated = {default = nil},
    lastBrewUpdated = {default = nil},
    lastWaterHeatUpdated = {default = nil},
    stewBuffs = {default = nil},
}

local meta = {
    ---@param tbl Ashfall.LiquidContainer
    ---@param key any
    __index = function(tbl, key)
        if LiquidContainer[key] then return LiquidContainer[key] end
        if dataValues[key] then
            local val = tbl.data[key] or dataValues[key].default
            return val
        end
    end,

    ---@param self Ashfall.LiquidContainer
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

---@class LiquidContainer.BottleData
---@field capacity number
---@field holdsStew boolean

---@class LiquidContainer.ConstructorData
---@field id string
---@field dataHolder table
---@field reference tes3reference
---@field bottleData table

--[[
    Construct a new Liquid Container.
    Data Holder is Optional, but only for using as a filter. Mandatory if you want to actually transfer liquid
]]
---@param e LiquidContainer.ConstructorData
---@return Ashfall.LiquidContainer|nil liquidContainer
function LiquidContainer.new(e)
    local id = e.id
    local dataHolder = e.dataHolder
    local reference = e.reference
    local bottleData = e.bottleData or common.staticConfigs.bottleList[id:lower()]
    if bottleData then
        ---@type Ashfall.LiquidContainer
        local liquidContainer = {}
        liquidContainer.dataHolder = dataHolder --if null, an item with no itemData
        ---@type Ashfall.LiquidContainer.Data
        liquidContainer.data = dataHolder and dataHolder.data or {}
        liquidContainer.capacity = bottleData.capacity
        liquidContainer.holdsStew = bottleData.holdsStew == true
        liquidContainer.reference = reference
        liquidContainer.itemId = id
        setmetatable(liquidContainer, meta )
        if liquidContainer.stewLevels then liquidContainer.waterType = "stew" end
        return liquidContainer
    end
    --Not a valid liquidContainer
end

--[[
    Create a Liquid container from a given reference.
]]
---@param reference tes3reference
---@return Ashfall.LiquidContainer|nil liquidContainer
function LiquidContainer.createFromReference(reference, bottleData)
    local id = (reference.data and reference.data.utensilId) or reference.baseObject.id
    return LiquidContainer.new{
        id = id,
        dataHolder = reference,
        reference = reference,
        bottleData = bottleData
    }
end

--[[
    Create a Liquid Container from an item in the player's inventory.
]]
---@param item tes3object
---@param itemData tes3itemData
---@return Ashfall.LiquidContainer|nil liquidContainer
function LiquidContainer.createFromInventory(item, itemData)
    local bottleData = common.staticConfigs.bottleList[item.id:lower()]
    return LiquidContainer.new{
        id = item.id,
        dataHolder = itemData,
        bottleData = bottleData
    }
end

--[[
    Create a Liquid Container from an item in the player's inventory and initialise an itemData for it.
]]
---@param item tes3object
---@param itemData tes3itemData
---@return Ashfall.LiquidContainer|nil liquidContainer
function LiquidContainer.createFromInventoryInitItemData(item, itemData)
    if not itemData then
        itemData = tes3.addItemData{
            to = tes3.player,
            item = item.id
        }
    end
    return LiquidContainer.new{
        id = item.id,
        dataHolder = itemData,
    }
end

--[[
    Create Liquid Container from an exiting item's data table.
]]
---@param data table
---@return Ashfall.LiquidContainer|nil liquidContainer
function LiquidContainer.createFromData(data, bottleData)
    bottleData = bottleData or {
        capacity = math.huge,
        holdsStew = false
    }
    return LiquidContainer.new{
        id = '_infinite_water_source',
        dataHolder = { data = data},
        bottleData = bottleData
    }
end

--[[
    Create an infinite water source Liquid Container.
    Use optional data table to determine properties such as tea type, dirty water etc.
]]
---@param data table|nil **Optional**
---@return Ashfall.LiquidContainer liquidContainer
function LiquidContainer.createInfiniteWaterSource(data)
    data = data or {}
    data.waterAmount = data.waterAmount or math.huge
    return LiquidContainer.createFromData(data)
end

--[[
    Check if water can be transfer between two liquid containers.
]]
---@param from Ashfall.LiquidContainer
---@param to Ashfall.LiquidContainer
function LiquidContainer.canTransfer(from, to)
    --Can't transfer to itself
    if from.data == to.data then
        return false
    end

    --If to is a reference stack, then can't transfer
    if to.reference and to.reference.attachments.variables.count > 1 then
        logger:debug("tried transfering to ref stack")
        return false, "Can not transfer to a stack."
    end

    --If both have a waterType, can't mix
    if from.waterType and to.waterType then
        if from.waterType ~= to.waterType then
            return false, "Can not mix different liquid types."
        end
    end

    -- Target of stew must have a ladle
    local requiresLadle = common.staticConfigs.cookingPots[to.itemId:lower()]
    local hasLadle = not not to.data.ladle
    if from.stewLevels and requiresLadle and not hasLadle then
        return false, "Target must have a ladle."
    end
    -- Target must have some room to add water
    if to.capacity - to.waterAmount < 1 then
        return false, "Target is full."
    end
    -- Source must have some water to transfer
    if from.waterAmount < 1 then
        return false, "Source is empty."
    end
    --If transfering stew, target must have holdsStew flag
    if from.stewLevels and not to.holdsStew then
        return false, "Target can not hold stew."
    end

    --If transferring tea, target must NOT have holdsStew flag
    local fromIsTea = teaConfig.teaTypes[from.waterType]
    local toIsTea = teaConfig.teaTypes[to.waterType]
    if fromIsTea and to.holdsStew then
        return false, "Target can not hold tea."
    end
    --if one is a tea, both must be same tea
    if fromIsTea or toIsTea then
        if to.waterAmount and to.waterAmount > 1 then
            if from.waterType ~= to.waterType then
                return false, "Can not mix different tea types."
            end
        end
    end
    logger:trace("Can transfer from %s to %s", from, to)
    return true
end

---Trasfer liquid from one liquid container to another.
---@param from Ashfall.LiquidContainer
---@param to Ashfall.LiquidContainer
---@param amount number|nil
function LiquidContainer.transferLiquid(from, to, amount)
    logger:debug("Transferring %s from %s to %s", amount or "[infinite]", from, to)

    --Check if transfer is possible
    local canTransfer, errorMsg = from:canTransfer(to)
    if not canTransfer then
        logger:debug("Failed to transfer: %s", errorMsg)
        return 0, errorMsg
    end
    amount = amount or math.huge
    ---Fill amount is limited by how much space there is in the target, and how much liquid the source has
    local targetRemainingCapacity = to.capacity - to.waterAmount
    local fillAmount = math.min(from.waterAmount, targetRemainingCapacity, amount)
    --Early exit if there's nothing to fill
    if fillAmount < 1 then return 0 end
    --Show message
    local item =  tes3.getObject(to.itemId)
    if item and item.name then
        tes3.messageBox('%s filled with %s.', common.helper.getGenericUtensilName(item), from:getLiquidName())
    end
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
    logger:trace("from.teaProgress: %s", from.teaProgress)
    logger:trace("fillAmount: %s", fillAmount)
    logger:trace("to.teaProgress: %s", to.teaProgress)
    logger:trace("to.waterAmount: %s", to.waterAmount)
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
    to.lastBrewUpdated = nil
    to.lastStewUpdated = nil
    to.lastWaterHeatUpdated = nil

    --play water transfer sound
    from:playSound()
    --Update both vessels
    from:updateAfterTransfer()
    to:updateAfterTransfer()
    logger:debug("Transferred %s", fillAmount)
    logger:debug("New water amount: %s", to.waterAmount)
    return fillAmount
end

---@return number #The amount of water that was removed. This may be less than the amount requested if there wasn't as much water in the container.
function LiquidContainer:reduce(amount)
    local amountToReduce = math.min(amount, self.waterAmount)
    self.waterAmount = self.waterAmount - amountToReduce
    self:playSound()
    self:updateAfterTransfer()
    return amountToReduce
end

---@return number #The amount that was added. This may be less than the amount requested if there wasn't enough capacity in the container.
function LiquidContainer:increase(amount)
    local remainingCapacity = self.capacity - self.waterAmount
    local amountToFill = math.min(amount, remainingCapacity)
    local remaining = amount - amountToFill
    self.waterAmount = self.waterAmount + amountToFill
    self:playSound()
    self:updateAfterTransfer()
    return amountToFill
end

--Perform any updates that might be required when water level changes
function LiquidContainer:updateAfterTransfer()
    --Clear data on empty
    if self.waterAmount < 1 then
        self:empty()
    end
    self:doGraphicalUpdates()
end

---Empty a water container, clearing item data and triggering any node updates.
---@return number #The amount of water that was emptied
function LiquidContainer:empty()
    local amountEmptied = self.waterAmount
    self:updateHeat(0)
    for k, _ in pairs(dataValues) do
        self.data[k] = nil
    end
    self:doGraphicalUpdates()
    return amountEmptied
end

function LiquidContainer:doGraphicalUpdates()
    --Update reference
    if self.reference then
        event.trigger("Ashfall:UpdateAttachNodes", { reference = self.reference})
        event.trigger("Ashfall:registerReference", { reference = self.reference})
    end
    --Update inventory
    tes3ui.updateInventoryTiles()
end

function LiquidContainer:playSound()
    tes3.playSound({reference = tes3.player, sound = "ashfall_water"})
end

---@alias Ashfall.LiquidContainer.LiquidName
---| '"Dirty Water"'
---| '"Water"'
---| '"Stew"'
---| '"Soup"'

---@param self Ashfall.LiquidContainer
---@return Ashfall.LiquidContainer.LiquidName
function LiquidContainer:getLiquidName()
    if self.waterType == "dirty" then
        return "Dirty water"
    elseif teaConfig.teaTypes[self.waterType] then
        return teaConfig.teaTypes[self.waterType].teaName
    elseif self.stewLevels then
        return foodConfig.isStewNotSoup(self.stewLevels) and "Stew" or "Soup"
    else
        return "Water"
    end
end

function LiquidContainer:getLiquidType()
    if self.waterType == "dirty" then
        return "dirty"
    elseif teaConfig.teaTypes[self.waterType] then
        return "tea"
    elseif self.stewLevels then
        return "stew"
    else
        return "clean"
    end
end

---@return number heat
function LiquidContainer:getHeat()
    return self.data.waterHeat or 0
end

function LiquidContainer:getWaterRatio()
    return self.waterAmount / self.capacity
end

function LiquidContainer:getStewLevel(foodType)
    if not self.stewLevels then return 0 end
    return self.stewLevels[foodType] or 0
end

function LiquidContainer:getStewCapacity(foodType)
    local waterRatio = self:getWaterRatio()
    local stewLevel = self:getStewLevel(foodType)
    local adjustedIngredAmount = common.staticConfigs.stewIngredAddAmount / waterRatio
    local rawCapacity = 100 - stewLevel
    local capacity = math.ceil(rawCapacity / adjustedIngredAmount)
    return capacity
end

function LiquidContainer:isWater()
    local liquidType = self:getLiquidType()
    return liquidType == "clean" or liquidType == "dirty"
end

function LiquidContainer:isInfinite()
    return self.itemId == '_infinite_water_source'
end

function LiquidContainer:isStew()
    return self:getLiquidType() == "stew"
end

function LiquidContainer:isCookedStew()
    return self:isStew() and self.stewProgress >= 100
end

function LiquidContainer:isTea()
    return self:getLiquidType() == "tea"
end

function LiquidContainer:isBrewedTea()
    return self:isTea() and self.teaProgress >= 100
end

function LiquidContainer:isBoiling()
    return self.waterHeat > common.staticConfigs.hotWaterHeatValue
end

function LiquidContainer:hasWater()
    return self.waterAmount >= 1
end

---Updates the heat of a liquid container, triggering any node updates and sounds if necessary
---@param self Ashfall.LiquidContainer
---@param newHeat number
function LiquidContainer.updateHeat(self, newHeat)
    local heatBefore = self.data.waterHeat or 0
    self.waterHeat = math.clamp(newHeat, 0, 100)
    local heatAfter = self.waterHeat
    --add sound if crossing the boiling barrior
    if self.reference and not self.reference.disabled then
        if heatBefore < common.staticConfigs.hotWaterHeatValue and heatAfter > common.staticConfigs.hotWaterHeatValue then
            event.trigger("Ashfall:UpdateAttachNodes", { reference = self.reference})
        end
        if heatBefore > common.staticConfigs.hotWaterHeatValue and heatAfter < common.staticConfigs.hotWaterHeatValue then
            logger:debug("No longer hot")
            event.trigger("Ashfall:UpdateAttachNodes", { reference = self.reference})
        end
    end
end



return LiquidContainer