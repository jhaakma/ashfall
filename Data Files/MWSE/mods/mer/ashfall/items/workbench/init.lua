local CraftingFramework = require("CraftingFramework")
local workbenchConfig = require("mer.ashfall.items.workbench.config")

local Workbench = {
    MAX_DISTANCE = 1000
}

--Register reference manager for workbenches
Workbench.referenceManager = CraftingFramework.ReferenceManager:new{
    id = "Ashfall_Workbenches",
    requirements = function(_, ref)
        return not not workbenchConfig.ids[ref.object.id:lower()]
    end
}

function Workbench.isNearby()
    local isNearby = false
    Workbench.referenceManager:iterateReferences(function(ref)
        if ref.position:distance(tes3.player.position) < Workbench.MAX_DISTANCE then
            isNearby = true
            return false
        end
    end)
    return isNearby
end

return Workbench