---@class Ashfall.Bushcrafting.FeatureFlags
local FeatureFlags = {}

local flags = mwse.loadConfig("ashfall-bushcrafting-experimental", {
    brickWall = false,
    cookingPot = false,
})

---@param id string
---@return boolean
function FeatureFlags.isEnabled(id)
    return flags[id] == true
end

---@param id string
---@param label string
---@return CraftingFramework.CustomRequirement.data
function FeatureFlags.createRequirement(id, label)
    return {
        getLabel = function()
            return label
        end,
        check = function()
            if FeatureFlags.isEnabled(id) then
                return true
            end
            return false, "This experimental recipe is not enabled."
        end,
    }
end

return FeatureFlags
