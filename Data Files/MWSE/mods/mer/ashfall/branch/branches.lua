local common = require("mer.ashfall.common.common")
local logger = common.createLogger("branches")
local config = require("mer.ashfall.config").config
local ActivatorController = require("mer.ashfall.activators.activatorController")
local branchConfig = require("mer.ashfall.branch.branchConfig")
local StaggeredRefProcessor = require("mer.ashfall.common.StaggeredRefProcessor")
--Branch placement configs


--[[
    Dynamically adds wooden branches around the base of trees.

    - Branches placed randomly on cell change
    - Picked up branches are re-enabled every couple of weeks
    - Placed with random rotation
    - Branch appearance is randomised

]]
local function isBranch(reference)
    return branchConfig.branchIds[reference.object.id:lower()]
end

local function isTree(reference)
    return common.staticConfigs.activatorConfig.list.tree:isActivator(reference)
end

local function isWaterplant(reference)
    local waterPlants = {
        flora_kelp_01 = true,
        flora_kelp_02 = true,
        flora_kelp_03 = true,
        flora_kelp_04 = true,
        in_cave_plant00 = true,
        in_cave_plant01 = true
    }
    return waterPlants[reference.object.id:lower()]
end



local function isSource(reference)
    return common.staticConfigs.activatorConfig.list.tree:isActivator(reference)
        or common.staticConfigs.activatorConfig.list.deadTree:isActivator(reference)
        or common.staticConfigs.activatorConfig.list.stoneSource:isActivator(reference)
        or isWaterplant(reference)
end

local function formatCellId(cell)
    return cell.editorName:lower()
end


local function getBranchGroupFromRegion(tree)
    logger:debug("Attempting to get type from region of %s", tree.object.id)
    local thisRegion = tree.cell.region and tree.cell.region.id:lower()
    local branchGroup = branchConfig.branchRegions[thisRegion]
    if branchGroup then
        logger:debug("Found branch group from region: %s\n", json.encode(branchGroup, { indent = true }))
        return branchGroup
    end
end

local function getBranchTypeFromTexture(tree)
    logger:debug("Attempting to get type from texture of %s", tree.object.id)
    for node in common.helper.traverseRoots{tree.sceneNode} do
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

local function getBranchTypeBytreeIdPattern(tree)
    logger:debug("Attempting to get type from pattern for id of %s", tree.object.id)
    for pattern, branchGroup in pairs(branchConfig.patternMapping) do
        local lowerId = tree.object.id:lower()
        if string.find(lowerId, pattern) then
            branchConfig.idMapping[lowerId] = branchGroup
            logger:debug("Found branch group from pattern. Adding to id map: %s\n", json.encode(branchGroup, { indent = true }))
            return branchGroup
        end
    end
end

local function getBranchTypeBytreeId(tree)
    logger:debug("Attempting to get type from ID of %s", tree.object.id)
    local branchGroup = branchConfig.idMapping[tree.object.id:lower()]
    if branchGroup then
        logger:debug("Found branch group from id: %s\n", json.encode(branchGroup, { indent = true }))
        return branchGroup
    end
end

local function getByActivatorType(debris)
    local activator = ActivatorController.getRefActivator(debris)
    if activator then
        local group =  branchConfig.activatorTypeGroups[activator.type]
        if group then
            logger:debug("Found branch group from activator type: %s", activator.type)
            return group
        end
    end
end

local function getBranchGroup(tree)
    local branchGroup = getBranchTypeBytreeId(tree)
                     or getBranchTypeBytreeIdPattern(tree)
                     or getBranchGroupFromRegion(tree)
                     or getBranchTypeFromTexture(tree)
                     or getByActivatorType(tree)
                     or branchConfig.defaultBranchGroup
    return branchGroup
end

local function getNow()
    return tes3.getSimulationTimestamp()
end

local function rollForNone(branchGroup)
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

local function getDropCount(branchGroup)
    local amount = math.random(branchGroup.minPlaced, branchGroup.maxPlaced)
    local multiplier = config.naturalMaterialsMultiplier / 100
    amount = math.floor(amount * multiplier)
    return amount
end

