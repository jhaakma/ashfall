---@class AshfallHarvestWeaponData
---@field effectiveness number
---@field degradeMulti number

---@class AshfallHarvestConfigHarvestable
---@field id number
---@field count number
---@field chance number

---@class AshfallHarvestConfigDestructionLimit
---@field min number
---@field max number

---@class AshfallHarvestConfig
---@field name string Name needed for error message when harvesting is illegal
---@field weaponTypes table<number, AshfallHarvestWeaponData> Key: tes3.weaponType
---@field weaponIds table<number, AshfallHarvestWeaponData> Key: tes3.weaponType
---@field weaponNamePatterns table<string, AshfallHarvestWeaponData> Key: String pattern to search in object name
---@field requirements function (weapon: tes3equipmentStack) -> boolean Returns true if the weapon meets the requirements
---@field items AshfallHarvestConfigHarvestable[] Array of harvestables
---@field sound string
---@field swingsNeeded number
---@field destructionLimit AshfallHarvestConfigDestructionLimit The min/max that can be harvested before being destroyed
---@field fallSound string The sound to play when the harvestable is destroyed
---@field clutter table<string, boolean> A list of clutter items that are destroyed alongside this harvestable.
---@field dropLoot boolean If set, any items sitting on top of the reference will be "dropped" to the ground

local attackDirection = {
    slash = 1,
    chop = 2,
    stab = 3
}
local config = {}



config.woodaxes = {
    ashfall_woodaxe_flint = {
        effectiveness = 1.4,
        degradeMulti = 0.50,
    },
    ashfall_woodaxe = {
        effectiveness = 1.5,
        degradeMulti = 0.50,
    },
    ashfall_woodaxe_steel = {
        effectiveness = 1.8,
        degradeMulti = 0.50,
    }
}
config.attackDirectionMapping = {
    [1] = {
        min = "slashMin",
        max = "slashMax"
    },
    [2] = {
        min = "chopMin",
        max = "chopMax"
    },
    [3] = {
        min = "stabMin",
        max = "stabMax"
    }
}

