local this = {}
local common = require("mer.ashfall.common.common")
local staticConfigs = common.staticConfigs
--Register heat source
local temperatureController = require("mer.ashfall.temperatureController")
temperatureController.registerExternalHeatSource("hazardTemp")

local maxDistance = 1000
local function getHeat(ref, hazardTemp)
    local heat = 0
    local distance = mwscript.getDistance({reference = "player", target = ref})

    --remap so heat is max at distance = 0, and 0 at maxDistance
    if distance < maxDistance then
        heat = math.remap(distance, maxDistance, 0, 0, hazardTemp)
    end
    
    return heat
end


local function doCalculateHazard(ref)
    local maxHeat = staticConfigs.heatSourceValues[ref.object.id:lower()]
    if maxHeat then
        return getHeat(ref, maxHeat)
    else
        return 0
    end
end

function this.calculateHazards()
    local totalHeat = 0
    for _, cell in pairs( tes3.getActiveCells() ) do
        for ref in cell:iterateReferences() do
            totalHeat = totalHeat + doCalculateHazard(ref)
        end
    end
    --tes3.messageBox("%s", totalHeat)
    totalHeat = math.min( 100, totalHeat)
    common.data.hazardTemp = totalHeat
end

return this