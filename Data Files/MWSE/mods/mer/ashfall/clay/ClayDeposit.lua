
local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("ClayDeposit")
local Dirt = require("mer.ashfall.clay.Dirt")
local RawClay = require("mer.ashfall.clay.RawClay")
--- This class manages the placement and activation of Clay Deposits
---@class Ashfall.ClayDeposit
local ClayDeposit = {
    MAX_DEPOSITS_PER_CELL = 3,
    activatorId = "ashfall_clay_deposit_01",
    respawnHours = 24 * 3,
    harvestHours = 0.25,
    harvestRealSeconds = 2,
    minClayPerHarvest = 8,
    maxClayPerHarvest = 16,
}

---@class Ashfall.Clay.DecalData
---@field path string The file path relative to "Data Files\"
---@field filename string? The full file path including "Data Files\"
---@field texture niSourceTexture?

---@class Ashfall.ClayDeposit.TerrainData
---@field trishape niTriShape
---@field chunkIndex number
---@field tileIndex number
---@field trishapeIndex number
---@field cell tes3cell

---@type table<string, Ashfall.Clay.DecalData>
local decals = {
    cracks = {
        path = "textures\\Ashfall\\mer_cracks.dds",
        texture = nil,
        filename = nil,
    }
}
decals.cracks.filename = "Data Files\\" .. decals.cracks.path
decals.cracks.texture = niSourceTexture.createFromPath(decals.cracks.path)

local function getZOffsets(trishape)
    local centerVertex = trishape.data.vertices[13]
    local offsets = {}
    for _, vertex in ipairs(trishape.data.vertices) do
        table.insert(offsets, vertex.z - centerVertex.z)
    end
    return offsets
end

---For a given terrain tile, create a clay deposit activator at its positon + Zoffset
---@param terrainData Ashfall.ClayDeposit.TerrainData
function ClayDeposit.createClayDepositAtTerrain(terrainData)
    local cell = tes3.getCell{ position = terrainData.trishape.worldTransform.translation }
    local deposit = tes3.createReference{
        object = ClayDeposit.activatorId,
        position = terrainData.trishape.worldTransform.translation + terrainData.trishape.data.vertices[13] + tes3vector3.new(0, 0, 1),
        orientation = terrainData.trishape.worldTransform.rotation:toEulerXYZ(),
    }
    deposit.data.ashfallZOffsets = getZOffsets(terrainData.trishape)
    logger:info("Created clay deposit at terrain in cell (%s)", cell.editorName)
end


function ClayDeposit.hasProcessedCell(cell)
    return common.data.clayDepositProcessedCells[cell.editorName] == true
end

function ClayDeposit.setProcessedCell(cell)
    common.data.clayDepositProcessedCells[cell.editorName] = true
end

function ClayDeposit.addClayToLoadedTerrain()
    if tes3.player.cell.isInterior then
        return
    end
    logger:info("Starting clay deposit processing for loaded terrain...")
    local start = os.clock()
    local shorelineTriShapes = ClayDeposit.getShorelineTriShapes()
    local getShorelineFinish = os.clock()
    logger:info("Found shoreline terrain shapes in %d milliseconds", (getShorelineFinish - start) * 1000)

    for cell, terrainDatas in pairs(shorelineTriShapes) do
        if #terrainDatas == 0 then
            logger:info("No shoreline terrain shapes found in cell (%s), skipping", cell.editorName)
        else
            logger:info("Creating clay deposits in loaded terrain in cell (%s)", cell.editorName)
            local max = ClayDeposit.MAX_DEPOSITS_PER_CELL
            local count = 0

            table.shuffle(terrainDatas)

            for _, terrainData in ipairs(terrainDatas) do
                count = count + 1
                if count > max then
                    logger:info("Reached max clay deposits for cell (%s), stopping", cell.editorName)
                    break
                end

                local trishape = terrainData.trishape
                if trishape.texturingProperty then
                    local beforeCreate = os.clock()
                    ClayDeposit.createClayDepositAtTerrain(terrainData)
                    local afterCreate = os.clock()
                    logger:info("Created clay deposit in %d milliseconds", (afterCreate - beforeCreate) * 1000)
                end
            end
        end
    end

    local createClayFinish = os.clock()
    common.log:info("Created clay deposits in loaded terrain in %d milliseconds", (createClayFinish - getShorelineFinish) * 1000)

    --iterate over all activators, find isClayDeposit and run setClayDepositMesh
    for _, cell in ipairs(tes3.getActiveCells()) do
        ClayDeposit.setProcessedCell(cell)
        for ref in cell:iterateReferences(tes3.objectType.activator) do
            if ClayDeposit.isClayDeposit(ref) then
                ClayDeposit.setClayDepositMesh(ref)
            end
        end
    end

    local finish = os.clock()
    common.log:info("Set clay deposit meshes in active cells in %d milliseconds", (finish - createClayFinish) * 1000)

    --log total
    common.log:info("Total clay deposit processing time: %d milliseconds", (finish - start) * 1000)
