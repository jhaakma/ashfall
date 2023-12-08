local drip = include("mer.drip")
if not drip then return end

local patterns = {
    ": Traveller",
    ": Brown Fur",
    ": White Fur",
    ": Netch Leather",
    ": Survivalist",
    ": Nordic",
    ": Wicker",
}

for _, pattern in ipairs(patterns) do
    drip.registerMaterialPattern(pattern, true)
end

local clothing = {
    "ashfall_pack_01",
    "ashfall_pack_02",
    "ashfall_pack_03",
    "ashfall_pack_04",
    "ashfall_pack_05",
    "ashfall_pack_06",
    "ashfall_pack_07",
}

for _, id in ipairs(clothing) do
    drip.registerClothing(id)
end

local weapons = {
    "ashfall_woodaxe",
    "ashfall_woodaxe_steel",
    "ashfall_woodaxe_flint",
    "ashfall_woodaxe_glass",
    "ashfall_spear_flint",
    "ashfall_spear_glass",
    "ashfall_bow_wood",
}

for _, id in ipairs(weapons) do
    drip.registerWeapon(id)
end