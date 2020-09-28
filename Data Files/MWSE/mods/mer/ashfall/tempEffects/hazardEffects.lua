local this = {}
local common = require("mer.ashfall.common.common")

--Register heat source
local temperatureController = require("mer.ashfall.temperatureController")
temperatureController.registerExternalHeatSource("hazardTemp")

local hazardTemps = {
    ["in_lava_1"] = 250,
    ["in_lava_2"] = 250,
    ["in_lava_5"] = 250,
    ["in_lava_oval"] = 250,
    ["lava_vent"] = 50,
    ["volcano_steam"] = 80,
}
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



function this.calculateHazards()
    local totalHeat = 0
    for _, cell in pairs( tes3.getActiveCells() ) do
        for ref in cell:iterateReferences(tes3.objectType.activator) do
            for pattern, val in pairs(hazardTemps) do
                if string.find(string.lower(ref.object.id), pattern) then
                    totalHeat = totalHeat + getHeat(ref, val)
                end
            end
        end
    end
    --tes3.messageBox("%s", totalHeat)
    totalHeat = math.min( 100, totalHeat)

    common.data.hazardTemp = totalHeat
end

return this