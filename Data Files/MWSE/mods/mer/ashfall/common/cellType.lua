local cellTypeConfig = require("mer.ashfall.config.cellTypeConfig")

local maxCount = 5
local function getCellType(cell)
    local count = 0
    local thisCellType
    for stat in cell:iterateReferences(tes3.objectType.static) do
        for _, cellData in ipairs(cellTypeConfig.cellTypes) do
            for _, statName in ipairs(cellData.statics) do
                if string.startswith(stat.object.id:lower(), statName) then
                    count = count + 1
                    thisCellType = cellData
                    if count >= maxCount then
                        return thisCellType
                    end
                end
            end
        end
    end
end