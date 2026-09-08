local common = require("mer.ashfall.common.common")
local logger = common.createLogger("Decoration")
local Decals = require("mer.ashfall.clay.Visuals.PotteryDecals")

---Class for handling the registration and application of clay decorations
---@class Ashfall.Clay.Decoration : Ashfall.Clay.DecorationData
---@field public registeredDecorations table<string, Ashfall.Clay.Decoration>
local Decoration = {}
Decoration.registeredDecorations = {}

Decoration.DEFAULTS = {
    skillRequirement = 10,
    firingStage = "cooking",
    ingredients = {},
}

---@class Ashfall.Clay.Decoration.textures
---@field raw string Path to the raw texture
---@field fired string Path to the fired texture

---Constructor data
---@class Ashfall.Clay.DecorationData
---@field id string Unique ID for the decoration
---@field name string Name of the decoration
---@field description string Description of the decoration
---@field textures Ashfall.Clay.Decoration.textures Texture paths for the decoration
---@field skillRequirement nil|number (Default: 10) The pottery skill needed to apply the decoration
---@field firingStage nil|Ashfall.Campfire.FiringStage (Default: "cooking") The firing stage required to fire an item with this decoration applied
---@field ingredients nil|table<string, number> A table of ingredient item IDs and their required counts for applying the decoration

---Register a new decoration
---@param decorationData Ashfall.Clay.DecorationData Data for the decoration
---@return Ashfall.Clay.Decoration The registered decoration
function Decoration.registerDecoration(decorationData)
    logger:assert(type(decorationData.id) == "string", "Decoration must have an id")
    logger:assert(type(decorationData.name) == "string", "Decoration must have a name")
    logger:assert(type(decorationData.description) == "string", "Decoration must have a description")
    logger:assert(type(decorationData.textures) == "table", "Decoration must have textures")
    logger:assert(type(decorationData.textures.raw) == "string", "Decoration textures must have a raw texture path")
    logger:assert(type(decorationData.textures.fired) == "string", "Decoration textures must have a fired texture path")


    local decoration = table.copy(decorationData)
    table.copymissing(decoration, Decoration.DEFAULTS)
    setmetatable(decoration, { __index = Decoration })

    ---@cast decoration Ashfall.Clay.Decoration

    Decoration.registeredDecorations[decoration.id] = decoration

    Decals.register{
        id = "raw_" .. decoration.id,
        texturePath = decoration.textures.raw,
        uvIndex = 2,
        priority = 2,
    }
    Decals.register{
        id = "fired_" .. decoration.id,
        texturePath = decoration.textures.fired,
        uvIndex = 2,
        priority = 2,
    }

    return decoration
end

---Get a registered decoration by ID
---@param id string The ID of the decoration to retrieve
---@return Ashfall.Clay.Decoration|nil The decoration with the specified ID, or nil
function Decoration.getDecoration(id)
    return Decoration.registeredDecorations[id]
end

---@return Ashfall.Clay.PotteryDecals
function Decoration:getRawDecal()
    return Decals.get("raw_" .. self.id)
end

---@return Ashfall.Clay.PotteryDecals
function Decoration:getFiredDecal()
    return Decals.get("fired_" .. self.id)
end

---Apply raw decoration decal to the given scene node
---@param sceneNode niNode
function Decoration:applyRaw(sceneNode)
    self:getRawDecal():applyDecal(sceneNode)
end

---Apply fired decoration decal to the given scene node
---@param sceneNode niNode
function Decoration:applyFired(sceneNode)
    self:getFiredDecal():applyDecal(sceneNode)
end

--Remove raw decal
---@param sceneNode niNode
function Decoration:removeRaw(sceneNode)
    self:getRawDecal():removeDecal(sceneNode)
end

--Remove fired decal
---@param sceneNode niNode
function Decoration:removeFired(sceneNode)
    self:getFiredDecal():removeDecal(sceneNode)
end

---Check if the player has the required ingredients to apply this decoration
---@return boolean
function Decoration:playerHasIngredients()
    if not self.ingredients then return true end
    for ingredientId, count in pairs(self.ingredients) do
        local playerCount = common.helper.getItemCount{ reference = tes3.player, item = ingredientId }
        if playerCount < count then
            logger:debug("Player missing ingredient %s: has %d, needs %d", ingredientId, playerCount, count)
            return false
        end
    end
    return true
end


---Remove the decoration ingredients from the player's inventory
---@return boolean success
function Decoration:consumeIngredients()
    if not self.ingredients then return true end
    for ingredientId, count in pairs(self.ingredients) do
        local removeCount = common.helper.removeItem{
            reference = tes3.player,
            item = ingredientId,
            count = count,
            playSound = false,
        }
        if removeCount < count then
            logger:error("Failed to consume ingredient %s for decoration %s", ingredientId, self.id)
            return false
        end
    end
    return true
end


return Decoration