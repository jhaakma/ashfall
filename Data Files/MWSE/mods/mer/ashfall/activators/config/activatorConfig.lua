local Activator = require("mer.ashfall.activators.Activator")
local this = {}

--[[
    TODO:
    Move configs into integrations, move tables into Activator,
    then remove this file.
]]

this.types = {
    waterSource = "waterSource",
    dirtyWaterSource = "dirtyWaterSource",
    cookingUtensil = "cookingUtensil",
    fire = "fire",
    campfire = "campfire",
    woodSource = "woodSource",
    stump = "stump",
    resinSource = "resinSource",
    vegetation = "vegetation",
    branch = "branch",
    cauldron = "cauldron",
    cushion = "cushion",
    hearth = "hearth",
    stove = "stove",
    partial = "partial",
    planter = "planter",
    teaWarmer = "teaWarmer",
    kettle = "kettle",
    cookingPot = "cookingPot",
    waterContainer = "waterContainer",
    stoneSource = "stoneSource",
    waterFilter = "waterFilter",
    woodStack = "woodStack",
}

this.subTypes = {
    partial = "partial",
    waterDirty = "waterDirty",
    water = "water",
    waterClean = "waterClean",
    basin = "basin",
    waterJug = "waterJug",
    well = "well",
    keg = "keg",
    vegetation = "vegetation",
    tree = "tree",
    stump = "stump",
    deadTree = "deadTree",
    wood = "wood",
    fire = "fire",
    campfire = "campfire",
    hearth = "hearth",
    fireplace = "fireplace",
    stove = "stove",
    cushion = "cushion",
    cauldron = "cauldron",
    teaWarmer = "teaWarmer",
    kettle = "kettle",
    cookingPot = "cookingPot",
    waterContainer = "waterContainer",
    stoneSource = "stoneSource",
    waterFilter = "waterFilter",
    woodStack = "woodStack",
}

this.list = {}

--[[
    The partial activator is any activator that
    only shows a tooltip and has functionality
    when looking at specific NiNodes.

    There's nothing special going on behind the scenes,
    it's literally just registering an activator with no name
    and no functionality.
]]
this.list.partial = Activator:new({
    name = nil,
    type = this.types.partial,
    ids = {}
})

this.list.waterDirty = Activator:new{
    name = "Water (Dirty)",
    type = this.types.dirtyWaterSource,
    mcmSetting = nil,
    ids = {}
}
this.list.water = this.list.waterDirty
this.list.waterClean = Activator:new{
    name = "Water (Clean)",
    type = this.types.waterSource,
    mcmSetting = nil,
    ids = {}
}
this.list.basin = Activator:new{
    name = "Basin",
    type = this.types.waterSource,
    mcmSetting = nil,
    ids = {}
}
this.list.waterJug = Activator:new{
    name = "Water Jug",
    type = this.types.waterSource,
    mcmSetting = nil,
    ids = {}
}
this.list.well = Activator:new{
    name = "Well",
    type = this.types.waterSource,
    mcmSetting = nil,
    ids = {}
}
this.list.keg = Activator:new{
    name = "Keg",
    type = this.types.waterSource,
    mcmSetting = nil,
    ids = {},
    owned = true,
}
this.list.vegetation = Activator:new{
    name = "Vegetation",
    type = this.types.vegetation,
    mcmSetting = "bushcraftingEnabled",
    patterns = {
    },
    ids = {}
}

this.list.tree = Activator:new{
    name = "Tree",
    type = this.types.resinSource,
    mcmSetting = nil,
    ids = {},
    patterns = {
        ["vurt_baobab"] = true,
        ["vurt_bctree"] = true,
        ["vurt_bentpalm"] = true,
        ["vurt_decstree"] = true,
        ["vurt_neentree"] = true,
        ["vurt_palm"] = true,
        ["vurt_unicy"] = true,
        ["pine_tree"] = true,--vsw
        ["mr_flora_graze_tree "] = true, --Rebirth
    },
}
this.list.stump = Activator:new{
    name = "Tree Stump",
    type = this.types.stump,
    mcmSetting = nil,
    ids = {},
}
this.list.deadTree = Activator:new{
    name = "Dead Tree",
    type = this.types.woodSource,
    mcmSetting = nil,
    ids = {},
}
this.list.wood = Activator:new{
    name = "Wood",
    type = this.types.woodSource,
    mcmSetting = nil,
    ids = {},
    patterns = {}
}
this.list.fire = Activator:new{
    name = "Fire",
    type = this.types.fire,
    patterns = {}
}

this.list.campfire = Activator:new{
    name = "Campfire",
    type = this.types.campfire,
    mcmSetting = nil,
    ids = {},
}

this.list.hearth = Activator:new{
    name = "Hearth",
    type = this.types.campfire,
    mcmSetting = nil,
    ids = {}
}

this.list.fireplace = Activator:new{
    name = "Fireplace",
    type = this.types.campfire,
    mcmSetting = nil,
    ids = {}
}
--Stove
this.list.stove = Activator:new{
    name = "Stove",
    type = this.types.campfire,
    mcmSetting = nil,
    ids = {}
}

this.list.cushion = Activator:new{
    name = "Cushion",
    type = this.types.cushion,
    mcmSetting = nil,
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
}

this.list.cauldron = Activator:new{
    name = "Cauldron",
    type = this.types.cauldron,
    mcmSetting = nil,
    ids = {},
    isStewer = true
}

this.list.teaWarmer = Activator:new{
    type = this.types.teaWarmer,
    mcmSetting = nil,
    ids = {},
}

this.list.kettle = Activator:new{
    type = this.types.kettle,
    mcmSetting = nil,
    ids = {},
}

this.list.cookingPot = Activator:new{
    type = this.types.cookingPot,
    mcmSetting = nil,
    ids = {}
}

this.list.waterContainer = Activator:new{
    type = this.types.waterContainer,
    mcmSetting = nil,
    ids = {}
}

this.list.stoneSource = Activator:new{
    name = "Rock",
    type = this.types.stoneSource,
    mcmSetting = nil,
    patterns = {
        ["terrain_rock"] = true,
        ["terrain_ashland_rock"] = true,
    }
}

this.list.waterFilter = Activator:new{
    name = "Water Filter",
    type = this.types.waterFilter,
    ids = {}
}

this.list.woodStack = Activator:new{
    name = "Wood Stack",
    type = this.types.woodStack,
    ids = { },
}

return this