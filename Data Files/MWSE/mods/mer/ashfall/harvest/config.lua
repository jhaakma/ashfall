---@class AshfallHarvestWeaponData
---@field effectiveness number
---@field degradeMulti number

---@class AshfallHarvestConfigHarvestable
---@field id number
---@field count number
---@field chance number

---@class AshfallHarvestConfig
---@field name string Name needed for error message when harvesting is illegal
---@field weaponTypes table<number, AshfallHarvestWeaponData> Key: tes3.weaponType
---@field weaponIds table<number, AshfallHarvestWeaponData> Key: tes3.weaponType
---@field weaponNamePatterns table<string, AshfallHarvestWeaponData> Key: String pattern to search in object name
---@field requirements function (weapon: tes3equipmentStack) -> boolean Returns true if the weapon meets the requirements
---@field items AshfallHarvestConfigHarvestable[] Array of harvestables
---@field sound string
---@field swingsNeeded number

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
    woodSource = {
        attackDirections = {
            [attackDirection.chop] = true
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
        swingsNeeded = 2
    },
    resinSource = {
        attackDirections = {
            [attackDirection.chop] = true
        },
        weaponTypes = {
            [tes3.weaponType.axeOneHand] = {
                effectiveness = 1.0
            },
            [tes3.weaponType.axeTwoHand] = {
                effectiveness = 1.0
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
        swingsNeeded = 2
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
        swingsNeeded = 1
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
        swingsNeeded = 4
    }
}

return config