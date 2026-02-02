local common = require("mer.ashfall.common.common")
local logger = common.createLogger("PotteryDecals")

---@class Ashfall.Clay.PotteryDecals.data
---@field id string The unique identifier for this decal type
---@field texturePath string The path to the decal texture file
---@field uvIndex number The UV index to use for the decal (default: 1)

---@class Ashfall.Clay.PotteryDecals : Ashfall.Clay.PotteryDecals.data
---@field texture niSourceTexture The loaded texture for the decal
local PotteryDecals = {
    ---@type table<string, Ashfall.Clay.PotteryDecals>
    registeredDecals = {},
}

---Register a pottery decal type
---@param data Ashfall.Clay.PotteryDecals.data
function PotteryDecals.register(data)
    logger:assert(data.id ~= nil, "Pottery decal must have an id")
    logger:assert(data.texturePath ~= nil, "Pottery decal must have a texturePath")

    local decal = PotteryDecals:new(data)
    PotteryDecals.registeredDecals[data.id:lower()] = decal
    logger:debug("Registered pottery decal: %s", data.id)
end

---Get a registered pottery decal by ID
---@param id string
---@return Ashfall.Clay.PotteryDecals?
function PotteryDecals.get(id)
    return PotteryDecals.registeredDecals[id:lower()]
end

---Constructor
---@param data Ashfall.Clay.PotteryDecals.data
---@return Ashfall.Clay.PotteryDecals
function PotteryDecals:new(data)
    local obj = table.copy(data)
    setmetatable(obj, self)
    self.__index = self
    ---@cast obj Ashfall.Clay.PotteryDecals
    ---@
    obj.uvIndex = obj.uvIndex or 1
    obj.texture = niSourceTexture.createFromPath(obj.texturePath)
    return obj --[[@as Ashfall.Clay.PotteryDecals]]
end


function PotteryDecals:hasDecal(texturingProperty)
    if not texturingProperty then return false end

    for index, map in ipairs(texturingProperty.maps) do
        local texture = map and map.texture
        local fileName = texture and texture.fileName
        if fileName == self.texture.fileName then
            return true, index
        end
    end
    return false
end


---Apply this decal to pottery
---@param pottery tes3reference The pottery reference to apply the decal to
function PotteryDecals:applyDecal(pottery)
    if not pottery then return end
    local mesh = pottery.object.mesh
    if not mesh then return end
    local sceneNode = pottery.sceneNode
    if not sceneNode then return end

    ---@param node niNode
    for node in table.traverse{sceneNode} do
        local texturingProperty = node.texturingProperty
        if texturingProperty then
            if not self:hasDecal(texturingProperty) then
                local clonedProp = node:detachProperty(ni.propertyType.texturing):clone()
                node:attachProperty(clonedProp)
                local decal = clonedProp:addDecalMap(self.texture)
                decal.texCoordSet = self.uvIndex
            end
        end
    end
    sceneNode:updateProperties()
end

---Remove this decal from pottery
---@param pottery tes3reference The pottery reference to remove the decal from
function PotteryDecals:removeDecal(pottery)
    logger:debug("Removing decal %s from pottery %s", self.id, pottery and pottery.object.id or "nil")
    if not pottery then return end
    local mesh = pottery.object.mesh
    if not mesh then return end
    local sceneNode = pottery.sceneNode
    if not sceneNode then return end

    local didUpdate = false
    ---@param node niNode
    for node in table.traverse{sceneNode} do
        local texturingProperty = node.texturingProperty
        if texturingProperty then
            local hasDecal, mapIndex = self:hasDecal(texturingProperty)
            if hasDecal then
                logger:trace("Found decal on node, removing")
                texturingProperty:removeDecalMap(mapIndex)
                didUpdate = true
            end
        end
    end
    if didUpdate then
        logger:debug("Decals removed, updating properties")
        sceneNode:updateProperties()
    end
end

---Apply cracked decal (convenience wrapper for backwards compatibility)
---@param pottery tes3reference
function PotteryDecals.applyCrackedDecal(pottery)
    local cracks = PotteryDecals.get("cracks")
    if cracks then
        cracks:applyDecal(pottery)
    end
end

---Remove cracked decal (convenience wrapper for backwards compatibility)
---@param pottery tes3reference
function PotteryDecals.removeCrackedDecal(pottery)
    local cracks = PotteryDecals.get("cracks")
    if cracks then
        cracks:removeDecal(pottery)
    end
end

return PotteryDecals