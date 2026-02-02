local common = require("mer.ashfall.common.common")
local logger = common.createLogger("FiredPottery")
local ItemInstance = require("CraftingFramework.carryableContainers.components.ItemInstance")
local PotteryRecipe = require("mer.ashfall.clay.PotteryRecipe")
local PotteryBreaking = require("mer.ashfall.clay.PotteryBreaking")

---Class for managing instances of fired pottery items
---@class Ashfall.FiredPottery : ItemInstance
---@field data Ashfall.FiredPotteryData
local FiredPottery = {}

---@class Ashfall.FiredPotteryData
---@field cracked boolean? Whether the pottery is cracked

---Construct from reference
---@param e ItemInstance.new.params
---@return Ashfall.FiredPottery?
function FiredPottery:new(e)
    if e.reference and not e.reference.supportsLuaData then return end

    local item = e.item or e.reference.baseObject

    logger:trace("FiredPottery:new() called for reference: %s", item.id)
    if not FiredPottery.isFiredItem(item) then
        logger:error("Attempted to create FiredPottery from non-fired item: " .. item.id)
        return nil
    end
    local firedPottery = ItemInstance:new{
        item = item,
        itemData = e.itemData,
        reference = e.reference,
        dataKey = "Ashfall_FiredPottery",
    }
    setmetatable(firedPottery, self)
    self.__index = self
    return firedPottery --[[@as Ashfall.FiredPottery]]
end

---Set decals on ref activated
function FiredPottery:setDecals()
    if not self.reference then
        logger:warn("FiredPottery:setDecals() called but no reference present")
        return
    end
    PotteryBreaking.setDecals(self.reference, self.data)
end

---Returns true if item is a fired pottery item
---@param item tes3item
---@return boolean
function FiredPottery.isFiredItem(item)
    logger:trace("FiredPottery.isFiredItem() called for item: %s", item and item.id or "nil")
    local isFired = PotteryRecipe.isFiredPotteryItem(item)
    logger:trace("Is fired pottery: %s", isFired)
    return isFired
end

---If pottery, add cracked status to tooltip
---@param e uiObjectTooltipEventData
function FiredPottery.onUiObjectTooltip(e)
    if not FiredPottery.isFiredItem(e.object) then
        return
    end
    local pottery = FiredPottery:new{ item = e.object, itemData = e.itemData, reference = e.reference }
    if pottery and pottery.data.cracked then
        common.helper.addLabelToTooltip(e.tooltip, "Cracked", {1.0, 0.5, 0.0})
    end
end

return FiredPottery
