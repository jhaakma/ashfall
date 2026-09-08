local common = require("mer.ashfall.common.common")
local logger = common.createLogger("Brick")
local CraftingFramework = require("CraftingFramework")
local Material = CraftingFramework.Material

---@exact
---@class Ashfall.Clay.Brick
---@field rawMenuActivator CraftingFramework.MenuActivator
---@field firedMenuActivator CraftingFramework.MenuActivator
local Brick = {
    rawId = "ashfall_brick_raw_01",
    firedId = "ashfall_brick_fired_01",
    menuEvent = "Ashfall:BrickMenu"
}


--Check if an object is a raw or fired clay brick
---@param item tes3item|nil
---@return boolean
function Brick.isBrick(item)
    if not item then return false end
    local id = item.id:lower()
    if id == Brick.rawId then
        return true
    end
    if id == Brick.firedId then
        return true
    end

    return false
end

--Check if raw brick
---@param item tes3item|nil
---@return boolean
function Brick.isRawBrick(item)
    if not item then return false end
    return item.id:lower() == Brick.rawId
end

--Check if fired brick
---@param item tes3item|nil
---@return boolean
function Brick.isFiredBrick(item)
    if not item then return false end
    return item.id:lower() == Brick.firedId
end


---@type CraftingFramework.MenuActivator.data
local menuData = {
    name = "Brick Crafting",
    type = "event",
    id = "BrickCraftingMenu",
    recipes = {}
}

---@type CraftingFramework.Material.data
local brickMaterialData = {
    name = "Brick",
    id = "brick",
    ids = {
        Brick.rawId,
        Brick.firedId,
    }
}

function Brick.initialise()
    Material:registerMaterials{brickMaterialData}

    local rawMenuData = table.copy(menuData)
    rawMenuData.id = "RawBrickCraftingMenu"
    Brick.rawMenuActivator = CraftingFramework.MenuActivator:new(rawMenuData)

    local firedMenuData = table.copy(menuData)
    firedMenuData.id = "FiredBrickCraftingMenu"
    Brick.firedMenuActivator = CraftingFramework.MenuActivator:new(firedMenuData)

    event.register("equip", function(e)
        if Brick.isRawBrick(e.item) then
            Brick.rawMenuActivator:openMenu()
        elseif Brick.isFiredBrick(e.item) then
            Brick.firedMenuActivator:openMenu()
        end
    end)
end

return Brick
