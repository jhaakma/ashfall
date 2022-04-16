local branchConfig = require("mer.ashfall.branch.branchConfig")

local this = {}

this.registerTreeBranches = function(params)
    assert(type(params.treeIds) == "table", "registerTreeBranches error: field 'ids' table expected")
    assert(type(params.branchIds) == "table", "registerTreeBranches error: field 'ids' table expected")
    for _, treeId in ipairs(params.treeIds) do
        assert(type(treeId) == "string", "registerTreeBranches error: treeId is not a string")
        branchConfig.idMapping[treeId:lower()] = {
            ids = params.branchIds or {},
            chanceNone = params.chanceNone or 50,
            minPlaced = params.minPlaced or 1,
            maxPlaced = params.maxPlaced or 2,
            minDistance = params.minDistance or 100,
            maxDistance = params.maxDistance or 300,
        }
    end
    return true
end

return this