end


local minWaterLevel = -50
local maxWaterLevel = 500

function ClayDeposit.isTriShapeAtWaterline(trishape)
    local hasAbove = false
    local hasBelow = false
    local waterLevel = tes3.player.cell.waterLevel or 0
    local vertices = trishape.data.vertices
    for _, vertex in pairs(vertices) do
        local worldZ = vertex.z + trishape.worldTransform.translation.z
        --If ANY vertex is too high or too low, discard
        local relativeWaterLevel = worldZ - waterLevel
        if relativeWaterLevel > maxWaterLevel or relativeWaterLevel < minWaterLevel then
            return false
        end

        if relativeWaterLevel >= 0 then
            hasAbove = true
        end
        if relativeWaterLevel < 0 then
            hasBelow = true
        end

    end
    return hasAbove and hasBelow
end



---Check if a reference is a clay deposit activator
---@param ref tes3reference
function ClayDeposit.isClayDeposit(ref)
    return ref.object and ref.object.id:lower() == ClayDeposit.activatorId
end


---When a clay deposit activator is created, find the terrain below it and copy its mesh,
--- and replacing the copied mesh's texture with the clay decal
---@param activator tes3reference
function ClayDeposit.setClayDepositMesh(activator)
    --If disabled, check harvest time
    if activator.disabled then
        local lastHarvested = activator.data.ashfallClayDepositHarvestTime
        if lastHarvested then
            local currentTime = tes3.getSimulationTimestamp()
            local hoursSinceHarvest = currentTime - lastHarvested
            if hoursSinceHarvest >= ClayDeposit.respawnHours then
                logger:info("Respawning clay deposit: %s", activator.id)
                activator:enable()
                activator.data.ashfallClayDepositHarvestTime = nil
            end
        end
    end

    if not activator.data.ashfallZOffsets then
        return
    end
    local zOffsets = activator.data.ashfallZOffsets
    if zOffsets then
        activator.hasNoCollision = true
        --iterate over terrain vertices and set mesh vertices to match
        local mesh = activator.sceneNode:getObjectByName("CRACKS_SHAPE")
        local newData = mesh.data:copy()
        for i, zOffset in ipairs(zOffsets) do
            newData.vertices[i].z = zOffset
        end
        activator.data.ashfallMeshdata = newData
        mesh.data = newData
        mesh.data:markAsChanged()
    end
end



--- Return all terrain shapes in the cell that have at least one vert above and one below water
---@return table<tes3cell, Ashfall.ClayDeposit.TerrainData[]>
function ClayDeposit.getShorelineTriShapes()
    local activeCells = {}
    for _, cell in pairs(tes3.getActiveCells()) do
        if ClayDeposit.hasProcessedCell(cell) then
            logger:info("Cell (%s) already processed for clay deposits, skipping", cell.editorName)
        else
            activeCells[cell] = true
        end
    end

    ---@type table<string, Ashfall.ClayDeposit.TerrainData[]>
    local shorelineTriShapes = {}
    for chunkIndex, chunk in pairs(tes3.game.worldLandscapeRoot.children) do
        local cell = tes3.getCell{ position = chunk.worldTransform.translation }
        for tileIndex, tile in pairs(chunk.children) do
            if activeCells[cell] then
                shorelineTriShapes[cell] = shorelineTriShapes[cell] or {}
                for trishapeIndex, trishape in pairs(tile.children) do
                    if ClayDeposit.isTriShapeAtWaterline(trishape) then
                        if Dirt.nodeHasDirtTexture(trishape) then
                            table.insert(shorelineTriShapes[cell], {
                                trishape = trishape,
                                chunkIndex = chunkIndex,
                                tileIndex = tileIndex,
                                trishapeIndex = trishapeIndex,
                                cell = cell,
                            })
                        else
                        end
                    end
                end
            end
        end
    end
    return shorelineTriShapes
end

---Pass a terrain tile and check if it has a clay decal
---@param terrain niNode
function ClayDeposit.tileHasClayDecal(terrain)
    local texturingProperty = terrain.texturingProperty
    if texturingProperty then
        for _, map in ipairs(texturingProperty.maps) do
            local texture = map and map.texture
            local fileName = texture and texture.fileName
            if fileName == decals.cracks.filename then
                return true
            end
        end
    end
    return false
end

function ClayDeposit.pickRandomClayMiscId()
    return RawClay.rawClayId
end


return ClayDeposit