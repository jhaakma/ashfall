local common = require("mer.ashfall.common.common")
local logger = common.createLogger("Temper")
local Decals = require("mer.ashfall.clay.PotteryDecals")
local CraftingFramework = require("CraftingFramework")
---Handles temper data and decals
---@class Ashfall.Clay.Tempered : ItemInstance
local Temper = {
    ---@type table<string, boolean> The list of registered temper compatible item IDs
    registeredTemperCompatibleItems = {}
}

---Registers an item as compatible with tempering
---@param itemId string The item ID to register
function Temper.registerTemperCompatibleItem(itemId)
    Temper.registeredTemperCompatibleItems[itemId:lower()] = true
    CraftingFramework.Indicator.register{
        objectId = itemId,
        additionalUI = function(_, parent)
            local text = "Tempered"
            local label = parent:createLabel{ text = text }
            label.color = tes3ui.getPalette(tes3.palette.bigNormalColor)
        end
    }
end

---Check if an item can have temper applied
function Temper.isCompatible(id)
    return Temper.registeredTemperCompatibleItems[id:lower()] == true
end

---Check if a reference has temper data
function Temper.hasTemper(reference)
    return reference
    and reference.supportsLuaData
    and reference.data
    and reference.data.ashfallTemper ~= nil
end

---Add temper to a reference
---@param reference tes3reference
function Temper.addTemper(reference)
    if not Temper.isCompatible(reference.object.id) then
        logger:warn("Tried to add temper to incompatible item: %s", reference.object.id)
        return
    end
    if Temper.hasTemper(reference) then
        return
    end
    reference.data.ashfallTemper = true
    Decals.get("temper"):applyDecal(reference)
end

---Remove temper from a reference
---This is unlikely to be used in normal gameplay
---@param reference tes3reference
function Temper.removeTemper(reference)
    if not Temper.hasTemper(reference) then
        return
    end
    reference.data.ashfallTemper = nil
    Decals.get("temper"):removeDecal(reference)
end


function Temper.onReferenceActivated(reference)
    local isCompatible = reference and Temper.isCompatible(reference.object.id)
    if not isCompatible then
        return
    end
    if not Temper.hasTemper(reference) then
        return
    end
    logger:debug("Reapplying temper decal to reference %s", reference.id)
    Decals.get("temper"):applyDecal(reference)
end

function Temper.initialise()
    event.register("ReferenceActivated", Temper.onReferenceActivated)
    logger:debug("Temper system initialised")

end

return Temper