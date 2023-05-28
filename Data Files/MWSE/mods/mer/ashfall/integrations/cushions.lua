local cushions = {
    ashfall_cushion_01 = { height = 20 },
    ashfall_cushion_02 = { height = 20 },
    ashfall_cushion_03 = { height = 20 },
    ashfall_cushion_04 = { height = 20 },
    ashfall_cushion_05 = { height = 20 },
    ashfall_cushion_06 = { height = 20 },
    ashfall_cushion_07 = { height = 20 },
    ashfall_cushion_sq_01 = { height = 10 },
    ashfall_cushion_sq_02 = { height = 10 },
    ashfall_cushion_sq_03 = { height = 10 },
    ashfall_cushion_sq_04 = { height = 10 },
    ashfall_cushion_sq_05 = { height = 10 },
    ashfall_cushion_sq_06 = { height = 10 },
    ashfall_cushion_sq_07 = { height = 10 },
    ashfall_cush_crft_01 = { height = 5 },
}

local Cushion = require("mer.ashfall.items.cushion")
for id, data in pairs(cushions) do
    Cushion.register{
        id = id,
        height = data.height
    }
end

