local common = require("mer.ashfall.common.common")
local logger = common.createLogger("Debris")
local config = require("mer.ashfall.config").config
local branchConfig = require("mer.ashfall.branch.branchConfig")
local StaggeredRefProcessor = require("mer.ashfall.common.StaggeredRefProcessor")
local ActivatorController = require("mer.ashfall.activators.activatorController")

---@class Ashfall.Debris
---@field enterCell fun(self: Ashfall.Debris, params: Ashfall.Debris.enterCellParams)
---@field private processor StaggeredRefProcessor
local Debris = {

}

Debris.processor = StaggeredRefProcessor.new{
    callback = function(reference)
        Debris:processSource(reference)
    end,
    interval = 0.05,
    refsPerFrame = 1,
    logger = logger,
}

---@class Ashfall.Debris.enterCellParams
---@field immediate? boolean If true, the debris will be added immediately. If false, it will be added after a delay.


---@param params Ashfall.Debris.enterCellParams
function Debris:enterCell(params)
    logger:debug("Entered Cell")
    Debris.processor:start()
    common.data.cellBranchList = common.data.cellBranchList or {}
    for _, cell in ipairs(tes3.getActiveCells()) do
        self:restoreDebrisInCell(cell)
        self:registerDebrisSources(cell)
    end
    if params.immediate then
        self.processor:processAll()
    end
end

---@param branch tes3reference
function Debris:restoreDebris(branch)
    if branch.disabled and branch.data.lastPickedUp then
        local now = tes3.getSimulationTimestamp()
        logger:debug("Now: %s", now)
        logger:debug("branch was last picked up %s", branch.data.lastPickedUp )
        logger:debug("now - lastPickedup = %s", (now - branch.data.lastPickedUp))
        logger:debug("Hours to refresh: %s", branchConfig.hoursToRefresh)
        if branch.data.lastPickedUp < now - branchConfig.hoursToRefresh then
            logger:debug("Re-enabling branch")
            branch:enable()
        end
    end
end

function Debris:restoreDebrisInCell(cell)
    if not Debris.checkCellProcessed(cell) then
        logger:debug("Cell %s has not been processed yet, skipping", cell.id)
        return
    end
    for reference in cell:iterateReferences(tes3.objectType.miscItem) do
        if Debris.isDebris(reference) then
            Debris:restoreDebris(reference)
        end
    end
end

---Register derbis sources for processing in this cell
function Debris:registerDebrisSources(cell)
    if Debris.checkCellProcessed(cell) then
        logger:debug("Cell %s has already been processed, skipping", cell.id)
        return
    end

    for reference in cell:iterateReferences(tes3.objectType.static) do
        if Debris.isDebrisSource(reference) then
            logger:debug("Adding %s to processor", reference.id)
            Debris.processor:add(reference)
        end
    end

    Debris.setCellProcessed(cell)
end

---@param debrisSourceRef tes3reference
function Debris:processSource(debrisSourceRef)
    logger:debug("Processing tree %s", debrisSourceRef.id)
    local cell = debrisSourceRef.cell
    --Select a branch mesh based on region
    local branchGroup = Debris.getBranchGroup(debrisSourceRef)
    if Debris.rollForNone(branchGroup) then
        common.log:debug("Roll failed, not placing debris")
        return
    end
    local debrisNum = Debris.getDropCount(branchGroup)
    if debrisNum == 0 then
        logger:debug("getDropCount returned 0, nothing to place")
        return
    else
        logger:debug("placing %s debris", debrisNum)
    end

    for _ = 1, debrisNum do
        --initial position is randomly near the source, 500 units higher than the source's origin
        local position = tes3vector3.new(
            debrisSourceRef.position.x + ( math.random(branchGroup.minDistance, branchGroup.maxDistance) * (math.random() < 0.5 and 1 or -1) ),
            debrisSourceRef.position.y + ( math.random(branchGroup.minDistance, branchGroup.maxDistance) * (math.random() < 0.5 and 1 or -1) ),
            debrisSourceRef.position.z + 500
        )

        if not tes3.getCell{ position = position } then
            logger:warn("Position is not in a valid cell, skipping")
        else
            --Branches are all of slightly different sizes
            local scale = math.random(80, 100) * 0.01
            local choice = table.choice(branchGroup.ids)
            --Create the branch
            common.log:debug("Creating debris (%s) to place at source (%s) at position (%s)", choice, debrisSourceRef, json.encode(position))
            local branch = tes3.createReference{
                object = choice,
                position = position,
                orientation = tes3vector3.new(0, 0, 0),
                cell = cell,
                scale = scale
            }
            --Drop and orient the branch on the ground
            local didOrient = common.helper.orientRefToGround{
                ref = branch,
                terrainOnly = true,
                maxDistance = 5000
            }

            --Check for fail conditions
            if not didOrient then
                branch:disable()
                ---@diagnostic disable-next-line
                mwscript.setDelete{ reference = branch}
            end
            --Too steep means it landed on a wall or something
            local tooSteep = math.abs(branch.orientation.x) > branchConfig.maxSteepness or math.abs(branch.orientation.y) > branchConfig.maxSteepness
            if tooSteep then
                common.log:debug("Too steep, deleting debris")
                branch:disable()
                ---@diagnostic disable-next-line
                mwscript.setDelete{ reference = branch}
                return
            else
                --Add some random orientation
                branch.orientation = tes3vector3.new(
                    branch.orientation.x,
                    branch.orientation.y,
                    math.remap(math.random(), 0, 1, -math.pi, math.pi))
                logger:debug("Finished placing %s debris %s", debrisNum, choice)
            end
        end
    end
    logger:debug("Done for source %s\n", debrisSourceRef.id)
