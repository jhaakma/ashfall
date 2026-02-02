local common = require("mer.ashfall.common.common")
local logger = common.createLogger("Pottery")


local defaultPotteryRecipeValues = {
    clayAmount = 1,
    craftingMethod = "wheel",
    breakResistance = 0.0,
    difficulty = 10,
}

---This class handles the registration and management of pottery recipes
---@class Ashfall.PotteryRecipe.data
---@field name string The name displayed when choosing a pottery item to craft
---@field id string The item ID of the pottery item before firing
---@field brokenId string The ID of the activator used when the pottery breaks
---@field firedItemId? string The item ID of the pottery item after firing
---@field clayAmount number (Default: 1) The amount of clay required to make the pottery item. Small items: 1, large items: 2
---@field animationMesh? string Path to the mesh used for the pottery animation. Required if crafting method is "wheel"
---@field craftingMethod? "hand"|"wheel" (Default: "wheel") The method used to craft the pottery item
---@field breakResistance? number (Default: 0.0) A value from 0.0 to 1.0 representing how resistant the item is to breaking during firing. 0.0 = always breaks, 1.0 = never breaks
---@field difficulty? number (Default: 10) A value between 1 and 100 representing the difficulty of crafting this item. Determines pottery skill requirement, progress gained on crafting/firing, damage chance, and value of resulting item

---@class Ashfall.PotteryRecipe : Ashfall.PotteryRecipe.data
---@field clayAmount number The amount of clay required to make the pottery item
---@field craftingMethod "hand"|"wheel" The method used to craft the pottery item
---@field breakResistance number A value from 0.0 to 1.0 representing how resistant the item is to breaking during firing
---@field difficulty number  A value between 1 and 100 representing the difficulty of crafting this item
local PotteryRecipe = {
    ---@type table<string, Ashfall.PotteryRecipe>
    registeredRecipes = {},
    ---@type table<string, boolean>
    registeredBrokenActivators = {},
}

---Registers a pottery recipe
---@param data Ashfall.PotteryRecipe.data
function PotteryRecipe.registerRecipe(data)
    PotteryRecipe.registeredRecipes[data.id:lower()] = PotteryRecipe:new(data)
    if data.brokenId then
        PotteryRecipe.registeredBrokenActivators[data.brokenId:lower()] = true
    end
    logger:debug("Registered pottery recipe for item: %s", data.id)
end

---Get a registered pottery recipe by the raw item ID
---@param rawItemId string
---@return Ashfall.PotteryRecipe?
function PotteryRecipe.getRecipeByRawItemId(rawItemId)
    return PotteryRecipe.registeredRecipes[rawItemId:lower()]
end

function PotteryRecipe.getRecipeByFiredItemId(firedItemId)
    for _, recipe in pairs(PotteryRecipe.registeredRecipes) do
        if recipe.firedItemId and recipe.firedItemId:lower() == firedItemId:lower() then
            return recipe
        end
    end
    return nil
end

---Returns true if item is a raw pottery item
---@param item tes3item
---@return boolean
function PotteryRecipe.isPotteryItem(item)
    if not item then return false end
    if not item.supportsLuaData then return false end
    return PotteryRecipe.registeredRecipes[item.id:lower()] ~= nil
end


---Returns true if item is a fired pottery item
---@param item tes3item
---@return boolean
function PotteryRecipe.isFiredPotteryItem(item)
    if not item then return false end
    if not item.supportsLuaData then return false end
    for _, recipe in pairs(PotteryRecipe.registeredRecipes) do
        if recipe.firedItemId ~= nil and recipe.firedItemId:lower() == item.id:lower() then
            return true
        end
    end
    return false
end

-- Get craftable recipes by crafting method
---@param method "hand"|"wheel"
---@return Ashfall.PotteryRecipe[]
function PotteryRecipe.getCraftableRecipesByMethod(method)
    local recipes = {}
    for _, recipe in pairs(PotteryRecipe.registeredRecipes) do
        if recipe:canCraft() and recipe.craftingMethod == method then
            table.insert(recipes, recipe)
        end
    end
    return recipes
end

--Get all recipes by crafting method
---@param method "hand"|"wheel"
---@return Ashfall.PotteryRecipe[]
function PotteryRecipe.getAllRecipesByMethod(method)
    local recipes = {}
    for _, recipe in pairs(PotteryRecipe.registeredRecipes) do
        if recipe.craftingMethod == method then
            table.insert(recipes, recipe)
        end
    end
    return recipes
end


--Constructor
---@param data Ashfall.PotteryRecipe.data
---@return Ashfall.PotteryRecipe
function PotteryRecipe:new(data)
    logger:assert(data.id ~= nil, "Pottery recipe must have an id")
    logger:assert(data.firedItemId ~= nil, "Pottery recipe must have a firedItemId")
    local recipe = table.copy(data)
    table.copymissing(recipe, defaultPotteryRecipeValues)

    local obj = table.copy(recipe)
    setmetatable(obj, self)
    self.__index = self
    return obj --[[@as Ashfall.PotteryRecipe]]
end

function PotteryRecipe:canCraft()
    if not tes3.player then
        logger:warn("No player reference found when checking pottery recipe craftability")
        return false
    end
    local bushcraftingSkill = common.skills.bushcrafting.current
    return bushcraftingSkill >= self.difficulty
end

---Get the raw pottery item
---@return tes3item
function PotteryRecipe:getRawItem()
    local item = tes3.getObject(self.id)
    logger:assert(item ~= nil, "Pottery recipe raw item not found: %s", self.id)
    return item
end

---Get the fired pottery item
---@return tes3item?
function PotteryRecipe:getFiredItem()
    if not self.firedItemId then
        return nil
    end
    local item = tes3.getObject(self.firedItemId)
    logger:assert(item ~= nil, "Pottery recipe fired item not found: %s", self.firedItemId)
    return item
end

return PotteryRecipe