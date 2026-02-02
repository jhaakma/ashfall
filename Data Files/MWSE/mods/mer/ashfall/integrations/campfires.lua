local interop = require("mer.ashfall.interop")

---@type Ashfall.Campfire.CampfireData[]
local campfires = {

}

for _, data in ipairs(campfires) do
    interop.registerCampfire(data)
end