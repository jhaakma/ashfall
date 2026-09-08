local common = require("mer.ashfall.common.common")
local logger = common.createLogger("Temper")
local Decals = require("mer.ashfall.clay.Visuals.PotteryDecals")
local CraftingFramework = require("CraftingFramework")
local ItemInstance = require("CraftingFramework.carryableContainers.components.ItemInstance")
local PotteryTooltips = require("mer.ashfall.clay.PotteryTooltips")

---Handles temper data and decals
---@class Ashfall.Clay.Tempered : ItemInstance
---@field data Ashfall.Clay.TemperedData
local Temper = {
    ---@type table<string, boolean> The list of registered temper compatible item IDs
    registeredTemperCompatibleItems = {},
    temperId = "ashfall_clay_broken_01",
}

---@class Ashfall.Clay.TemperedData
---@field ashfallTemper boolean? Whether the item has temper applied

---Construct from reference or item
---@param e ItemInstance.new.params
---@return Ashfall.Clay.Tempered?
function Temper:new(e)
    if e.reference and not e.reference.supportsLuaData then return end

    local item = e.item or e.reference.baseObject

    logger:trace("Temper:new() called for item: %s", item.id)
    if not Temper.isCompatible(item.id) then
        logger:trace("Item %s is not temper compatible", item.id)
        return nil
    end
    local tempered = ItemInstance:new{
        item = item,
        itemData = e.itemData,
        reference = e.reference,
        dataKey = "Ashfall_Temper",
    }
    setmetatable(tempered, self)
    self.__index = self
    return tempered --[[@as Ashfall.Clay.Tempered]]
end

---Registers an item as compatible with tempering
---@param itemId string The item ID to register
function Temper.registerTemperCompatibleItem(itemId)
    Temper.registeredTemperCompatibleItems[itemId:lower()] = true
end

---If pottery, add firing info to tooltip
---@param e uiObjectTooltipEventData
function Temper.onUiObjectTooltip(e)
    local temper = Temper:new{
        item = e.object,
        itemData = e.itemData,
        reference = e.reference
    }
    if temper and temper:hasTemper() then
        local temperedLabel = PotteryTooltips.getTemperedLabel()
        common.helper.addLabelToTooltip(e.tooltip, temperedLabel.text, temperedLabel.color)
    end
end



---Check if this instance has temper applied
---@return boolean
function Temper:hasTemper()
    return self.data.ashfallTemper == true
end

---Add temper to this instance
function Temper:addTemper()
    if self:hasTemper() then
        logger:trace("Item already has temper")
        return
    end
    self.data.ashfallTemper = true
    if self.reference then
        Decals.get("temper"):applyDecal(self.reference.sceneNode)
        logger:debug("Applied temper to reference %s", self.reference.id)
    end
end

---Remove temper from this instance
---This is unlikely to be used in normal gameplay
function Temper:removeTemper()
    if not self:hasTemper() then
        logger:trace("Item doesn't have temper to remove")
        return
    end
    self.data.ashfallTemper = nil
    if self.reference then
        Decals.get("temper"):removeDecal(self.reference.sceneNode)
        logger:debug("Removed temper from reference %s", self.reference.id)
    end
end


---Check if an item can have temper applied
---@param id string The item ID to check
---@return boolean
function Temper.isCompatible(id)
    return Temper.registeredTemperCompatibleItems[id:lower()] == true
end

---@param e  { reference?: tes3reference, item?: tes3item, itemData?: table }
function Temper.isTempered(e)
    local tempered = Temper:new{
        item = e.item,
        itemData = e.itemData,
        reference = e.reference
    }
    return tempered and tempered:hasTemper()
end

---Return how much temper player has in inventory
---@return number
function Temper.getPlayerTemperCount()
    return CraftingFramework.CarryableContainer.getItemCount{
        reference = tes3.player,
        item = Temper.temperId
    }
end

---@param e referenceActivatedEventData
function Temper.onReferenceActivated(e)
    local isCompatible = e.reference and Temper.isCompatible(e.reference.object.id)
    if not isCompatible then
        logger:trace("Reference %s is not temper compatible", e.reference.id)
        return
    end
    local tempered = Temper.isTempered{ reference = e.reference }
    if not tempered then
        logger:trace("Reference %s does not have temper", e.reference.id)
        return
    end
    logger:debug("Reapplying temper decal to reference %s", e.reference.id)
    Decals.get("temper"):applyDecal(e.reference.sceneNode)
end

function Temper.initialise()
    event.register("referenceActivated", Temper.onReferenceActivated)
    logger:debug("Temper system initialised")
end

return Temper