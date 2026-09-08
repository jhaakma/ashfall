local common = require("mer.ashfall.common.common")
local logger = common.createLogger("PotteryDecals")

---@class Ashfall.Clay.PotteryDecals.data
---@field id string The unique identifier for this decal type
---@field texturePath string The path to the decal texture file
---@field uvIndex number The UV index to use for the decal (default: 1)
---@field priority number The rendering priority of the decal (higher renders below lower, default: 0)

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
    obj.uvIndex = obj.uvIndex or 1
    obj.priority = obj.priority or 0
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
---@param sceneNode niNode The scene node to apply the decal to
function PotteryDecals:applyDecal(sceneNode)
    if not sceneNode then
        logger:warn("No sceneNode provided to apply decal")
        return
    end
    logger:trace("Applying decal %s to sceneNode", self.id)

    local didUpdate = false
    ---@param node niNode
    for node in table.traverse{sceneNode} do
        local texturingProperty = node.texturingProperty
        local alphaProperty = node.alphaProperty
        local noDecalsName = node.parent.name and node.parent.name == "NO_DECALS"
        if texturingProperty and (not alphaProperty) and (not noDecalsName) then
            if not self:hasDecal(texturingProperty) then
                node.texturingProperty = node.texturingProperty:clone()
                logger:trace("Setting decal to priority %d with UV index %d", self.priority, self.uvIndex)
                local decal = node.texturingProperty:addDecalMap(self.texture, self.priority)
                decal.texCoordSet = self.uvIndex
                logger:trace("Applied decal to node")
                didUpdate = true
            end
        end
    end
    if didUpdate then
        logger:debug("Decal applied, updating properties")
        sceneNode:updateProperties()
    end
end

---Remove this decal from pottery
---@param sceneNode niNode The scene node to remove the decal from
function PotteryDecals:removeDecal(sceneNode)
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
        cracks:applyDecal(pottery.sceneNode)
    end
end

---Remove cracked decal (convenience wrapper for backwards compatibility)
---@param pottery tes3reference
function PotteryDecals.removeCrackedDecal(pottery)
    local cracks = PotteryDecals.get("cracks")
    if cracks then
        cracks:removeDecal(pottery.sceneNode)
    end
end

return PotteryDecals