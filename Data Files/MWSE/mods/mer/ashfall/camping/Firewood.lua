local common = require("mer.ashfall.common.common")
local Material = require("CraftingFramework").Material
local Campfire = require("mer.ashfall.camping.campfire.Campfire")
---Class for managing firewood as fuel
---@class Ashfall.Camping.Firewood
local Firewood = {}

function Firewood.getWoodFuel()
    local survivalEffect = common.helper.clampmap(common.skills.survival.current, 0, 100, 1, 1.5)
    return common.staticConfigs.firewoodFuelMulti * survivalEffect
end

function Firewood.getFirewoodCount()
    -- local firewood = tes3.getObject(common.staticConfigs.objectIds.firewood)
    -- return common.helper.getItemCount{ reference = tes3.player, item = firewood }
    local firewoodMaterial = Material.getMaterial("wood")
    return firewoodMaterial:getCount()
end

function Firewood.getFirewoodCapacity(reference)
    local fuelLevel = reference.data.fuelLevel or 0
    return math.floor((Campfire.getMaxFuel(reference.baseObject.id) - fuelLevel) / Firewood.getWoodFuel())
end

function Firewood.canAddFireWoodToCampfire(reference)
    return Firewood.getFirewoodCapacity(reference) > 0
end

return Firewood