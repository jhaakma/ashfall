local common = require("mer.ashfall.common.common")
local logger = common.createLogger("gearPlacement")
local placementConfig = require("mer.ashfall.gearPlacement.config")
local Orienter = require("CraftingFramework.components.Orienter")
--[[
    Orients a placed object and lowers it into the ground so it lays flat against the terrain,
]]

local function onDropGear(e)

    local gearValues = placementConfig[string.lower(e.reference.object.id)]
    if gearValues or (e.reference.object.sourceMod and e.reference.object.sourceMod:lower() == "ashfall.esp") then
        gearValues = gearValues or { maxSteepness = 0.5 }
        local hasWater = e.reference.data and e.reference.data.waterAmount and e.reference.data.waterAmount > 0
        local maxSteepness = gearValues.maxSteepness
        if hasWater then
            maxSteepness = 0
        end
        if gearValues.maxSteepness then
            Orienter.orientRefToGround{ ref = e.reference, maxSteepness = maxSteepness }
        end
        if gearValues.drop then
            logger:debug("Dropping %s by %s", e.reference.object.name, gearValues.drop)
            e.reference.position = {
                e.reference.position.x,
                e.reference.position.y,
                e.reference.position.z - gearValues.drop,
            }
        end
        event.trigger("Ashfall:GearDropped", e)
    end
end
event.register("itemDropped", onDropGear, { priority = 100})


