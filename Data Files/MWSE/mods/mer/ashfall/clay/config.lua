---@class Ashfall.Clay.Config
local clayConfig = {}

local common = require("mer.ashfall.common.common")
local logger = common.createLogger("clayConfig")
local Kiln = require("mer.ashfall.clay.Kiln")
local bushcraftingConfig = require("mer.ashfall.bushcrafting.config")


---@type CraftingFramework.Recipe.data[]
clayConfig.firedBrickRecipes = {
    {
        name = "Brick Kiln",
        id = "brick:ashfall_kiln_01",
        craftableId = "ashfall_kiln_01",
        description = "A simple kiln for firing pottery. Unlike a campfire, it can maintain high temperatures for longer, and pottery is less likely to crack or shatter while being fired.",
        materials = {
            { material = "ashfall_brick_fired_01", count = 40 }
        },
        category = "Structures",
        soundPath = "ashfall/brick_lo.wav",
        deconstructionSoundPath = "ashfall/brick_lo.wav",
        timeTaken = 1,
        craftCallback = function(_, e)
            e.reference.data.fuelLevel = 0
            event.trigger("Ashfall:registerReference", { reference = e.reference})
            logger:info("Crafted Brick Kiln: %s", e.reference.id)
        end,
        noMenu = true,
        skillRequirements = {
            {
                skill = "Bushcrafting",
                requirement = 20
            }
        },
        placeCallback = function(_, e)
            local kiln = Kiln:new(e.reference)
            kiln:updateVisuals()
        end
    },
    {
        name = "Brick Wall",
        id = "brick:ashfall_wall_01",
        craftableId = "ashfall_wall_01",
        description = "A section of wall made from fired bricks",
        materials = {
            { material = "ashfall_brick_fired_01", count = 16 }
        },
        deconstructionSoundPath = "ashfall/brick_lo.wav",
        category = "Structures",
        timeTaken = 0.5,
        skillRequirements = {
            {
                skill = "Bushcrafting",
                requirement = 10
            }
        },
        customRequirements = {
            bushcraftingConfig.customRequirements.experimentalBrickWall,
        }
    }
}

---@type CraftingFramework.Recipe.data[]
clayConfig.rawBrickRecipes = {
    {
        name = "Brick Kiln",
        id = "brick:ashfall_kiln_01",
        craftableId = "ashfall_kiln_01",
        description = "A simple kiln for firing pottery. Unlike a campfire, it can maintain high temperatures for longer, and pottery is less likely to crack or shatter while being fired. Raw bricks will convert to fired bricks after first use.",
        materials = {
            { material = "ashfall_brick_raw_01", count = 40 }
        },
        category = "Structures",
        soundPath = "ashfall/brick_lo.wav",
        deconstructionSoundPath = "ashfall/brick_lo.wav",
        timeTaken = 1,
        craftCallback = function(_, e)
            e.reference.data.fuelLevel = 0
            event.trigger("Ashfall:registerReference", { reference = e.reference})
            logger:info("Crafted Brick Kiln: %s", e.reference.id)
        end,
        noMenu = true,
        skillRequirements = {
            {
                skill = "Bushcrafting",
                requirement = 20
            }
        },
    },
}

---@type Ashfall.PotteryRecipe.data[]
clayConfig.potteryRecipes = {
    --cup
    {
        name = "Cup",
        id = "ashfall_raw_cup_01",
        brokenId = "ashfall_cup_break_01",
        firedItemId = "ashfall_clay_cup_01",
        clayAmount = 1,
        animationMesh = "Ashfall\\pot\\cup1_anim.nif",
        craftingMethod = "wheel",
        difficulty = 10,
        canDecorate = true
    },
    --goblet
    {
        name = "Goblet",
        id = "ashfall_raw_gob_01",
        brokenId = "ashfall_gob_break_01",
        firedItemId = "ashfall_clay_gob_01",
        clayAmount = 1,
        animationMesh = "Ashfall\\pot\\gob_anim.nif",
        craftingMethod = "wheel",
        difficulty = 15,
        canDecorate = true
    },


    -- --plate
    -- {
    --     name = "Plate",
    --     id = "ashfall_rawclay_plate_01",
    --     firedItemId = "ashfall_clay_plate_01",
    --     clayAmount = 1,
    --     animationMesh = "Ashfall\\clay\\plate_anim_01.nif",
    --     craftingMethod = "wheel",
    -- },
    -- --flask
    -- {
    --     name = "Flask",
    --     id = "ashfall_rawclay_flask_01",
    --     firedItemId = "ashfall_clay_flask_01",
    --     clayAmount = 1,
    --     animationMesh = "Ashfall\\clay\\flask_anim_01.nif",
    --     craftingMethod = "wheel",
    -- },

    --Large
    {
        name = "Cooking Pot",
        id = "ashfall_pot1_raw",
        firedItemId = "ashfall_pot1",
        brokenId = "ashfall_pot1_break",
        clayAmount = 2,
        animationMesh = "Ashfall\\pot\\pot1_anim.nif",
        craftingMethod = "wheel",
        difficulty = 20,
        canDecorate = true,
        featureFlag = "cookingPot",
    },


    --Hand shaped

    {
        name = "Brick Mould",
        id = "ashfall_brick_mold_raw",
        firedItemId = "ashfall_brick_mold_fired",
        brokenId = "ashfall_brmold_break",
        clayAmount = 1,
        craftingMethod = "hand",
        breakResistance = 0.50,
        canDecorate = false,
        description = "Making bricks using a brick mould takes less time than shaping it by hand.",
    },

    --Firing only, no recipe

    {
        name = "Brick",
        id = "ashfall_brick_raw_01",
        firedItemId = "ashfall_brick_fired_01",
        clayAmount = 1,
        craftingMethod = "none",
        breakResistance = 1.0,
        isBasic = true,
        canDecorate = false,
        description = "A simple brick made from clay. Can be fired in a kiln to create a sturdy building material."
    }
}

