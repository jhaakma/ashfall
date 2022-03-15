local common = require("mer.ashfall.common.common")
local logger = common.createLogger("branches")
local config = require("mer.ashfall.config").config
local branchConfig = require("mer.ashfall.branch.branchConfig")
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
    return common.staticConfigs.activatorConfig.list.tree:isActivator(reference.object.id)
end

local function formatCellId(cell)
    return cell.editorName:lower()
end


local function getBranchGroupFromRegion(tree)
    logger:debug("Attempting to get type from region of %s", tree.object.id)
    local thisRegion = tree.cell.region and tree.cell.region.id:lower()
    local branchGroup = branchConfig.branchRegions[thisRegion]
    if branchGroup then
        logger:debug("Found from region\n")
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
                logger:debug("Found from texture\n")
                return branchGroup
            end
        end
    end
end

local function getBranchTypeBytreeIdPattern(tree)
    logger:debug("Attempting to get type from pattern for id of %s", tree.object.id)
    for pattern, group in pairs(branchConfig.patternMapping) do
        if string.find(tree.object.id:lower(), pattern) then
            logger:debug("Found from Tree ID\n")
            return group
        end
    end
end

local function getBranchTypeBytreeId(tree)
    logger:debug("Attempting to get type from ID of %s", tree.object.id)
    local group = branchConfig.idMapping[tree.object.id:lower()]
    if group then
        logger:debug("Found mapping for id")
        return group
    end
end

local function getBranchGroup(tree)
    local branchGroup = getBranchTypeBytreeId(tree)
                     or getBranchGroupFromRegion(tree)
                     or getBranchTypeFromTexture(tree)
                     or getBranchTypeBytreeIdPattern(tree)
                     or branchConfig.defaultBranchGroup
    return branchGroup
end

local function getNow()
    return tes3.getSimulationTimestamp()
end
--
local cell_list
--local ignore_list
local function addBranchesToTree(tree)
    local numBranchesToPlace = math.random(branchConfig.minBranchesPerTree, branchConfig.maxBranchesPerTree)
    if numBranchesToPlace == 0 then return end
    for _ = 1, numBranchesToPlace do

        --initial position is randomly near the tree, 500 units higher than the tree's origin
        local position = {
            tree.position.x + ( math.random(branchConfig.minDistanceFromTree, branchConfig.maxDistanceFromTree) * (math.random() < 0.5 and 1 or -1) ),
            tree.position.y + ( math.random(branchConfig.minDistanceFromTree, branchConfig.maxDistanceFromTree) * (math.random() < 0.5 and 1 or -1) ),
            tree.position.z + 500
        }
        --Branches are all of slightly different sizes
        local scale = math.random(80, 100) * 0.01

        --Select a branch mesh based on region
        local branchGroup = getBranchGroup(tree)

        local choice = table.choice(branchGroup)

        --Create the branch
        local branch = tes3.createReference{
            object = choice,
            position = position,
            orientation =  {0, 0, 0},
            cell = tree.cell,
            scale = scale
        }
        --table.insert(ignore_list, branch)

        --Drop and orient the branch on the ground
        local didOrient = common.helper.orientRefToGround({ ref = branch, terrainOnly = true })
        --Check for fail conditions
        if not didOrient then
            branch:disable()
            mwscript.setDelete{ reference = branch}
        end
        --Too steep means it landed on a wall or something
        local tooSteep = math.abs(branch.orientation.x) > branchConfig.maxSteepness or math.abs(branch.orientation.y) > branchConfig.maxSteepness
        if tooSteep then
            branch:disable()
            mwscript.setDelete{ reference = branch}
            return
        end

        --Add some random orientation
        branch.orientation = {
            branch.orientation.x,
            branch.orientation.y,
            math.remap(math.random(), 0, 1, -math.pi, math.pi)
        }

    end
    logger:debug("Done for Tree %s", tree.id)
end

local function checkAndRestoreBranch(branch)
    if branch.disabled and branch.data.lastPickedUp then
        local now = getNow()
        logger:debug("Now: %s", now)
        logger:debug("branch was last picked up %s", branch.data.lastPickedUp )
        logger:debug("now - lastPickedup = %s", (now - branch.data.lastPickedUp))
        logger:debug("Seconds to refresh: %s", branchConfig.hoursToRefresh)
        if branch.data.lastPickedUp < now - branchConfig.hoursToRefresh then
            logger:debug("Re-enabling branch")
            branch:enable()
        end
    end
end

local function addBranchesToCell(cell)
    logger:debug("Adding branches to %s", cell.editorName)
    --only add branches to cells we haven't added them to before
    if not cell_list[formatCellId(cell)] then
        --Find trees and add branches
        for reference in cell:iterateReferences(tes3.objectType.static) do
            if isTree(reference) then
                logger:debug("Adding branches to %s", reference.object.id)
                addBranchesToTree(reference)
            end
        end
    end

    --Find previously placed branches and reactivate them if necessary
    for reference in cell:iterateReferences(tes3.objectType.miscItem) do
        if isBranch(reference) then
            checkAndRestoreBranch(reference)
        end
    end

    cell_list[formatCellId(cell)] = true

end

local function updateCells()
    if common.data and config.enableBranchPlacement then
        logger:debug("Branch placement enabled")

        for _, cell in ipairs(tes3.getActiveCells()) do
            if not cell.isInterior then
                addBranchesToCell(cell)
            else
                logger:debug("Cell is an interior")
            end
        end
    end
end

event.register("cellChanged", updateCells)

local function onLoad()
    logger:debug("data loaded branch placement commencing")
    common.data.cellBranchList = common.data.cellBranchList or {}
    cell_list = common.data.cellBranchList
    updateCells()
end

event.register("Ashfall:dataLoaded", onLoad)



--[[
    When activating a branchk, pick up a firewood

    Disable the branch but don't delete it: we will enable it again when enough time has passed
]]
local function onActivate(e)
    if not (e.activator == tes3.player) then return end
    if isBranch(e.target) then
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
