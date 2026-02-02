local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config").config
local logger = common.createLogger("ClayTemper")
local RawClay = require("mer.ashfall.clay.RawClay")
local PotteryRecipe = require("mer.ashfall.clay.PotteryRecipe")
local CraftingFramework = require("CraftingFramework")
local UnfiredPottery = require("mer.ashfall.clay.UnfiredPottery")


---@class Ashfall.Clay.TemperData
---@field id string The object ID of the ingredient used as temper
---@field name string The name of the temper
---@field description string The description of the temper


---Class for managing the clayworking menu
---triggered by equipping raw clay
---@class Ashfall.Clay.ClayWorking
local ClayWorking    = {
    ---@type table<string, { name: string, description: string } >
    registeredTempers = {},
    ---@type CraftingFramework.MenuActivator?
    menuActivator = nil,

    ---@type table<string, boolean>
    activatorIds = {}
}


---Register a temper
---@param temperData Ashfall.Clay.TemperData Data for the temper
function ClayWorking.registerTemper(temperData)
    logger:assert(type(temperData.id) == "string", "Temper must have an id")
    ClayWorking.registeredTempers[temperData.id:lower()] = temperData
    if ClayWorking.menuActivator then
        local recipeData = ClayWorking.createTemperRecipe(temperData)
        ClayWorking.menuActivator:registerRecipe(recipeData)
        logger:debug("Registered temper recipe for item: %s", temperData.id)
    end
end


---Create a tempering recipe for the given ingredient
---@param temperData Ashfall.Clay.TemperData
---@return CraftingFramework.Recipe.data?
function ClayWorking.createTemperRecipe(temperData)
    ---@type CraftingFramework.Recipe.data
    local recipe = {
        id = "ashfall_temper_with_" .. temperData.id:lower(),
        name = string.format("Tempered Clay (%s)", temperData.name),
        description = temperData.description,
        craftableId = RawClay.temperedClayId,
        materials = {
            { material = temperData.id, count = 1 },
            { material = RawClay.rawClayId, count = 1 },
        },
        category = "Tempering",
        soundId = "corpDRAG",
        customRequirements = {
            {
                getLabel = function() return "Mortar and Pestle" end,
                check = function()
                    for _, result in pairs(CraftingFramework.CarryableContainer.getInventory()) do
                        local stack = result.stack
                        local isMortarAndPestle = stack.object.objectType == tes3.objectType.apparatus
                            and stack.object.type == tes3.apparatusType.mortarAndPestle
                        if isMortarAndPestle then
                            return true
                        end
                    end
                    return false
                end
            }
        },
        skillRequirements = {
            {
                skill = "pottery",
                requirement = 10
            }
        },
    }
    return recipe
end


---Create a CraftingFramework Recipe from a PotteryRecipe
---@param potteryRecipe Ashfall.PotteryRecipe
---@return CraftingFramework.Recipe.data
function ClayWorking.createPotteryRecipes(potteryRecipe)
    local recipes = {}

    ---@type CraftingFramework.Recipe.data
    local untemperedRecipe = {
        id = "ashfall_handmold_" .. potteryRecipe.id:lower(),
        name = potteryRecipe.name,
        description = "Craft " .. potteryRecipe.name .. " using clay.",
        craftableId = potteryRecipe.id,
        materials = {
            { material = RawClay.rawClayId, count = potteryRecipe.clayAmount },
        },
        category = "Hand Molding",
        soundId = "corpDRAG",
        skillRequirements = {
            {
                skill = "pottery",
                requirement = potteryRecipe.difficulty,
            }
        },
        timeTaken = 0.1,
    }
    table.insert(recipes, untemperedRecipe)

    ---@type CraftingFramework.Recipe.data
    local temperedRecipe = {
        id = "ashfall_handmold_tempered_" .. potteryRecipe.id:lower(),
        name = potteryRecipe.name .. " (Tempered)",
        description = "Craft " .. potteryRecipe.name .. " using tempered clay.",
        craftableId = potteryRecipe.id,
        materials = {
            { material = RawClay.temperedClayId, count = potteryRecipe.clayAmount },
        },
        category = "Hand Molding",
        soundId = "corpDRAG",
        data = function(e)
            local pottery = UnfiredPottery:new{
                item = e.item
            }
            if pottery then
                return {
                    Ashfall_UnfiredPottery = {
                        quality = pottery:calculateQuality(),
                        tempered = true
                    }
                }
            else
                return {}
            end
        end,
        skillRequirements = {
            {
                skill = "pottery",
                requirement = potteryRecipe.difficulty,
            }
        },
        timeTaken = 0.1,
    }
    table.insert(recipes, temperedRecipe)
    return recipes
end


function ClayWorking.getCraftMenuActivatorIds()
    return ClayWorking.activatorIds
end


function ClayWorking.registerActivatorId(id)
    ClayWorking.activatorIds[id:lower()] = true
    logger:debug("Registered clay working activator id: %s", id)
end


function ClayWorking.initialise()
    logger:debug("Initialising ClayWorking menu activator")
    ---@type CraftingFramework.Recipe.data[]
    local recipes = {}
    for _, data in pairs(ClayWorking.registeredTempers) do
        ---@type CraftingFramework.Recipe.data
        local recipe = ClayWorking.createTemperRecipe(data)
        if recipe then
            table.insert(recipes, recipe)
        end
    end

    local handMoldRecipes = PotteryRecipe.getAllRecipesByMethod("hand")
    for _, potteryRecipe in pairs(handMoldRecipes) do
        local potteryRecipes = ClayWorking.createPotteryRecipes(potteryRecipe)
        for _, recipe in ipairs(potteryRecipes) do
            table.insert(recipes, recipe)
        end
    end

    ClayWorking.menuActivator = CraftingFramework.MenuActivator:new{
        id = "ashfall_clay_working_menu",
        type = "event",
        name = "Clay Working",
        recipes = recipes,
        doesTimePass = function()
            return config.craftingTakesTime
        end,
    }

    local craftingActivatorIds = ClayWorking.getCraftMenuActivatorIds()

    event.register("equip", function(e)
        --if raw or tempered clay is equipped, open menu
        if e.reference == tes3.player then
            local itemId = e.item.id:lower()
            if craftingActivatorIds[itemId] then
                logger:debug("Opening Clay Working menu from equip event")
                ClayWorking.menuActivator:openMenu()
                return true
            end
        end
    end)

    for id in pairs(craftingActivatorIds) do
        CraftingFramework.Indicator.register{
            objectId = id,
            additionalUI = function(_, parent)
                parent:createLabel{ text = "Equip: Clay Working" }
            end
        }
    end

    logger:debug("ClayWorking initialised with %d recipes", #recipes)
end

return ClayWorking