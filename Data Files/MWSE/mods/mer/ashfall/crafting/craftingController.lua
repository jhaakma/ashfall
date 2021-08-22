local craftingConfig = require("mer.ashfall.crafting.craftingConfig")
local craftingMenu = require("mer.ashfall.crafting.craftingMenu")
local common = require ("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config

local function isIngredient(item)
    return craftingConfig.ingredMaterials[item.id:lower()]
end

local function getRecipes(item)
    common.log:debug("getting recipes for %s", item.id)
    local recipeList = {}
    for recipeName, recipe in pairs(craftingConfig.recipes) do
        common.log:debug("checking %s recipe", recipeName)
        for _, ingredient in ipairs(recipe.ingredients) do
            for _, id in ipairs(ingredient.ingredType.ids) do
                if item.id:lower() == id then
                    common.log:debug("Adding %s to recipe list", recipeName)
                    table.insert(recipeList, recipe)
                    break
                end
            end
        end
    end
    return recipeList
end



local function onActivateIngredient(e)
    if not config.enableBushcrafting then return end
    --must be in menu
    if not tes3.menuMode() then return end
    if isIngredient(e.item) then
        craftingMenu.openMenu(craftingConfig.recipes)
        return true
    end
end
event.register("equip", onActivateIngredient, { filter = tes3.player, priority = -50 } )



local function createMaterialsTooltip(e)
    if not config.enableBushcrafting then return end

    if not e.tooltip then
        return
    end
    if not e.object then
        return
    end

    if isIngredient(e.object) then
        common.helper.addLabelToTooltip(e.tooltip, "Crafting Material", {175/255, 129/255, 184/255})
    end
end

event.register('uiObjectTooltip', createMaterialsTooltip)