
local CraftingFramework = require("CraftingFramework")
---@class MortarAndPestle
local MortarAndPestle = {}

--Check if player has a mortar and pestle
function MortarAndPestle.playerHasMortarAndPestle()
    for _, result in pairs(CraftingFramework.CarryableContainer.getInventory()) do
        local stack = result.stack
        local isMortarAndPestle = stack.object.objectType == tes3.objectType.apparatus
            and stack.object.type == tes3.apparatusType.mortarAndPestle
        if isMortarAndPestle then
            return true
        end
    end
    return false
end

return MortarAndPestle