---@param tree tes3reference
---@param cell tes3cell
local function addBranchesToTree(tree, cell)

    --Select a branch mesh based on region
    local branchGroup = getBranchGroup(tree)

    if rollForNone(branchGroup) then
        common.log:debug("Roll failed, not placing debris")
        return
    end
    local debrisNum = getDropCount(branchGroup)
    if debrisNum == 0 then return end

    for _ = 1, debrisNum do
        --initial position is randomly near the tree, 500 units higher than the tree's origin
        local position = tes3vector3.new(
            tree.position.x + ( math.random(branchGroup.minDistance, branchGroup.maxDistance) * (math.random() < 0.5 and 1 or -1) ),
            tree.position.y + ( math.random(branchGroup.minDistance, branchGroup.maxDistance) * (math.random() < 0.5 and 1 or -1) ),
            tree.position.z + 500
        )

        if not tes3.getCell{ position = position } then
            logger:warn("Position is not in a valid cell, skipping")
        else
            --Branches are all of slightly different sizes
            local scale = math.random(80, 100) * 0.01
            local choice = table.choice(branchGroup.ids)
            --Create the branch
            common.log:debug("Creating debris (%s) to place at source (%s) at position (%s)", choice, tree, json.encode(position))
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
            end

            --Add some random orientation
            branch.orientation = tes3vector3.new(
                branch.orientation.x,
                branch.orientation.y,
                math.remap(math.random(), 0, 1, -math.pi, math.pi))
            logger:debug("Finished placing %s debris %s", debrisNum, choice)
        end
    end
    logger:debug("Done for Tree %s\n", tree.id)
end

local function checkAndRestoreBranch(branch)
    if branch.disabled and branch.data.lastPickedUp then
        local now = getNow()
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

local treeProcessor = StaggeredRefProcessor.new{
    callback = function(reference)
        logger:debug("Adding branches to %s in cell %s", reference.object.id, reference.cell.editorName)
        addBranchesToTree(reference, reference.cell)
    end,
    interval = 0.05,
    refsPerFrame = 1,
    logger = logger,
}


local function addBranchesToCell(cell)
    logger:debug("Adding branches to %s", cell.editorName)
    --only add branches to cells we haven't added them to before
    if not common.data.cellBranchList[formatCellId(cell)] then
        --Find trees and add branches
        for reference in cell:iterateReferences(tes3.objectType.static) do
            if isSource(reference) then
                logger:debug("Registering Branch source to %s in cell %s", reference.object.id, cell.editorName)
                treeProcessor:add(reference)
            end
        end
    end

    --Find previously placed branches and reactivate them if necessary
    for reference in cell:iterateReferences(tes3.objectType.miscItem) do
        if isBranch(reference) then
            checkAndRestoreBranch(reference)
        end
    end
    common.data.cellBranchList[formatCellId(cell)] = true
end

local function doBranches()
    if common.data and config.enableBranchPlacement then
        logger:debug("Adding branches to active cells")
        for _, cell in ipairs(tes3.getActiveCells()) do
            addBranchesToCell(cell)
        end
    end
end

local function doTrees()
    for _, cell in ipairs(tes3.getActiveCells()) do
        for reference in cell:iterateReferences(tes3.objectType.static) do
            if isSource(reference) then
                addBranchesToTree(reference, reference.cell)
            end
        end
    end
end


event.register("cellChanged", function(e)
    if e.cell.isInterior then
        logger:debug("Skipping interior cell %s", e.cell.editorName)
        return
    end

    doBranches()
    if e.previousCell and e.previousCell.isInterior then
        --We came from an interior, do the branches immediately
        doTrees()
    else
        --We came from an exterior, stagger the branch placement
        treeProcessor:start()
    end
end)

local function onLoad()
    logger:debug("data loaded branch placement commencing")
    common.data.cellBranchList = common.data.cellBranchList or {}

    if tes3.player.cell.isInterior then
        logger:debug("Skipping interior cell %s", tes3.player.cell.editorName)
        return
    end

    doBranches()
    doTrees()
end
event.register("Ashfall:dataLoaded", onLoad)


--[[
    When activating a branch, pick up a firewood

    Disable the branch but don't delete it: we will enable it again when enough time has passed
]]
local function onActivate(e)
    if not (e.activator == tes3.player) then return end
    if string.startswith(e.target.object.id:lower(), "ashfall_branch_") then
        e.target.data.lastPickedUp = getNow()
        e.target:disable()

        tes3.addItem{
            reference = tes3.player,
            item = common.staticConfigs.objectIds.firewood,
            playSound = true,
        }
        tes3.messageBox("Collected 1 firewood.")
        return false
    end
end

event.register("activate", onActivate)
