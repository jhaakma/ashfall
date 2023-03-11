---@class Ashfall.Skinning.config
local skinningConfig = {
    SWINGS_NEEDED = 2,
    MIN_DESTRUCTION_LIMIT = 2,
    MAX_DESTRUCTION_LIMIT = 5,
    MIN_SURVIVAL_SKILL = 10,
    MAX_SURVIVAL_SKILL = 60,
    HARVEST_VARIANCE = 3,
    MIN_HEIGHT = 60,
    MAX_HEIGHT = 400,
    MIN_HEIGHT_EFFECT = 0.25,
    MAX_HEIGHT_EFFECT = 2,
}

skinningConfig.materials = {
    fur = true,
    hide = true,
}

skinningConfig.foodTypes = {
    meat = true,
}

skinningConfig.actorTypes = {
    [tes3.objectType.creature] = true,
}

skinningConfig.creatureTypes = {
    [tes3.creatureType.normal] = true
}

---@class Ashfall.Skinning.meatConfig
---@field creatures table<string, boolean> A list of creatures who can drop this skinnable type, Key: object id (lowercase)
---@field alternatives table<string, boolean>? A list of ingredients to check for If any exist on the inventory of the creature, don't add this skinnable. Key: object id (lowercase)
---@field foodType string? The food type
---@field materialType string? The material type

---@type table<string, Ashfall.Skinning.meatConfig> Key: skinnable object id
skinningConfig.extraSkinnables = {
    ashfall_meat_alit = {
        foodType = "meat",
        creatures = {
            alit = true,
            alit_diseased = true,
            alit_blighted = true,
        },
        alternatives = {
            t_ingfood_meatalit_01 = true
        }
    },
    ashfall_meat_guar = {
        foodType = "meat",
        creatures = {
            guar = true,
            guar_feral = true,
            guar_llovyn_unique = true,
            guar_pack = true,
            guar_pack_tarvyn_unique = true,
            guar_rollie_unique = true,
            guar_white_unique = true,
        },
        alternatives = {
            t_ingfood_meatguar_01 = true,
            ab_ingcrea_guarmeat_01 = true
        }
    },
    ashfall_meat_kag = {
        foodType = "meat",
        creatures = {
            kagouti = true,
            kagouti_blighted = true,
            kagouti_diseased = true,
            kagouti_hrk = true,
            kagouti_mating= true,
        },
        alternatives = {
            t_ingfood_meatkagouti_01 = true,
        }
    },
    ashfall_meat_racer ={
        foodType = "meat",
        creatures = {
            ["cliff racer"] = true,
            ["cliff racer_blighted"] = true,
            ["cliff racer_diseased"] = true
        },
        alternatives = {
            t_ingfood_meatcliffracer_01 = true,
        }
    },
    ashfall_meat_sfish = {
        foodType = "meat",
        creatures = {
            slaughterfish = true,
            slaughterfish_hr_sfavd = true,
            slaughterfish_small = true,
        },
        alternatives = {
            ab_ingcrea_sfmeat_01 = true,
            mc_fish_bladder = true,
            mc_fish_raw = true,
        }
    },
    ashfall_rat_pelt = {
        materialType = "hide",
        creatures = {
            rat = true,
            rat_blighted = true,
            rat_cave_fgrh = true,
            rat_cave_fgt = true,
            rat_cave_hhte1 = true,
            rat_cave_hhte2 = true,
            rat_diseased = true,
            rat_plague = true,
            rat_plague_hall1 = true,
            rat_plague_hall1a = true,
            rat_plague_hall2 = true,
            rat_rerlas = true,
            rat_telvanni_unique = true,
            rat_telvanni_unique_2 = true,
        }

    }
}



return skinningConfig