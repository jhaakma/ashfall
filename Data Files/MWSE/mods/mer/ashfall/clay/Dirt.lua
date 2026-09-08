local common = require("mer.ashfall.common.common")
local logger = common.createLogger("Dirt")

--- This class handles the registration and detection of dirt types based on ground textures.
---@class Ashfall.Dirt
local Dirt = {
    ---@type table<string, Ashfall.DirtType>
    registeredDirtTypes = {}
}

---@class Ashfall.DirtType.data
---@field id string Unique identifier for the dirt type
---@field name string Display name for the dirt type
---@field textures string[] List of texture file names that match the dirt type. Case insensitive, does not include file extension.

---@class Ashfall.DirtType : Ashfall.DirtType.data
---@field textures table<string, boolean> List of texture file names that match the dirt type. Case insensitive, does not include file extension.

---Register a dirt type
---@param data Ashfall.DirtType.data
function Dirt.registerDirtType(data)
    logger:assert(data.id ~= nil, "Dirt type missing id")
    logger:assert(data.name ~= nil, "Dirt type missing name")
    logger:assert(data.textures ~= nil, "Dirt type missing textures")

    ---@type Ashfall.DirtType
    local dirtType
    if Dirt.registeredDirtTypes[data.id] then
        logger:debug("Merging existing dirt type: %s", data.id)
        dirtType = Dirt.registeredDirtTypes[data.id]
    else
        dirtType = table.copy(data) --[[@as Ashfall.DirtType]]
        dirtType.textures = {}
    end

    for _, texture in ipairs(data.textures) do
        local path = ("data files\\textures\\" .. texture .. ".dds"):lower()
        dirtType.textures[path] = true
    end

    logger:info("Registered dirt type: %s", data.id)
    Dirt.registeredDirtTypes[data.id] = dirtType
end


local function printGroundTextureInfo(groundTextureInfo)
    if not groundTextureInfo then
        logger:debug("No ground texture info")
        return
    end
    logger:debug("Blend: %s", groundTextureInfo.blend)
    logger:debug("Object: %s", groundTextureInfo.object)
    logger:debug("Textures: ")
    for i, map in ipairs(groundTextureInfo.texturingProperty.maps) do
        if map and map.texture then
            logger:debug("%s: %s", i, map.texture.fileName)
        end
    end
end

local function filepathToName(filePath)
    logger:debug("Getting name from path: %s", filePath)
    local filename = filePath:match("([^/\\]+)$")
    logger:debug("Filename: %s", filename)
    local nameWithoutExtension = filename:gsub("%.%w+$", "")
    logger:debug("Name without extension: %s", nameWithoutExtension)
    return nameWithoutExtension:lower()
end

---@class Ashfall.getDirtLookingAt.results
---@field texture niRenderedTexture|niSourceTexture
---@field dirtType Ashfall.DirtType
---@field intersection tes3vector3
---@field normal tes3vector3

--- Get the dirt type the player is currently looking at
---@return  Dirt.getDirtLookingAt.results?
function Dirt.getDirtLookingAt()
    local groundTextureInfo = common.helper.getGroundTextureInfo{
        maxDistance = tes3.getPlayerActivationDistance()
    }
    if groundTextureInfo then
        printGroundTextureInfo(groundTextureInfo)
        local textureMaps = groundTextureInfo.texturingProperty.maps

        for _, dirtType in pairs(Dirt.registeredDirtTypes) do
            --Check base map
            local baseMap = textureMaps[1]
            if baseMap and baseMap.texture then
                local texturePath = baseMap.texture.fileName:lower()
                logger:debug("Checking texture: %s", texturePath)
                if dirtType.textures[texturePath] then
                    if groundTextureInfo.blend < 0.5 then
                        logger:debug("Found dirt base texture: %s, blend: %s",
                            baseMap.texture.fileName, groundTextureInfo.blend)
                        ---@type Ashfall.getDirtLookingAt.results
                        local results = {
                            texture = baseMap.texture,
                            dirtType = dirtType,
                            intersection = groundTextureInfo.intersection,
                            normal = groundTextureInfo.normal
                        }
                        return results
                    else
                        logger:debug("Found dirt base texture but not blended enough: %s, blend: %s",
                            baseMap.texture.fileName, groundTextureInfo.blend)
                    end
                end
            end
            --Check decal map
            local decalMap = textureMaps[2]
            if decalMap and decalMap.texture then
                local texturePath = decalMap.texture.fileName:lower()
                logger:debug("Checking texture: %s", texturePath)
                if dirtType.textures[texturePath] then
                    if groundTextureInfo.blend >= 0.5 then
                        logger:debug("Found dirt decal texture: %s, blend: %s",
                            decalMap.texture.fileName, groundTextureInfo.blend)
                        ---@type Ashfall.getDirtLookingAt.results
                        local results = {
                            texture = decalMap.texture,
                            dirtType = dirtType,
                            intersection = groundTextureInfo.intersection,
                            normal = groundTextureInfo.normal
                        }
                        return results
                    else
                        logger:debug("Found dirt decal texture but not blended enough: %s, blend: %s",
                            decalMap.texture.fileName, groundTextureInfo.blend)
                    end
                end
            end
        end
    end
end



---Check if a node has a dirt texture
---@param node niNode
---@return boolean
function Dirt.nodeHasDirtTexture(node)
    local texturingProperty = node.texturingProperty
    if texturingProperty then
        for _, map in ipairs(texturingProperty.maps) do
            local texture = map and map.texture
            local fileName = texture and texture.fileName
            if fileName then
                for _, dirtType in pairs(Dirt.registeredDirtTypes) do
                    if dirtType.textures[fileName:lower()] then
                        return true
                    end
                end
            end
        end
    end
    return false
end

return Dirt