local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("Bushcrafting")
local CraftingFramework = include("CraftingFramework")
local inspect = require("inspect").inspect

if not CraftingFramework then
    logger:error("CraftingFramework not found")
end
local craftingConfig = require("mer.ashfall.bushcrafting.config")

---@param recipeLists Ashfall.bushcrafting.recipeConfiguration[]
---@return CraftingFramework.Recipe.data[]
local function initialiseRecipeList(recipeLists)
    local recipes = {}
    for _, recipeList in ipairs(recipeLists) do
        local tiers = {
            "beginner",
            "novice",
            "apprentice",
            "journeyman",
            "expert",
            "master"
        }

        for _, tier in ipairs(tiers) do
            ---@type CraftingFramework.Recipe.data[]
            local tierData = recipeList[tier]
            for _, recipe in ipairs(tierData) do
                ---@type CraftingFramework.Recipe.data
                recipe = table.copy(recipe)
                if recipeList.commonFields then
                    for key, value in pairs(recipeList.commonFields) do
                        recipe[key] = value
                    end
                end

                local skillRequirement = craftingConfig.survivalTiers[tier]
                recipe.skillRequirements = {
                    skillRequirement
                }
                table.insert(recipes, recipe)
            end
        end
    end
    return recipes
end

do -- initialise recipes
    for _, tool in ipairs(craftingConfig.tools) do
        logger:debug("Registering Tool: %s", tool.id)
        CraftingFramework.Tool:new(tool)
    end
    for _, activatorConfig in pairs(craftingConfig.menuActivators) do


        local menuActivatorData = activatorConfig.menuActivator
        logger:debug("Registering Menu Activator: %s", menuActivatorData.name)
        local recipes = initialiseRecipeList(activatorConfig.recipeLists)
        logger:debug("Recipes: " .. inspect(recipes))
        menuActivatorData.recipes = recipes
        CraftingFramework.MenuActivator:new(menuActivatorData)
    end
    for _, material in ipairs(craftingConfig.materials) do
        logger:debug("Registering Material: %s", material.name)
        CraftingFramework.Material:new(material)
    end
    event.trigger("Ashfall:Bushcrafting_Initialized")
end

--Vanilla tanning racks
for _, tanningRackId in ipairs(craftingConfig.tanningRacks) do
    CraftingFramework.StaticActivator.register{
        objectId = tanningRackId,
        name = "Tanning Rack",
        onActivate = function()
            logger:debug("Tanning Rack Activated")
            event.trigger(craftingConfig.tanningEvent)
        end
    }
end