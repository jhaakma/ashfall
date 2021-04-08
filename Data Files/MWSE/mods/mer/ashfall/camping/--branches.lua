local common = require("mer.ashfall.common.common")
--Branch placement configs
local daysToRefresh = 14
local SECONDS_TO_REFRESH = daysToRefresh * 24 * 60
local MIN_BRANCHES_PER_TREE = 0
local MAX_BRANCHES_PER_TREE = 2
local MIN_DISTANCE_FROM_TREE = 150
local MAX_DISTANCE_FROM_TREE = 400
local delay = 1
local delayMulti = 0.0005
local maxSteepness = 0.7
--[[
    Dynamically adds wooden branches around the base of trees.

    - Branches placed randomly on cell change
    - Picked up branches are re-enabled every couple of weeks
    - Placed with random rotation
    - Branch appearance is randomised

]]
local function isBranch(reference)
    return common.staticConfigs.branchIds[reference.object.id:lower()]
end

local function isTree(reference)
    return common.staticConfigs.activatorConfig.list.tree:isActivator(reference.object.id)
end
local function formatCellId(cell)
    return cell.editorName:lower()
end
--
local cell_list
local ignore_list
local function addBranchesToTree(tree)
    local numBranchesToPlace = math.random(MIN_BRANCHES_PER_TREE, MAX_BRANCHES_PER_TREE)
    for _ = 1, numBranchesToPlace do
        local newDuration = (delay * delayMulti)
        timer.start{
            duration = newDuration,
            callback = function()
                --initial position is randomly near the tree, 500 units higher than the tree's origin
                local position = {
                    tree.position.x + ( math.random(MIN_DISTANCE_FROM_TREE, MAX_DISTANCE_FROM_TREE) * (math.random() < 0.5 and 1 or -1) ),
                    tree.position.y + ( math.random(MIN_DISTANCE_FROM_TREE, MAX_DISTANCE_FROM_TREE) * (math.random() < 0.5 and 1 or -1) ),
                    tree.position.z + 500
                }
                --Branches are all of slightly different sizes
                local scale = math.random(80, 100) * 0.01

                --Select a branch mesh based on region
                local thisRegion = tes3.getRegion().id
                local branchGroup = common.staticConfigs.branchRegions[thisRegion] or common.staticConfigs.defaultBranchGroup
                local choice = table.choice(branchGroup) 

                --Create the branch
                local branch = tes3.createReference{
                    object = choice,
                    position = position,
                    orientation =  {0, 0, 0},
                    cell = tree.cell,
                    scale = scale
                }
                table.insert(ignore_list, branch)

                --Drop and orient the branch on the ground
                local didOrient = common.helper.orientRefToGround({ ref = branch, ignore_list = ignore_list })
                --Check for fail conditions
                if not didOrient then 
                    branch:disable() 
                    mwscript.setDelete{ reference = branch}
                end
                --Too steep means it landed on a wall or something
                local tooSteep = math.abs(branch.orientation.x) > maxSteepness or math.abs(branch.orientation.y) > maxSteepness
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
                --set lastUpdated so it can be re-enabled after some time
                branch.data.lastUpdated = tes3.getSimulationTimestamp()
            end,
        }
        delay = delay + 1
        common.log:debug("delay: %s", (delay * delayMulti))
    end
    common.log:debug("Done for Tree %s", tree.id)
end

local function checkAndRestoreBranch(branch)
    if branch.disabled and branch.data.lastPickedUp then
        if branch.data.lastPickedUp < tes3.getSimulationTimestamp() - SECONDS_TO_REFRESH then
            common.log:debug("Re-enabling branch")
            branch:enable()
        end
    end
end

local function addBranchesToCell(cell)

    --only add branches to cells we haven't added them to before
    if not cell_list[formatCellId(cell)] then
        --Find trees and add branches
        for reference in cell:iterateReferences(tes3.objectType.static) do
            if isTree(reference) then
                common.log:debug("Adding branches to %s", reference.object.id)
                table.insert(ignore_list, reference)
                addBranchesToTree(reference)
            end
        end
    end

    --Find previously placed branches and reactivate them if necessary
    for reference in cell:iterateReferences(tes3.objectType.activator) do
        if isBranch(reference) then
            checkAndRestoreBranch(reference)
        end
    end

    cell_list[formatCellId(cell)] = true

end

local function updateCells()

    if common.data and common.config.getConfig().enableBranchPlacement then
        --Get ignore List
        ignore_list = {}
        for _, cell in ipairs(tes3.getActiveCells()) do
            for reference in cell:iterateReferences() do
                if reference.object.objectType ~= tes3.objectType.static then
                    common.log:trace("Adding %s to ignore list", reference.object.id)
                    table.insert(ignore_list, reference)
                end
            end
        end

        --Start adding branches
        delay = 1
        for _, cell in ipairs(tes3.getActiveCells()) do
            if not cell.isInterior then
                addBranchesToCell(cell)
            else
                common.log:debug("Cell is an interior")
            end
        end
    end
end

event.register("cellChanged", updateCells)

local function onLoad()
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
    if isBranch(e.target) then
        e.target.data.lastPickedUp = tes3.getSimulationTimestamp()
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
