local this = {}
local tentConfig = require("mer.ashfall.camping.tents.tentConfig")
--Do common ingred ids first so they have priority
this.materials = {
    resin = {
        name = "Resin",
        ids = {"ingred_resin_01", "ingred_shalk_resin_01" }
    },
    wood = {
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
    },
    rope = {
        name = "Rope",
        ids = { "ashfall_rope" }
    },
    sack = {
        name = "Sack",
        ids = { "ashfall_sack_01" }
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
        id  = "ashfall_rope",
        description = "A rope spun from plant fibres that can be used in more advanced crafting recipes.",
        materials = {
            { material = this.materials.fibre, count = 2 }
        }
    },
    {
        id  = "ashfall_torch",
        description = "A rudimentary torch made by applying resin to a piece of wood.",
        materials = {
            { material = this.materials.resin, count = 1 },
            { material = this.materials.wood, count = 1 }
        }
    },
    {
        id = "ashfall_sack_01",
        description = "A sack that can be placed on the ground and used as storage.",
        materials = {
            { material = this.materials.rope, count = 1 },
            { material = this.materials.fibre, count = 10 },
        }
    },
    {
        id = "ashfall_chest_01_m",
        description = "A large wooden chest that can be placed on the ground and used as storage.",
        materials = {
            { material = this.materials.wood, count = 8 },
            { material = this.materials.rope, count = 4 }
        }
    },
    {
        id = "ashfall_strawbed",
        description = "Bedding made of dried plant fibres.",
        materials = {
            { material = this.materials.fibre, count = 5 }
        }
    },
    {
        id = "ashfall_strawhat",
        description = "A straw hat which protects the wearer from the sun.",
        materials = {
            { material = this.materials.fibre, count = 4 }
        }
    },
    {
        id = "ashfall_waterskin",
        description = "A waterskin made of sewn animal hide, made waterproof with a resin coating.",
        materials = {
            { material = this.materials.leather, count = 1 },
            { material = this.materials.resin, count = 1 }
        }
    },
    {
        id = "ashfall_cov_thatch",
        mesh = tentConfig.coverToMeshMap["ashfall_cov_thatch"],
        description = "A tent cover made of leather and thatch that provides added protection from the rain.",
        materials = {
            { material = this.materials.wood, count = 4 },
            { material = this.materials.rope, count = 1 },
            { material = this.materials.fibre, count = 10 },
            { material = this.materials.leather, count = 2 },
        }
    },
    {
        id = "ashfall_cov_ashl",
        mesh = tentConfig.coverToMeshMap["ashfall_cov_ashl"],
        description = "A tent cover made of leather that provides added protection from the rain.",
        materials = {
            { material = this.materials.wood, count = 4 },
            { material = this.materials.rope, count = 1 },
            { material = this.materials.leather, count = 2 },
        }
    },
    {
        id = "ashfall_tent_leather_m",
        description = "A heavy tent stitched together from various animal hides",
        materials = {
            { material = this.materials.leather, count = 4 },
            { material = this.materials.wood, count = 6 },
            { material = this.materials.rope, count = 4 },
        }
    },


    {
        id = "ashfall_supports_01",
        description = "Wooden supports in a tripod shape. Attach to a campfire so you can attach kettles and cooking pots.",
        materials = {
            { material = this.materials.wood, count = 3}
        }
    },

    {
        id = "ashfall_supports_02",
        description = "Wooden supports in a square shape. Attach to a campfire so you can attach kettles and cooking pots.",
        materials = {
            { material = this.materials.wood, count = 3}
        }
    },

    --Small table of wood and rope
    {
        id = "ashfall_table_sml",
        description = "A small, crudely made wooden table",
        materials = {
            { material = this.materials.wood, count = 6 },
            { material = this.materials.rope, count = 2 }
        }
    },
    {
        id = "ashfall_table_sml_2",
        description = "A long, crudely made wooden table",
        materials = {
            { material = this.materials.wood, count = 8 },
            { material = this.materials.rope, count = 2 }
        }
    },

    {
        id = "ashfall_pack_04",
        description = "A heavy wooden backpack.",
        materials = {
            { material = this.materials.wood, count = 8 },
            { material = this.materials.rope, count = 4 },
            { material = this.materials.sack, count = 1 },
            { material = this.materials.leather, count = 2 }
        }
    }
}

return this