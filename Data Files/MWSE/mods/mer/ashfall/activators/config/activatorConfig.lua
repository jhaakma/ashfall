local Activator = require("mer.ashfall.activators.Activator")
local this = {}

---@class Ashfall.Activator.Config
---@field name? string The name of the activator
---@field type string The type of the activator
---@field mcmSetting? string The name of the MCM setting that controls whether this activator is active
---@field ids? table<string, table> A table of ids to register for this activator. Key: id, Value: table of data
---@field patterns? table<string, boolean> A table of patterns to register for this activator. Key: pattern, Value: true
---@field isStewer boolean Whether this activator is a stewer
---@field owned? boolean Whether this activator is owned by NPCs, such as kegs

---List of activator configurations to register
local activatorConfigs = {
    --[[
        The partial activator is any activator that
        only shows a tooltip and has functionality
        when looking at specific NiNodes.

        There's nothing special going on behind the scenes,
        it's literally just registering an activator with no name
        and no functionality.
    ]]
    {
        id = "partial",
        name = nil,
        type = "partial",
    },

    -- Water sources
    {
        id = "waterDirty",
        name = "Water (Dirty)",
        type = "dirtyWaterSource",
    },
    {
        id = "waterClean",
        name = "Water (Clean)",
        type = "waterSource",
    },
    {
        id = "basin",
        name = "Basin",
        type = "waterSource",
    },
    {
        id = "waterJug",
        name = "Water Jug",
        type = "waterSource",
    },
    {
        id = "well",
        name = "Well",
        type = "waterSource",
    },
    {
        id = "keg",
        name = "Keg",
        type = "waterSource",
        owned = true,
    },

    -- Vegetation
    {
        id = "vegetation",
        name = "Vegetation",
        type = "vegetation",
        mcmSetting = "bushcraftingEnabled",
        patterns = {},
    },
    {
        id = "tree",
        name = "Tree",
        type = "resinSource",
        patterns = {
            ["vurt_baobab"] = true,
            ["vurt_bctree"] = true,
            ["vurt_bentpalm"] = true,
            ["vurt_decstree"] = true,
            ["vurt_neentree"] = true,
            ["vurt_palm"] = true,
            ["vurt_unicy"] = true,
            ["pine_tree"] = true,--vsw
            ["mr_flora_graze_tree"] = true, --Rebirth
        },
    },
    {
        id = "stump",
        name = "Tree Stump",
        type = "stump",
    },
    {
        id = "deadTree",
        name = "Dead Tree",
        type = "woodSource",
    },
    {
        id = "wood",
        name = "Wood",
        type = "woodSource",
        patterns = {}
    },

    -- Fire sources
    {
        id = "fire",
        name = "Fire",
        type = "fire",
        patterns = {}
    },
    {
        id = "campfire",
        name = "Campfire",
        type = "campfire",
    },
    {
        id = "hearth",
        name = "Hearth",
        type = "campfire",
    },
    {
        id = "fireplace",
        name = "Fireplace",
        type = "campfire",
    },
    {
        id = "kiln",
        name = "Kiln",
        type = "campfire",
    },
    {
        id = "stove",
        name = "Stove",
        type = "campfire",
    },

    -- Furniture
    {
        id = "cushion",
        name = "Cushion",
        type = "cushion",
        ids = {
            furn_de_cushion_round_01 = { height = 20 },
            furn_de_cushion_round_02 = { height = 20 },
            furn_de_cushion_round_03 = { height = 20 },
            furn_de_cushion_round_04 = { height = 20 },
            furn_de_cushion_round_05 = { height = 20 },
            furn_de_cushion_round_06 = { height = 20 },
            furn_de_cushion_round_07 = { height = 20 },
            furn_de_cushion_square_01 = { height = 10 },
            furn_de_cushion_square_02 = { height = 10 },
            furn_de_cushion_square_03 = { height = 10 },
            furn_de_cushion_square_04 = { height = 10 },
            furn_de_cushion_square_05 = { height = 10 },
            furn_de_cushion_square_06 = { height = 10 },
            furn_de_cushion_square_07 = { height = 10 },
            furn_de_cushion_square_08 = { height = 10 },
            furn_de_cushion_square_09 = { height = 10 },
            ss20_dae_cushion_round_01 = { height = 20 },
            ss20_dae_cushion_round_02 = { height = 20 },
            ss20_dae_cushion_round_03 = { height = 20 },
            ss20_dae_cushion_round_04 = { height = 20 },
            ss20_dae_cushion_round_05 = { height = 20 },
            ss20_dae_cushion_square_01 = { height = 10 },
            ss20_dae_cushion_square_02 = { height = 10 },
            ss20_dae_cushion_square_03 = { height = 10 },
            ss20_dae_cushion_square_04 = { height = 10 },
            ss20_dae_cushion_square_05 = { height = 10 },
        },
    },

    -- Cooking equipment
    {
        id = "cauldron",
        name = "Cauldron",
        type = "cauldron",
        isStewer = true
    },
    {
        id = "teaWarmer",
        type = "teaWarmer",
    },
    {
        id = "kettle",
        type = "kettle",
    },
    {
        id = "cookingPot",
        type = "cookingPot",
    },

    -- Containers and resources
    {
        id = "waterContainer",
        type = "waterContainer",
    },
    {
        id = "stoneSource",
        name = "Rock",
        type = "stoneSource",
        patterns = {
            ["terrain_rock"] = true,
            ["terrain_ashland_rock"] = true,
        }
    },
    {
        id = "waterFilter",
        name = "Water Filter",
        type = "waterFilter",
    },
    {
        id = "woodStack",
        name = "Wood Stack",
        type = "woodStack",
        ids = {},
    },
    {
        id = "brickShed",
        name = "Brick Shed",
        type = "brickShed",
        ids = {}
    },
    {
        id = "moonStone",
        name = "Moonstone",
        type = "moonStone",
        ids = {
            ggw_rock_moonstone01 = true
        }
    },
}

-- Register all activators
for _, config in ipairs(activatorConfigs) do
    Activator:new(config)
end

-- Register aliases for backward compatibility
Activator.registerAlias("water", "waterDirty")

---@type table<string, Ashfall.Activator>
---Direct reference to Activator.registeredActivators - single source of truth
this.list = Activator.registeredActivators

return this