---@type Ashfall.Campfire.CampfireData[]
clayConfig.kilnDatas = {
    {
        id = "ashfall_kiln_01",
        heatMultiplier = 1.75,
        damageChanceMultiplier = 0.75,
        fuelBurnMultiplier = 0.75,
        maxFuel = 16,
    }
}



clayConfig.spinningWheels = {
    "ashfall_spin_wheel_01"
}

clayConfig.clayWorkingActivatorIds = {
    "ashfall_raw_clay_01",
    "ashfall_clay_tempered",
    "ashfall_clay_broken_01",
    "ashfall_brick_raw_01",
}

---@type Ashfall.Clay.PotteryDecals.data[]
clayConfig.potteryDecals = {
    {
        id = "temper",
        texturePath = "textures\\Ashfall\\clay\\temper.dds",
        uvIndex = 0,
        priority = 3,
    },
    {
        id = "cracks",
        texturePath = "textures\\Ashfall\\clay\\cracks.dds",
        uvIndex = 1,
        priority = 1
    },
}

---@type Ashfall.Clay.DecorationData[]
clayConfig.decorations = {

    {
        id = "slip_1",
        name = "Charcoal Slip 1",
        description = "A clay slip made from charcoal with a primitive pattern.",
        textures = {
            raw = "textures\\Ashfall\\clay\\chaslip_r.dds",
            fired = "textures\\Ashfall\\clay\\chaslip_f.dds",
        },
        skillRequirement = 10,
        firingStage = "firing",
        ingredients = {
            ashfall_ingred_coal_01 = 1,
        }
    },
    {
        id = "slip_2",
        name = "Clay Slip 1",
        description = "A white clay slip with black painted geometric pattern.",
        textures = {
            raw = "textures\\Ashfall\\clay\\pttn_1_r.dds",
            fired = "textures\\Ashfall\\clay\\pttn_1_f.dds",
        },
        skillRequirement = 15,
        firingStage = "firing",
        ingredients = {
            ashfall_ingred_coal_01 = 1,
            ashfall_raw_clay_01 = 1,
        }
    },
    {
        id = "slip_3",
        name = "Clay Slip 2",
        description = "A white clay slip with black painted geometric pattern.",
        textures = {
            raw = "textures\\Ashfall\\clay\\pttn_2_r.dds",
            fired = "textures\\Ashfall\\clay\\pttn_2_f.dds",
        },
        skillRequirement = 15,
        firingStage = "firing",
        ingredients = {
            ashfall_ingred_coal_01 = 1,
            ashfall_raw_clay_01 = 1,
        }
    },

    {
        id = "ashwash",
        name = "Ash Wash",
        description = "A wash of wood ash, giving a subtle green tint to the clay.",
        textures = {
            raw = "textures\\Ashfall\\clay\\ashwash_r.dds",
            fired = "textures\\Ashfall\\clay\\ashwash_f.dds",
        },
        skillRequirement = 15,
        firingStage = "firing",
        ingredients = {
            ashfall_ingred_woodash_01 = 1,
        }
    },
    {
        id = "firesaltglaze",
        name = "Fire Glaze",
        description = "A glaze made from fire salts, creating a deep red finish with a firey red drip pattern.",
        textures = {
            raw = "textures\\Ashfall\\clay\\glazefire_r.dds",
            fired = "textures\\Ashfall\\clay\\glazefire_f.dds",
        },
        skillRequirement = 25,
        firingStage = "glazing",
        ingredients = {
            ingred_fire_salts_01 = 1,
        }
    }
}

return clayConfig