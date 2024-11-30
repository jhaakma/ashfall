local ChargenScenarios = include("mer.chargenScenarios")

---@type ChargenScenarios.ItemListInput[]
local loadouts = {
    {
        name = "Survival Gear",
        description = "A basic set of equipment for surviving in the wilderness.",
        items = {
            { id = "ashfall_woodaxe" },
            { id = "ashfall_flintsteel" },
            {
                description = "Cooking Pot",
                ids = {
                    "ashfall_cooking_pot",
                    "ashfall_cooking_pot_iron",
                    "ashfall_cooking_pot_steel",
                },
            },
            {
                id = "ashfall_waterskin",
                data = { waterAmount = 50 },
            },
            {
                description = "Tent",
                ids = {
                    "ashfall_tent_base_m",
                    "ashfall_tent_ashl_m",
                    "ashfall_tent_leather_m"
                }
            },
        }
    },
    {
        name = "Tea Set",
        description = "A tea set, for the calmer moments between adventuring.",
        items = {
            { id = "ashfall_stand_01" },
            {
                description = "Teapot",
                id = "ashfall_kettle_08",
                data = {
                    waterAmount = 100,
                    teaProgress = 100,
                    waterType = "ingred_hackle-lo_leaf_01"
                }
            },
            {
                description = "Teacup",
                id = "ashfall_teacup_01",
                count = 2
            },
        }
    }
}

for _, loadout in ipairs(loadouts) do
    ChargenScenarios.registerLoadout{
        id = "ashfall:" .. loadout.name,
        itemList = loadout
    }
end