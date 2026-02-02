local common = require("mer.ashfall.common.common")
local logger = common.createLogger("ClayGlaze")

---Class for handling the registration and application of clay glazes
---@class Ashfall.Clay.Glaze
---@field public registeredGlazes table<string, Ashfall.Clay.Glaze>
local Glaze = {}
Glaze.registeredGlazes = {}

---Construtor data
---@class Ashfall.Clay.GlazeData
---@field id string Unique ID for the glaze
---@field name string Name of the glaze
---@field texturePath string Path to the texture file for the glaze
---@field description string Description of the glaze
---@field recipe CraftingFramework.Recipe.data Recipe data for crafting the glaze
---@field quality number Between 0 and 1, quality is used for determining the final value of the fired pottery.

---Register a new glaze
---@param glazeData Ashfall.Clay.GlazeData Data for the glaze
---@return Ashfall.Clay.Glaze The registered glaze
function Glaze.registerGlaze(glazeData)
    logger:assert(type(glazeData.id) == "string", "Glaze must have an ID")
    logger:assert(type(glazeData.name) == "string", "Glaze must have a name")
    logger:assert(type(glazeData.texturePath) == "string", "Glaze must have a texturePath")
    logger:assert(type(glazeData.description) == "string", "Glaze must have a description")
    logger:assert(glazeData.recipe ~= nil, "Glaze must have a recipe")
    logger:assert(type(glazeData.quality) == "number", "Glaze must have a quality number")

    local glaze = {}
    glaze.id = glazeData.id
    glaze.name = glazeData.name
    glaze.texturePath = glazeData.texturePath
    glaze.description = glazeData.description
    glaze.recipe = glazeData.recipe
    glaze.quality = glazeData.quality

    setmetatable(glaze, { __index = Glaze })
    Glaze.registeredGlazes[glaze.id] = glaze

    return glaze
end



return Glaze