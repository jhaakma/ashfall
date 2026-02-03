local common = require("mer.ashfall.common.common")
local logger = common.createLogger("Temper")
local Decals = require("mer.ashfall.clay.PotteryDecals")
local CraftingFramework = require("CraftingFramework")
local ItemInstance = require("CraftingFramework.carryableContainers.components.ItemInstance")

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
        logger:error("Attempted to create Temper from incompatible item: %s", item.id)
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
    CraftingFramework.Indicator.register{
        objectId = itemId,
        additionalUI = function(indicator, parent)
            logger:debug("Adding temper indicator UI for item: %s", itemId)
            local tempered = Temper:new{
                item = indicator.item,
                itemData = indicator.dataHolder,
                reference = indicator.reference,
            }
            if not tempered or not tempered:hasTemper() then
                return
            end

            local text = "Tempered"
            local label = parent:createLabel{ text = text }
            label.color = tes3ui.getPalette(tes3.palette.bigNormalColor)
        end
    }
end

---Check if an item can have temper applied
---@param id string The item ID to check
---@return boolean
function Temper.isCompatible(id)
    return Temper.registeredTemperCompatibleItems[id:lower()] == true
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

---Return how much temper player has in inventory
---@return number
function Temper.getPlayerTemperCount()
    return CraftingFramework.CarryableContainer.getItemCount{
        reference = tes3.player,
        item = Temper.temperId
    }
end

function Temper.onReferenceActivated(reference)
    local isCompatible = reference and Temper.isCompatible(reference.object.id)
    if not isCompatible then
        return
    end
    local tempered = Temper:new{ reference = reference }
    if not tempered or not tempered:hasTemper() then
        return
    end
    logger:debug("Reapplying temper decal to reference %s", reference.id)
    Decals.get("temper"):applyDecal(reference.sceneNode)
end

function Temper.initialise()
    event.register("ReferenceActivated", Temper.onReferenceActivated)
    logger:debug("Temper system initialised")

end

return Temper