config.activatorHarvestData = {
    stump = {
        attackDirections = {
            [attackDirection.chop] = true,
            [attackDirection.slash] = true
        },
        weaponTypes = {
            [tes3.weaponType.axeOneHand] = {
                effectiveness = 1.0,
            },
            [tes3.weaponType.axeTwoHand] = {
                effectiveness = 1.0,
            },
        },
        weaponIds = config.woodaxes,
        requirements = function(weapon)
            local isAxe = weapon.object.type == tes3.weaponType.axeOneHand
                or weapon.object.type == tes3.weaponType.axeTwoHand
            local isPick = string.find(weapon.object.id:lower(), "pick")
            return isAxe and not isPick
        end,
        items = {
            { id = "ashfall_firewood", count = 10, chance = 1.0 },
        },
        sound = "ashfall\\chopshort.wav",
        swingsNeeded = 2,
        destructionLimit = {
            min = 8,
            minHeight = 300,
            max = 25,
            maxHeight = 4000,
        },
        clutter = {
            ["flora_bc_shelffungus_01"] = true,
            ["flora_bc_shelffungus_02"] = true,
            ["flora_bc_shelffungus_03"] = true,
            ["flora_bc_shelffungus_04"] = true,
            ["t_mw_floragm_grtkpoly01"] = true,
            ["t_mw_floragm_grtkpoly02"] = true,
            ["t_mw_floragm_grtkpoly03"] = true,
            ["t_mw_floragm_grtkpoly04"] = true,
            ["t_mw_floragm_fungus_01"] = true,
            ["t_mw_floragm_fungus_02"] = true,
            ["t_mw_floragm_fungus_03"] = true,
            ["t_mw_floragm_fungus_04"] = true,
            ["furn_bone_skull_01"] = true
        },
        fallSound = "ashfall_woodfall",
        fallSpeed = 1.5,
        dropLoot = true,
    },
    woodSource = {
        attackDirections = {
            [attackDirection.chop] = true,
            [attackDirection.slash] = true
        },
        weaponTypes = {
            [tes3.weaponType.axeOneHand] = {
                effectiveness = 1.0,
            },
            [tes3.weaponType.axeTwoHand] = {
                effectiveness = 1.0,
            },
        },
        weaponIds = config.woodaxes,
        requirements = function(weapon)
            local isAxe = weapon.object.type == tes3.weaponType.axeOneHand
                or weapon.object.type == tes3.weaponType.axeTwoHand
            local isPick = string.find(weapon.object.id:lower(), "pick")
            return isAxe and not isPick
        end,
        items = {
            { id = "ashfall_firewood", count = 10, chance = 1.0 },
        },
        sound = "ashfall\\chopshort.wav",
        swingsNeeded = 2,
        destructionLimit = {
            min = 8,
            minHeight = 300,
            max = 25,
            maxHeight = 4000,
        },
        clutter = {
            ["flora_bc_shelffungus_01"] = true,
            ["flora_bc_shelffungus_02"] = true,
            ["flora_bc_shelffungus_03"] = true,
            ["flora_bc_shelffungus_04"] = true,
            ["t_mw_floragm_grtkpoly01"] = true,
            ["t_mw_floragm_grtkpoly02"] = true,
            ["t_mw_floragm_grtkpoly03"] = true,
            ["t_mw_floragm_grtkpoly04"] = true,
            ["t_mw_floragm_fungus_01"] = true,
            ["t_mw_floragm_fungus_02"] = true,
            ["t_mw_floragm_fungus_03"] = true,
            ["t_mw_floragm_fungus_04"] = true,
        },
        fallSound = "ashfall_woodfall",
        fallSpeed = 1.5,
    },
    resinSource = {
        attackDirections = {
            [attackDirection.chop] = true,
            [attackDirection.slash] = true
        },
        weaponTypes = {
            [tes3.weaponType.axeOneHand] = {
                effectiveness = 1.0
            },
            [tes3.weaponType.axeTwoHand] = {
                effectiveness = 1.25
            },
        },
        weaponIds = config.woodaxes,
        requirements = function(weapon)
            local isAxe = weapon.object.type == tes3.weaponType.axeOneHand
                or weapon.object.type == tes3.weaponType.axeTwoHand
            local isPick = string.find(weapon.object.id:lower(), "pick")
            return isAxe and not isPick
        end,
        items = {
            { id = "ashfall_firewood", count = 10, chance = 0.7 },
            { id = "ingred_resin_01", count = 3, chance = 0.3 },
        },
        sound = "ashfall\\chopshort.wav",
        swingsNeeded = 2,
        destructionLimit = {
            min = 10,
            minHeight = 500,
            max = 30,
            maxHeight = 4000,
        },
        clutter = {
            ["flora_bc_shelffungus_01"] = true,
            ["flora_bc_shelffungus_02"] = true,
            ["flora_bc_shelffungus_03"] = true,
            ["flora_bc_shelffungus_04"] = true,
            ["t_mw_floragm_grtkpoly01"] = true,
            ["t_mw_floragm_grtkpoly02"] = true,
            ["t_mw_floragm_grtkpoly03"] = true,
            ["t_mw_floragm_grtkpoly04"] = true,
            ["t_mw_floragm_fungus_01"] = true,
            ["t_mw_floragm_fungus_02"] = true,
            ["t_mw_floragm_fungus_03"] = true,
            ["t_mw_floragm_fungus_04"] = true,
            ["flora_root_wg_01"] = true,
            ["flora_root_wg_02"] = true,
            ["flora_root_wg_03"] = true,
            ["flora_root_wg_04"] = true,
            ["flora_root_wg_05"] = true,
            ["flora_root_wg_06"] = true,
            ["flora_root_wg_07"] = true,
            ["flora_root_wg_08"] = true,
            ["flora_bc_vine_01"] = true,
            ["flora_bc_vine_02"] = true,
            ["flora_bc_vine_03"] = true,
            ["flora_bc_vine_04"] = true,
            ["flora_bc_vine_05"] = true,
            ["flora_bc_vine_06"] = true,
            ["flora_bc_vine_07"] = true,
            ["flora_bc_moss_01"] = true,
            ["flora_bc_moss_02"] = true,
            ["flora_bc_moss_03"] = true,
            ["flora_bc_moss_04"] = true,
            ["flora_bc_moss_05"] = true,
            ["flora_bc_moss_06"] = true,
            ["flora_bc_moss_07"] = true,
            ["flora_bc_moss_08"] = true,
            ["flora_bc_moss_09"] = true,
            ["flora_bc_moss_10"] = true,
            ["flora_bc_moss_11"] = true,
            ["flora_bc_moss_12"] = true,
            ["flora_bc_moss_13"] = true,
            ["flora_bc_moss_14"] = true,
            ["flora_bc_moss_15"] = true,
            ["flora_bc_moss_16"] = true,
            ["flora_bc_moss_17"] = true,
            ["flora_bc_moss_18"] = true,
            ["flora_bc_moss_19"] = true,
            ["flora_bc_moss_20"] = true,
            ["flora_bc_moss_21"] = true,
        },
        fallSound = "ashfall_treefall",
        fallSpeed = 2.0,
    },
    vegetation = {
        attackDirections = {
            [attackDirection.chop] = true,
            [attackDirection.slash] = true,
        },
        weaponTypes = {
            [tes3.weaponType.shortBladeOneHand] = {
                effectiveness = 1.0
            },
            [tes3.weaponType.axeOneHand] = {
                effectiveness = 0.7
            },
            [tes3.weaponType.longBladeOneHand] = {
                effectiveness = 0.6
            },
            [tes3.weaponType.longBladeTwoClose] = {
                effectiveness = 0.5
            },
            [tes3.weaponType.axeTwoHand] = {
                effectiveness = 0.4
            },
        },
        items = {
            { id = "ashfall_plant_fibre", count = 15, chance = 1.0 },
        },
        sound ="ashfall\\chopveg.wav",
        swingsNeeded = 1,
        destructionLimit = {
            min = 8,
            minHeight = 50,
            max = 20,
            maxHeight = 500,
        },
        fallSound = "ashfall_vegfall",
        fallSpeed = 1.0,
    },
    stoneSource = {
        attackDirections = {
            [attackDirection.chop] = true
        },
        weaponNamePatterns = {
            ["pick"] = {
                effectiveness = 1.0,
                degradeMulti = 1.0,
            }
        },
        requirements = function(weapon)
            local isPick = string.find(weapon.object.id:lower(), "pick")
            return isPick
        end,
        items = {
            { id = "ashfall_flint", count = 2, chance = 1.0 }
        },
        sound = "Fx\\Heavy Armor Hit.wav",
        swingsNeeded = 4,
    }
}

return config