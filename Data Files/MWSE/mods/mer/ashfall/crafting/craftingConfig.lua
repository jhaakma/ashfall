local this = {}

--Do common ingred ids first so they have priority
this.materials = {
    resin = {
        name = "Resin",
        ids = {"ingred_resin_01", "ingred_shalk_resin_01" } 
    },
    firewood = { 
        name = "Wood",
        ids = {"ashfall_firewood"} 
    },
    leather = {
        name = "Leather",
        ids = { 
            "ingred_alit_hide_01", 
            "ingred_guar_hide_01", 
            "ingred_kagouti_hide_01", 
            "ingred_netch_leather_01",
            "ingred_boar_leather"
        }
    },
    fibre = {
        name = "Fibre",
        ids = { "ashfall_plant_fibre" }
    }
}
this.ingredMaterials = {}
for name, ingredient in pairs(this.materials) do
    for _, id in ipairs(ingredient.ids) do
        this.ingredMaterials[id] = name
    end
end


this.recipes = {
    {
        id  = "ashfall_torch",
        description = "A rudimentary torch made by applying resin to a piece of wood.",
        materials = {
            { material = this.materials.resin, count = 1 },
            { material = this.materials.firewood, count = 1 }
        }
    },
    {
        id = "ashfall_sack_01",
        description = "A sack made of animal hides that can be placed on the ground and used as storage.",
        materials = {
            { material = this.materials.leather, count = 3 }
        }
    },
    {
        id = "ashfall_strawbed",
        description = "Bedding made of dried plant fibres.",
        materials = {
            { material = this.materials.fibre, count = 10 }
        }
    },
    {
        id = "ashfall_strawhat",
        description = "A straw hat the offers mild protection from the rain.",
        materials = {
            { material = this.materials.fibre, count = 5 }
        }
    },
    {
        id = "ashfall_waterskin",
        description = "A waterskin made of sewn animal hide, made waterproof with a resin coating.",
        materials = {
            { material = this.materials.leather, count = 2 },
            { material = this.materials.resin, count = 1 }

        }
    }
}

return this