end

---Check if a cell has already been processed for debris registration
function Debris.checkCellProcessed(cell)
    local cellId = cell.editorName:lower()
    return common.data.cellBranchList[cellId] == true
end

function Debris.setCellProcessed(cell)
    local cellId = cell.editorName:lower()
    common.data.cellBranchList[cellId] = true
end

function Debris.rollForNone(branchGroup)
    local roll = math.random(100)
    common.log:debug("Rolling for none: %s", roll)
    local multiplier = config.naturalMaterialsMultiplier / 100
    roll = roll * multiplier
    common.log:debug("Roll after multiplier: %s", roll)
    common.log:debug("Chance for none: %s", branchGroup.chanceNone)
    local isNone = roll < branchGroup.chanceNone
    common.log:debug("Is none: %s", isNone)
    return isNone
end

---Check if a given reference is a debris
function Debris.isDebris(reference)
    return branchConfig.branchIds[reference.object.id:lower()]
end

---Check if a given reference is a source of debris
function Debris.isDebrisSource(reference)
    local waterPlants = {
        flora_kelp_01 = true,
        flora_kelp_02 = true,
        flora_kelp_03 = true,
        flora_kelp_04 = true,
        in_cave_plant00 = true,
        in_cave_plant01 = true
    }
    return common.staticConfigs.activatorConfig.list.tree:isActivator(reference)
        or common.staticConfigs.activatorConfig.list.deadTree:isActivator(reference)
        or common.staticConfigs.activatorConfig.list.stoneSource:isActivator(reference)
        or waterPlants[reference.object.id:lower()]
end

---@param debrisSourceRef tes3reference
function Debris.getBranchGroup(debrisSourceRef)
    local branchGroup = Debris._getBranchTypeBytreeId(debrisSourceRef)
                     or Debris._getBranchTypeBytreeIdPattern(debrisSourceRef)
                     or Debris._getBranchGroupFromRegion(debrisSourceRef)
                     or Debris._getBranchTypeFromTexture(debrisSourceRef)
                     or Debris._getBranchGroupByActivatorType(debrisSourceRef)
                     or branchConfig.defaultBranchGroup
    return branchGroup
end

function Debris.getDropCount(branchGroup)
    local amount = math.random(branchGroup.minPlaced, branchGroup.maxPlaced)
    local multiplier = config.naturalMaterialsMultiplier / 100
    amount = math.floor(amount * multiplier)
    return amount
end

---@param debrisSourceRef tes3reference
function Debris._getBranchGroupFromRegion(debrisSourceRef)
    logger:debug("Attempting to get type from region of %s", debrisSourceRef.object.id)
    local thisRegion = debrisSourceRef.cell.region and debrisSourceRef.cell.region.id:lower()
    local branchGroup = branchConfig.branchRegions[thisRegion]
    if branchGroup then
        logger:debug("Found branch group from region: %s\n", json.encode(branchGroup, { indent = true }))
        return branchGroup
    end
end

---@param debrisSourceRef tes3reference
function Debris._getBranchTypeFromTexture(debrisSourceRef)
    logger:debug("Attempting to get type from texture of %s", debrisSourceRef.object.id)
    for node in common.helper.traverseRoots{debrisSourceRef.sceneNode} do
        if node.RTTI.name == "NiTriShape" then
            local texturing_property = node:getProperty(0x4)
            if texturing_property then
                local filePath = texturing_property.maps[1].texture.fileName
                filePath = string.sub(filePath, 1, -5):lower()
                logger:debug(filePath)
                local branchGroup = branchConfig.textureMapping[filePath]
                if branchGroup then
                    logger:debug("Found branch group from texture: %s\n", json.encode(branchGroup, { indent = true }))
                    return branchGroup
                end
            end
        end
    end
end

---@param debrisSourceRef tes3reference
function Debris._getBranchTypeBytreeIdPattern(debrisSourceRef)
    logger:debug("Attempting to get type from pattern for id of %s", debrisSourceRef.object.id)
    for pattern, branchGroup in pairs(branchConfig.patternMapping) do
        local lowerId = debrisSourceRef.object.id:lower()
        if string.find(lowerId, pattern) then
            branchConfig.idMapping[lowerId] = branchGroup
            logger:debug("Found branch group from pattern. Adding to id map: %s\n", json.encode(branchGroup, { indent = true }))
            return branchGroup
        end
    end
end

---@param debrisSourceRef tes3reference
function Debris._getBranchTypeBytreeId(debrisSourceRef)
    logger:debug("Attempting to get type from ID of %s", debrisSourceRef.object.id)
    local branchGroup = branchConfig.idMapping[debrisSourceRef.object.id:lower()]
    if branchGroup then
        logger:debug("Found branch group from id: %s\n", json.encode(branchGroup, { indent = true }))
        return branchGroup
    end
end

---@param debrisRef tes3reference
function Debris._getBranchGroupByActivatorType(debrisRef)
    local activator = ActivatorController.getRefActivator(debrisRef)
    if activator then
        local group =  branchConfig.activatorTypeGroups[activator.type]
        if group then
            logger:debug("Found branch group from activator type: %s", activator.type)
            return group
        end
    end
end

return Debris