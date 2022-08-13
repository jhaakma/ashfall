local interop = require("mer.ashfall.interop")
local types = {
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
local activators = {
    t_com_var_barrelwater_01 = types.waterClean,
    t_glb_terrwater_waterjet_01 = types.waterClean,


}

interop.registerActivators(activators)

return activators