---@class Ashfall.Clay.Config
local clayConfig = {}

local common = require("mer.ashfall.common.common")
local logger = common.createLogger("clayConfig")

---@return craftingFrameworkMenuButtonData
local function convertAshfallMenuOption(ashfallMenuOption)
    ---@type craftingFrameworkMenuButtonData
    local cfMenuOption =  {
        text = ashfallMenuOption.text,
        showRequirements = function(e)
            return ashfallMenuOption.showRequirements(e.reference)
        end,
        enableRequirements = function(e)
            return ashfallMenuOption.enableRequirements(e.reference)
        end,
        tooltip = function(e)
            return ashfallMenuOption.tooltip()
        end,
        tooltipDisabled = function(e)
            return ashfallMenuOption.tooltipDisabled(e.reference)
        end,
        callback = function(e)
            ashfallMenuOption.callback(e.reference)
        end
    }

    return cfMenuOption
end

---@type Ashfall.PotteryRecipe.data[]
clayConfig.potteryRecipes = {
    --cup
    {
        name = "Cup",
        id = "ashfall_rawclay_cup_01",
        brokenId = "ashfall_cup_break_01",
        firedItemId = "ashfall_clay_cup_01",
        clayAmount = 1,
        animationMesh = "Ashfall\\clay\\cup_anim_01.nif",
        craftingMethod = "wheel",
        difficulty = 10,
    },
    -- --goblet
    -- {
    --     name = "Goblet",
    --     id = "ashfall_rawclay_gob_01",
    --     firedItemId = "ashfall_clay_gob_01",
    --     clayAmount = 1,
    --     animationMesh = "Ashfall\\clay\\gob_anim_01.nif",
    --     craftingMethod = "wheel",
    -- },
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


    --Hand molded
    {
        name = "Brick",
        id = "ashfall_brick_raw_01",
        brokenId = "ashfall_brick_break_01",
        firedItemId = "ashfall_brick_fired_01",
        clayAmount = 1,
        craftingMethod = "hand",
        breakResistance = 0.5,
    }
}

---@type Ashfall.Campfire.CampfireData[]
clayConfig.kilnDatas = {
    {
        id = "ashfall_kiln_01",
        heatMultiplier = 1.8,
        damageChanceMultiplier = 0.75,
        fuelBurnMultiplier = 0.75,
        maxFuel = 16,
    }
}


---@type CraftingFramework.Recipe.data[]
clayConfig.otherClayWorkingRecipes = {
    {
        name = "Brick Kiln",
        id = "bushcraft:ashfall_kiln_01",
        craftableId = "ashfall_kiln_01",
        description = "A simple kiln for firing pottery. Unlike a campfire, it can maintain high temperatures for longer, and pottery is less likely to crack or shatter while being fired.",
        materials = {
            { material = "ashfall_brick_raw_01", count = 40 }
        },
        category = "Kilns",
        soundId = "corpDRAG",
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
                requirement = 30
            }
        }
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
    },
    {
        id = "cracks",
        texturePath = "textures\\Ashfall\\clay\\cracks.dds",
        uvIndex = 1,
    },
}

---@type Ashfall.Clay.TemperData[]
clayConfig.tempers = {
    {
        id = "ashfall_clay_broken_01",
        name = "Crushed Grog",
        description = "Crushed bits of fired clay used as a temper to improve the quality of raw clay when making pottery.",
    },
    {
        id = "ashfall_ingred_coal_01",
        name = "Crushed Charcoal",
        description = "Crushed charcoal used as a temper to improve the quality of raw clay when making pottery.",
    },
}

return clayConfig