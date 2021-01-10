local common = require("mer.ashfall.common.common")

--[[
    Dynamically adds wooden branches around the base of trees.

    - Branches placed randomly on cell change
    - Restocks per cell every week or so
    - Placed with random rotation
    - Branch appearance is randomised

]]


local function onActivate(e)
    if common.staticConfigs.branchIds[string.lower(e.target.object.id)] then
        mwscript.disable{ reference = e.target }
        mwscript.setDelete{ reference = e.target}

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

local daysToRefresh = 14
local SECONDS_TO_REFRESH = daysToRefresh * 24 * 60
local MIN_BRANCHES_PER_TREE = 0
local MAX_BRANCHES_PER_TREE = 2
local MIN_DISTANCE_FROM_TREE = 150
local MAX_DISTANCE_FROM_TREE = 400
local delay = 1
local delayMulti = 0.0005
local maxSteepness = 0.7


local cellList
local cellListVar

local function formatCellId(cell)
    return string.format("%s-%s-%s", cell.id, cell.gridX, cell.gridY)
end

--Check if a given cell requires a refresh
local function cellNeedsRefresh(cell)
    local cellId = formatCellId(cell)
    --check has been refreshed before
    if cellList[cellId] then
        --check last updated
        if cellList[cellId] < tes3.getSimulationTimestamp() - SECONDS_TO_REFRESH then
            ----mwse.log("enough time has passed")
            return true
        else
            ----mwse.log("not enough time has passed")
            return false
        end
    else
        ----mwse.log("cell has never been refreshed")
        return true
    end
end


local ignoreList

local function addBranchesToTree(tree)


    local branchNum = math.random(MIN_BRANCHES_PER_TREE, MAX_BRANCHES_PER_TREE)
    for i = 1, branchNum do
        local newDuration = (delay * delayMulti)
        timer.start{
            
            duration = newDuration,
            callback = function() 
                local position = {
                    tree.position.x + ( math.random(MIN_DISTANCE_FROM_TREE, MAX_DISTANCE_FROM_TREE) * (math.random() < 0.5 and 1 or -1) ),
                    tree.position.y + ( math.random(MIN_DISTANCE_FROM_TREE, MAX_DISTANCE_FROM_TREE) * (math.random() < 0.5 and 1 or -1) ),
                    tree.position.z + 500
                }
                local scale = math.random(80, 100) * 0.01

                --Select a branch mesh based on region
                local thisRegion = tes3.getRegion().id
                local branchGroup = common.staticConfigs.branchRegions[thisRegion] or common.staticConfigs.defaultBranchGroup
                local choice = table.choice(branchGroup) 

                local branch = tes3.createReference{
                    object = choice,
                    position = position,
                    orientation =  {0, 0, 0},
                    cell = tree.cell,
                    scale = scale
                }
                table.insert(ignoreList, branch)

                local didOrient = common.helper.orientRefToGround({ ref = branch, ignoreList = ignoreList })
                if not didOrient then 
                    branch:disable() 
                    mwscript.setDelete{ reference = branch}
                end
                if math.abs(branch.orientation.x) > maxSteepness or math.abs(branch.orientation.y) > maxSteepness then
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
            end,
        }
        delay = delay + 1
        --mwse.log("delay: %s", (delay * delayMulti))
    end
    --mwse.log("Done for Tree %s", tree.id)
end

local function getIsTree(reference)
    if common.staticConfigs.activatorConfig.list.tree:isActivator(reference.object.id) then
        return true
    end
end

local function addBranchesToCell(cell)

    for reference in cell:iterateReferences(tes3.objectType.static) do
        if getIsTree(reference) then
            table.insert(ignoreList, reference)
            addBranchesToTree(reference)
        end
    end

    cellList[formatCellId(cell)] = tes3.getSimulationTimestamp()
    cellListVar:set(cellList)
end

local function updateCells()

    if common.data and common.config.getConfig().enableBranchPlacement then
        --Get ignore List
        ignoreList = {}
        for _, cell in ipairs(tes3.getActiveCells()) do
            for reference in cell:iterateReferences() do
                if reference.object.id == "ashfall_firewood" then
                    reference:disable()
                end
                if reference.object.objectType ~= tes3.objectType.static then
                    table.insert(ignoreList, reference)
                end
            end
        end

        --Start adding branches
        for _, cell in ipairs(tes3.getActiveCells()) do
            if not cell.isInterior then
                if cellNeedsRefresh(cell) then
                    addBranchesToCell(cell)
                else
                    ----mwse.log("%s doesn't need refresh", cell.id)
                end
            else
                ----mwse.log("in interior")
            end
        end
        delay = 1
        --mwse.log("Function took %s", (os.clock() - tStart ))
    end
end

event.register("cellChanged", updateCells)

local function onLoad()
    
    cellListVar= mwse.mcm.createPlayerData{
        id = "cellBranchList",
        path = "ashfall",
        defaultSetting = {}
    }
    cellList = cellListVar:get()
    updateCells()
end

event.register("loaded", onLoad)
