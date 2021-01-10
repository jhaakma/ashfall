local common = require("mer.ashfall.cooking.common")

local Recipe = {}
Recipe.name = "Meal"
Recipe.ingredients = {}
Recipe.type = common.recipeType.prepared
Recipe.duration = 15 --How long it takes to prepare
Recipe.difficulty = 15 --Cooking skill required to prepare

function Recipe:new(data)
    local t = data or {}
    setmetatable(t, self)
    self.__index = self
    return t
end

 
function Recipe.getPlayerIngredientCount(ingredient)
    local count = 0
    for _, id in ipairs(ingredient.ids) do
        count = count + mwscript.getItemCount({ reference = tes3.player, item = id})
    end
    return count
end

function Recipe:checkIngredient(ingredient)
    local needed = ingredient.count
    local count =  self:getPlayerIngredientCount(ingredient)
    local hasEnough =  ( count >= needed )
    return hasEnough
end


function Recipe:checkIngredients()
    local hasIngredients = true
    for _, ingredient in ipairs(self.ingredients) do
        local hasThisIngredient = self:checkIngredient(ingredient)
        if not hasThisIngredient then
            hasIngredients = false
        end
    end
    return hasIngredients
end

return Recipe 