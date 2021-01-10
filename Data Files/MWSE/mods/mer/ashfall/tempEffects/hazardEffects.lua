local this = {}
local common = require("mer.ashfall.common.common")
local staticConfigs = common.staticConfigs
--Register heat source
local temperatureController = require("mer.ashfall.temperatureController")
temperatureController.registerExternalHeatSource("hazardTemp")

local maxDistance = 1000
local function getHeat(ref)
    local hazardTemp = staticConfigs.heatSourceValues[ref.object.id:lower()] or 0
    local heat = 0
    local distance = mwscript.getDistance({reference = "player", target = ref})

    --remap so heat is max at distance = 0, and 0 at maxDistance
    if distance < maxDistance then
        heat = math.remap(distance, maxDistance, 0, 0, hazardTemp)
    end
    
    return heat
end


function this.calculateHazards()
    local totalHeat = 0
    common.helper.iterateRefType("hazard", function(ref)
        totalHeat = totalHeat + getHeat(ref)
    end)
    --tes3.messageBox("%s", totalHeat)
    totalHeat = math.min( 100, totalHeat)
    common.data.hazardTemp = totalHeat
end

return this