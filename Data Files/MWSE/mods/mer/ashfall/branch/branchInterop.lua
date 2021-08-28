local branchConfig = require("mer.ashfall.branch.branchConfig")

local this = {}

this.registerTreeBranches = function(params)
    assert(type(params.treeIds) == "table", "registerTreeBranches error: field 'ids' table expected")
    assert(type(params.branchIds) == "table", "registerTreeBranches error: field 'ids' table expected")
    for _, treeId in ipairs(params.treeIds) do
        assert(type(treeId) == "string", "registerTreeBranches error: treeId is not a string")
        branchConfig.idMapping[treeId:lower()] = {}
        for _, id in ipairs(params.branchIds) do
            assert(type(id) == 'string', 'registerTreeBranches error: id is not a string')
            branchConfig.branchIds[id:lower()] = true
            table.insert(branchConfig.idMapping[treeId:lower()], id:lower())
        end
    end
    return true
end

return this