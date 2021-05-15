--[[
    Register items that can be quickkeyed
]]
local common = require("mer.ashfall.common.common")

local function isBottle(e)
    return common.staticConfigs.bottleList[e.item.id:lower()]
end

event.register("filterInventorySelect", function(e)
    if isBottle(e) then e.filter = true end
end, { filter = "quick" })