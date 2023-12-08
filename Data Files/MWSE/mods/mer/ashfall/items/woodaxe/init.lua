local common = require("mer.ashfall.common.common")
local logger = common.createLogger("WoodAxe")
local backpackConfig = require("mer.ashfall.items.backpack.config")

---@class Ashfall.WoodAxe
local WoodAxe = {}
WoodAxe.harvestConfig = require("mer.ashfall.harvest.config").woodaxes

---@class Ashfall.WoodAxe.registerParams
---@field id string the id of the woodaxe
---@field effectiveness number Multiplier for how fast it chops trees
---@field degradeMulti number Multiplier for how fast it degrades

function WoodAxe.getHarvestConfig(id)
    return WoodAxe.harvestConfig[id:lower()]
end

function WoodAxe.canWearOnBackpack(id)
    return backpackConfig.woodAxes[id:lower()]
end

---Register a woodaxe to display on backpacks
---The mesh must be configured to display properly
---@param id string The ID of the woodaxe
function WoodAxe.registerForBackpack(id)
    backpackConfig.woodAxes[id:lower()] = true
end

---Register a woodaxe object for harvesting
---Determines how effective it is at chopping trees
---@param id string The ID of the woodaxe
function WoodAxe.registerForHarvesting(id)
    assert(type(id) == 'string', "registerWoodAxes: id must be a string")
    logger:debug(id)
    WoodAxe.harvestConfig[id:lower()] = {
        effectiveness = 1.5,
        degradeMulti = 0.5,
    }
end


---@param e objectCreatedEventData
event.register("objectCreated", function(e)
    if not e.copiedFrom then return end

    if WoodAxe.getHarvestConfig(e.copiedFrom.id) then
        logger:info("objectCreated: registering woodaxe %s", e.object.id)
        WoodAxe.registerForBackpack(e.object.id)
        common.data.woodAxesForHarvesting[e.object.id:lower()] = true
    end

    if WoodAxe.canWearOnBackpack(e.copiedFrom.id) then
        logger:info("objectCreated: registering woodaxe %s", e.object.id)
        WoodAxe.registerForHarvesting(e.object.id)
        common.data.woodAxesForBackpack[e.object.id:lower()] = true
    end
end)

event.register("loaded", function(e)
    --Register copied fishing rods
    for id in pairs(common.data.woodAxesForBackpack) do
        logger:info("Registering copied woodaxe %s", id)
        WoodAxe.registerForBackpack(id)
    end
    for id in pairs(common.data.woodAxesForHarvesting) do
        logger:info("Registering copied woodaxe %s", id)
        WoodAxe.registerForHarvesting(id)
    end
end)


return WoodAxe