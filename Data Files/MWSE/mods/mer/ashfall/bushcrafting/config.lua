local this = {}
local tentConfig = require("mer.ashfall.camping.tents.tentConfig")
local itemDescriptions = require("mer.ashfall.config.itemDescriptions")
local BedRoll = require("mer.ashfall.items.bedroll")
local WaterFilter = require("mer.ashfall.items.waterFilter")
local CrabPot = require("mer.ashfall.items.crabpot")
local config = require("mer.ashfall.config").config



local survivalTiers = {
    beginner = { skill = "Bushcrafting", requirement = 10 },
    novice = { skill = "Bushcrafting", requirement = 20 },
    apprentice = { skill = "Bushcrafting", requirement = 30 },
    journeyman = { skill = "Bushcrafting", requirement = 40 },
    expert = { skill = "Bushcrafting", requirement = 60 },
    master = { skill = "Bushcrafting", requirement = 80 },
    grandmaster = { skill = "Bushcrafting", requirement = 100 },
}

local customRequirements = {
    outdoorsOnly = {
        getLabel = function()
            return "Outdoors"
        end,
        check = function()
            local cell = tes3.player.cell
            local isOutdoors = (not cell.isInterior)
                or cell.behavesAsExterior
            local canCampIndoors = config.canCampIndoors
            if isOutdoors or canCampIndoors then
                return true
            else
                return false, "You must be outdoors to craft this"
            end
        end
    },
    wildernessOnly = {
        getLabel = function()
            return "Wilderness"
        end,
        check = function()
            local cell = tes3.player.cell
            local isWilderness = not cell.restingIsIllegal
            local canCampInSettlements = config.canCampInSettlements
            if isWilderness or canCampInSettlements then
                return true
            else
                return false, "You must be outside of towns/settlements to craft this"
            end
        end
    }
}

this.tools = {
    {
        id = "knife",
        name = "Knife",
        ---@param itemStack tes3itemStack
        requirement = function(itemStack)
            return itemStack.object.objectType == tes3.objectType.weapon
            and itemStack.object.type == tes3.weaponType.shortBladeOneHand
        end,
    }
}


this.categories = {
    beds = "Beds",
    containers = "Containers",
    furniture = "Furniture",
    materials = "Materials",
    other = "Other",
    survival = "Survival",
    structures = "Structures",
    equipment = "Equipment",
    cutlery = "Cutlery",
    weapons = "Weapons",
}

--Do common ingred ids first so they have priority
this.menuOptions = {
    restMenu = BedRoll.buttons.sleep,
    layDown = BedRoll.buttons.layDown,
    tanningRackMenu = {
        text = "Craft",
        callback = function()
            event.trigger("Ashfall:ActivateTanningRack")
        end
    },
    rename = {
        text = "Rename",
        callback = function(e)
            local menuID = "RenameMenu"
            local menu = tes3ui.createMenu{ id = menuID, fixedFrame = true }
            menu.minWidth = 400
            menu.alignX = 0.5
            menu.alignY = 0
            menu.autoHeight = true
            local textField = mwse.mcm.createTextField(
                menu,
                {
                    label = string.format("Label %s:", e.reference.object.name),
                    variable = mwse.mcm.createTableVariable{
                        id = 'customName',
                        table = e.reference.data
                    },
                    callback = function()
                        e.reference.modified = true
                        tes3ui.leaveMenuMode(menuID)
                        tes3ui.findMenu(menuID):destroy()
                        tes3.messageBox("Renamed to %s", e.reference.data.customName)
                    end
                }
            )
            tes3ui.acquireTextInput(textField.elements.inputField)
            tes3ui.enterMenuMode(menuID)
        end
    },
    filterWater = WaterFilter.buttons.filterWater,
    collectWater = WaterFilter.buttons.collectWater,
}

this.materials = {
    {
        id = "resin",
        name = "Resin",
        ids = {"ingred_resin_01", "ingred_shalk_resin_01" }
    },
    {
        id = "wood",
        name = "Wood",
        ids = {"ashfall_firewood"}
    },
    {
        id = "hide",
        name = "Animal Hide",
        ids = {
            "ingred_alit_hide_01",
            "ingred_guar_hide_01",
            "ingred_kagouti_hide_01",
            "ingred_netch_leather_01",
            "ingred_boar_leather",
            "ingred_scamp_skin_01",
        }
    },
    {
        id = "leather",
        name = "Leather",
        ids = {
            "ashfall_leather",
        }
    },
    {
        id = "fibre",
        name = "Fibre",
        ids = { "ashfall_plant_fibre" }
    },
    {
        id = "rope",
        name = "Rope",
        ids = { "ashfall_rope" }
    },
    {
        --straw
        id = "straw",
        name = "Straw",
        ids = { "ashfall_straw" }
    },
    {
        id = "fabric",
        name = "Fabric",
        ids = {
            "ashfall_fabric",
            "misc_de_cloth10",
            "misc_de_cloth11",
        }
    },
    {
        id = "flint",
        name = "Flint",
        ids = {
            "ashfall_flint",
        },
    },
    {
        id = "fur",
        name = "Fur",
        ids = {
            "ingred_bear_pelt",
            "ingred_wolf_pelt",
        }
    },
    {
        id = "pillow",
        name = "Pillow",
        ids = {
            "ashfall_cush_crft_01",
            "ab_misc_depillowl_02",
            "misc_uni_pillow_02",
        }
    },
    {
        id = "coal",
        name = "Coal",
        ids = {
            "ashfall_ingred_coal_01"
        }
    },
    {
        id = "netting",
        name = "Netting",
        ids = {
            "ashfall_netting"
        }
    }
}
this.ingredMaterials = {}
for name, ingredient in pairs(this.materials) do
    for _, id in ipairs(ingredient.ids) do
        this.ingredMaterials[id] = name
    end
end

this.bushCraftingRecipes = {
    --Beginner
    {
        id  = "ashfall_rope",
        description = itemDescriptions.ashfall_rope,
        materials = {
            { material = "fibre", count = 2 }
        },
        skillRequirements = {
            survivalTiers.beginner
        },
        category = this.categories.materials,
        soundType = "rope",
    },
    {
        --Straw
        id = "ashfall_straw",
        description = itemDescriptions.ashfall_straw,
        materials = {
            { material = "fibre", count = 1 }
        },
        skillRequirements = {
            survivalTiers.beginner
        },
        category = this.categories.materials,
        soundType = "straw",
    },
    {
        id  = "ashfall_torch",
        description = itemDescriptions.ashfall_torch,
        materials = {
            { material = "resin", count = 1 },
            { material = "wood", count = 1 }
        },
        skillRequirements = {
            survivalTiers.beginner
        },
        category = this.categories.other,
        soundType = "wood",
    },
    {
        id = "ashfall_torch_lrg",
        name = "Torch: Large",
        description = "A large torch for lighting up your campsite.",
        materials = {
            { material = "resin", count = 2 },
            { material = "wood", count = 2 }
        },
        skillRequirements = {
            survivalTiers.beginner
        },
        category = this.categories.other,
        soundType = "wood",
        customRequirements = {
            customRequirements.wildernessOnly
        }
    },
    {
        id = "ashfall_strawbed_s",
        additionalMenuOptions = {
            this.menuOptions.restMenu,
            this.menuOptions.layDown,
        },
        maxSteepness = 0,
        description = "A simple straw bed. Not very comfortable but it beats sleeping on the ground.",
        materials = {
            { material = "straw", count = 10 },
            { material = "wood", count = 4 },
            { material = "rope", count = 1 },

        },
        skillRequirements = {
            survivalTiers.beginner
        },
        category = this.categories.beds,
        soundType = "straw",
        customRequirements = {
            customRequirements.wildernessOnly
        },
    },
    {
        --Lean To
        id = "ashfall_lean_to_01",
        description = "A simple lean-to provides a bit of shelter from the elements.",
        materials = {
            { material = "straw", count = 8 },
            { material = "rope", count = 1 },
            { material = "wood", count = 8 },
        },
        skillRequirements = {
            survivalTiers.beginner
        },
        category = this.categories.structures,
        soundType = "wood",
        customRequirements = {
            customRequirements.wildernessOnly
        }
    },
    {
        id = "ashfall_knife_flint",
        description = "A simple dagger made of flint. Useful for skinning animals and harvesting plant fibres.",
        materials = {
            { material = "flint", count = 1 },
            { material = "wood", count = 1 },
        },
        skillRequirements = {
            survivalTiers.beginner
        },
        category = this.categories.weapons,
        soundType = "wood",
        recoverEquipmentMaterials = true,
    },
    {
        id = "ashfall_woodaxe_flint",
        description = "A woodaxe made with flint. Can be used to harvest firewood.",
        materials = {
            { material = "flint", count = 2 },
            { material = "wood", count = 1 },
            { material = "rope", count = 1 },
        },
        skillRequirements = {
            survivalTiers.beginner
        },
        category = this.categories.weapons,
        soundType = "wood",
        recoverEquipmentMaterials = true,
    },
    {
        id = "ashfall_bowl_01",
        description = "A handcarved wooden bowl. Can be used to store water or stew.",
        materials = {
            { material = "wood", count = 1},
        },
        toolRequirements = {
            {
                tool = "knife",
                equipped = true,
                conditionPerUse = 5
            }
        },
        category = this.categories.cutlery,
        previewScale = 4,
        soundType = "carve",
        skillRequirements = {
            survivalTiers.beginner
        },
    },
    {
        id = "ashfall_cup_01",
        description = "A handcarved wooden cup. Can be used to store water or tea.",
        materials = {
            { material = "wood", count = 1},
        },
        toolRequirements = {
            {
                tool = "knife",
                equipped = true,
                conditionPerUse = 4
            }
        },
        category = this.categories.cutlery,
        previewScale = 4,
        soundType = "carve",
        skillRequirements = {
            survivalTiers.beginner
        },
    },
    {
        id = "ashfall_wood_knife",
        description = "A handcarved wooden knife.",
        materials = {
            { material = "wood", count = 1},
        },
        toolRequirements = {
            {
                tool = "knife",
                equipped = true,
                conditionPerUse = 2
            }
        },
        category = this.categories.cutlery,
        rotationAxis = 'y',
        soundType = "carve",
        skillRequirements = {
            survivalTiers.beginner
        },
    },
    {
        id = "ashfall_wood_fork",
        description = "A handcarved wooden fork.",
        materials = {
            { material = "wood", count = 1},
        },
        toolRequirements = {
            {
                tool = "knife",
                equipped = true,
                conditionPerUse = 2
            }
        },
        category = this.categories.cutlery,
        rotationAxis = 'y',
        soundType = "carve",
        skillRequirements = {
            survivalTiers.beginner
        },
    },
    {
        id = "ashfall_wood_spoon",
        description = "A handcarved wooden spoon.",
        materials = {
            { material = "wood", count = 1},
        },
        toolRequirements = {
            {
                tool = "knife",
                equipped = true,
                conditionPerUse = 2
            }
        },
        category = this.categories.cutlery,
        rotationAxis = 'y',
        soundType = "carve",
        skillRequirements = {
            survivalTiers.beginner
        },
    },
    {
        id = "ashfall_wood_plate",
        description = "A handcarved wooden plate.",
        materials = {
            { material = "wood", count = 1},
        },
        toolRequirements = {
            {
                tool = "knife",
                equipped = true,
                conditionPerUse = 4
            }
        },
        category = this.categories.cutlery,
        soundType = "carve",
        skillRequirements = {
            survivalTiers.beginner
        },
    },
    {
        id = "ashfall_wood_ladle",
        description = "A handcarved wooden ladle. Can be added to cooking pots to make stews.",
        materials = {
            { material = "wood", count = 1},
        },
        toolRequirements = {
            {
                tool = "knife",
                equipped = true,
                conditionPerUse = 4
            }
        },
        category = this.categories.cutlery,
        previewMesh = "ashfall\\craft\\wood_ladle_attach.nif",
        soundType = "carve",
        skillRequirements = {
            survivalTiers.beginner
        },
    },

    --Novice
    {
        id = "ashfall_water_filter",
        description = "A water filter that uses plant fibre and coal to purify dirty water.",
        materials = {
            { material = "fibre", count = 4 },
            { material = "coal", count = 4 },
            { material = "rope", count = 2 },
            { material = "wood", count = 3 },
            { material = "ashfall_bowl_01", count = 1}

        },
        skillRequirements = {
            survivalTiers.novice
        },
        category = this.categories.structures,
        soundType = "wood",
        customRequirements = {
            customRequirements.wildernessOnly
        },
        maxSteepness = 0,
        additionalMenuOptions = {
            this.menuOptions.filterWater,
            this.menuOptions.collectWater,
        }
    },
    {
        id = "ashfall_fab_cloak",
        previewMesh = "ashfall\\craft\\cloak_fab_preview.nif",
        description = itemDescriptions.ashfall_fab_cloak,
        materials = {
            { material = "fabric", count = 6 },
        },
        skillRequirements = {
            survivalTiers.novice
        },
        category = this.categories.equipment,
        soundType = "fabric",
        recoverEquipmentMaterials = true,
    },
    {
        id = "ashfall_strawhat",
        description = itemDescriptions.ashfall_strawhat,
        materials = {
            { material = "straw", count = 4 }
        },
        skillRequirements = {
            survivalTiers.novice
        },
        category = this.categories.equipment,
        soundType = "straw",
        recoverEquipmentMaterials = true,
        previewMesh = "ashfall\\craft\\strawhat.nif",
    },
    {
        id = "ashfall_fabric",
        description = itemDescriptions.ashfall_fabric,
        materials = {
            { material = "fibre", count = 4 },
        },
        skillRequirements = {
            survivalTiers.novice
        },
        category = this.categories.materials,
        soundType = "fabric",
        rotationAxis = 'y',
    },
    {
        --ashfall_cush_crft_01 cushion
        id = "ashfall_cush_crft_01",
        description = itemDescriptions.ashfall_cush_crft_01,
        materials = {
            { material = "fabric", count = 2 },
            { material = "straw", count = 4 }
        },
        skillRequirements = {
            survivalTiers.novice
        },
        category = this.categories.other,
        soundType = "fabric",
    },
    {
        id = "ashfall_sack_01",
        placedObject = "ashfall_sack_c",
        description = itemDescriptions.ashfall_sack_01,
        materials = {
            { material = "rope", count = 1 },
            { material = "fabric", count = 2 },
        },
        skillRequirements = {
            survivalTiers.novice
        },
        category = this.categories.containers,
        soundType = "fabric",
        additionalMenuOptions = {
            this.menuOptions.rename
        },
    },
    {
        id = "ashfall_rug_crft_01",
        description = itemDescriptions.ashfall_rug_crft_01,
        materials = {
            { material = "fabric", count = 2 },
        },
        skillRequirements = {
            survivalTiers.novice
        },
        category = this.categories.other,
        soundType = "fabric",
        rotationAxis = 'y',
    },
    {
        id = "ashfall_spear_flint",
        description = "A wooden spear with a flint tip. Useful for hunting game.",
        materials = {
            { material = "flint", count = 1 },
            { material = "wood", count = 2 },
            { material = "rope", count = 1 },
        },
        skillRequirements = {
            survivalTiers.novice
        },
        category = this.categories.weapons,
        soundType = "wood",
        recoverEquipmentMaterials = true,
    },
    {
        id = "ashfall_bow_wood",
        description = "A simple bow and quiver made of wood.",
        materials = {
            { material = "wood", count = 3 },
            { material = "rope", count = 3 },
        },
        skillRequirements = {
            survivalTiers.novice
        },
        category = this.categories.weapons,
        soundType = "wood",
        recoverEquipmentMaterials = true,
        previewScale = 1.2,
    },
    {
        id = "ashfall_arrow_flint",
        description = "A simple arrow with a flint head.",
        materials = {
            { material = "flint", count = 1 },
            { material = "wood", count = 1 },
        },
        skillRequirements = {
            survivalTiers.novice
        },
        category = this.categories.weapons,
        soundType = "wood",
        resultAmount = 10,
    },

    --Apprentice
    {
      --tanning rack
        id = "ashfall_tan_rack",
        additionalMenuOptions = {
            this.menuOptions.tanningRackMenu
        },
        description = "A rack for tanning hides to create leather.",
        materials = {
            { material = "wood", count = 4 },
            { material = "rope", count = 2 },
        },
        skillRequirements = {
            survivalTiers.apprentice
        },
        category = this.categories.structures,
        soundType = "wood",
        customRequirements = {
            customRequirements.wildernessOnly
        }
    },
    {
        id = "ashfall_waterskin",
        description = itemDescriptions.ashfall_waterskin,
        materials = {
            { material = "leather", count = 1 },
            { material = "resin", count = 1 }
        },
        skillRequirements = {
            survivalTiers.apprentice
        },
        category = this.categories.other,
        soundType = "leather",
        rotationAxis = 'y',
    },
    {
        id = "ashfall_tent_leather_m",
        description = itemDescriptions.ashfall_tent_leather_m,
        materials = {
            { material = "leather", count = 4 },
            { material = "wood", count = 6 },
            { material = "rope", count = 2 },
        },
        skillRequirements = {
            survivalTiers.apprentice
        },
        category = this.categories.survival,
        soundType = "leather",
        previewMesh = "ashfall\\tent\\tent_leather.nif"
    },
    {
        id = "ashfall_table_sml_s",
        description = "A tall, crudely made wooden table",
        materials = {
            { material = "wood", count = 6 },
            { material = "rope", count = 2 }
        },
        skillRequirements = {
            survivalTiers.apprentice
        },
        category = this.categories.structures,
        soundType = "wood",
        customRequirements = {
            customRequirements.wildernessOnly
        }
    },
    {
        id = "ashfall_table_sml_2_s",
        description = "A long, crudely made wooden table",
        materials = {
            { material = "wood", count = 8 },
            { material = "rope", count = 2 }
        },
        skillRequirements = {
            survivalTiers.apprentice
        },
        category = this.categories.structures,
        soundType = "wood",
        customRequirements = {
            customRequirements.wildernessOnly
        }
    },
    {
        id = "ashfall_pickaxe_flint",
        description = "A pickaxe made with flint. Can be used to harvest stone.",
        materials = {
            { material = "flint", count = 1 },
            { material = "wood", count = 1 },
            { material = "rope", count = 2 },
        },
        skillRequirements = {
            survivalTiers.apprentice
        },
        category = this.categories.weapons,
        soundType = "wood",
        recoverEquipmentMaterials = true,
    },

    --Journeyman
    {
        id = "ashfall_netting",
        description = "a web of netting crafted from rope.",
        materials = {
            { material = "rope", count = 2 },
        },
        skillRequirements = {
            survivalTiers.journeyman
        },
        rotationAxis = 'y',
        category = this.categories.materials,
        soundType = "rope",
    },
    {
        id = "ashfall_chest_01_c",
        description = "A large wooden chest that can be placed on the ground and used as storage.",
        materials = {
            { material = "wood", count = 8 },
            { material = "rope", count = 2 }
        },
        skillRequirements = {
            survivalTiers.journeyman
        },
        category = this.categories.containers,
        soundType = "wood",
        customRequirements = {
            customRequirements.wildernessOnly
        },
        additionalMenuOptions = {
            this.menuOptions.rename
        },
    },
    {
        id = "ashfall_cov_thatch",
        mesh = tentConfig.coverToMeshMap["ashfall_cov_thatch"],
        description = itemDescriptions.ashfall_cov_thatch,
        materials = {
            { material = "wood", count = 4 },
            { material = "rope", count = 1 },
            { material = "straw", count = 10 },
            { material = "leather", count = 2 },
        },
        skillRequirements = {
            survivalTiers.journeyman
        },
        category = this.categories.survival,
        soundType = "straw",
    },
    {
        id = "ashfall_hammock",
        maxSteepness = 0,
        additionalMenuOptions = {
            this.menuOptions.restMenu,
            this.menuOptions.layDown,
        },
        description = "A hammock for sleeping out in the rough.",
        materials = {
            { material = "wood", count = 4 },
            { material = "rope", count = 1 },
            { material = "fabric", count = 4 },
            { material = "straw", count = 4 },
            { material = "pillow", count = 1 },
        },
        skillRequirements = {
            survivalTiers.journeyman
        },
        category = this.categories.beds,
        soundType = "wood",
        customRequirements = {
            customRequirements.wildernessOnly
        }
    },
    {
        id = "ashfall_pack_04",
        description = itemDescriptions.ashfall_pack_04,
        materials = {
            { material = "wood", count = 2 },
            { material = "rope", count = 1 },
            { material = "ashfall_sack_01", count = 1 },
            { material = "leather", count = 1 },
            { material = "netting", count = 1 },
        },
        skillRequirements = {
            survivalTiers.journeyman
        },
        category = this.categories.equipment,
        soundType = "wood",
    },
    {
        id = "ashfall_crabpot_02_a",
        description = itemDescriptions.ashfall_crabpot_01_m,
        materials = {
            { material = "wood", count = 4 },
            { material = "rope", count = 1 },
            { material = "netting", count = 2 },
        },
        skillRequirements = {
            survivalTiers.journeyman
        },
        category = this.categories.structures,
        soundType = "wood",
        additionalMenuOptions = {
            CrabPot.buttons.collect,
        },
        previewScale = 4,
        previewHeight = -80
    },

    --Expert
    {
        id = "ashfall_cov_ashl",
        mesh = tentConfig.coverToMeshMap["ashfall_cov_ashl"],
        description = itemDescriptions.ashfall_cov_ashl,
        materials = {
            { material = "wood", count = 4 },
            { material = "rope", count = 1 },
            { material = "leather", count = 4 },
        },
        skillRequirements = {
            survivalTiers.expert
        },
        category = this.categories.survival,
        soundType = "leather",
    },
    {
        --Travellers pack
        id = "ashfall_pack_05",
        description = itemDescriptions.ashfall_pack_05,
        materials = {
            { material = "wood", count = 2 },
            { material = "rope", count = 1 },
            { material = "fabric", count = 4 },
            { material = "leather", count = 1 }
        },
        skillRequirements = {
            survivalTiers.expert
        },
        category = this.categories.equipment,
        soundType = "wood",
    },
    {
        id = "ashfall_dummy_01",
        description = "A practice dummy for training your melee skills.",
        materials = {
            { material = "wood", count = 2 },
            { material = "rope", count = 1 },
            { material = "fabric", count = 4 },
            { material = "straw", count = 6 }
        },
        skillRequirements = {
            survivalTiers.expert
        },
        category = this.categories.structures,
        maxSteepness = 0,
        soundType = "fabric",
        customRequirements = {
            customRequirements.wildernessOnly
        }
    },
    {
        id = "ashfall_target_01",
        description = "A target for practicing your marksman skills.",
        materials = {
            { material = "wood", count = 3 },
            { material = "rope", count = 2 },
            { material = "straw", count = 10 },
        },
        skillRequirements = {
            survivalTiers.expert
        },
        category = this.categories.structures,
        maxSteepness = 0,
        soundType = "straw",
        customRequirements = {
            customRequirements.wildernessOnly
        }
    },
    {
        id = "ashfall_bed_fur",
        maxSteepness = 0,
        additionalMenuOptions = {
            this.menuOptions.restMenu,
            this.menuOptions.layDown,
        },
        description = "A sturdy bed covered in warm furs.",
        materials = {
            { material = "wood", count = 6 },
            { material = "rope", count = 1 },
            { material = "fabric", count = 2 },
            { material = "fur", count = 2 },
            { material = "pillow", count = 1 },
        },
        skillRequirements = {
            survivalTiers.expert
        },
        category = this.categories.beds,
        soundType = "wood",
        customRequirements = {
            customRequirements.wildernessOnly
        }
    },

    --Master
    {
        id =  "ashfall_cbroll_active",
        description = "A covered bedroll which provides protection from the elements while sleeping.",
        additionalMenuOptions = {
            this.menuOptions.restMenu,
            this.menuOptions.layDown,
        },
        maxSteepness = 0,
        materials = {
            { material = "straw", count = 4 },
            { material = "wood", count = 3 },
            { material = "rope", count = 2 },
            { material = "fabric", count = 4},
            { material = "leather", count = 2 },
        },
        skillRequirements = {
            survivalTiers.master
        },
        category = this.categories.beds,
        soundType = "leather",
        previewScale = 1.25,
        customRequirements = {
            customRequirements.wildernessOnly
        }
    },
    {
        --Nordic backpack
        id = "ashfall_pack_06",
        description = itemDescriptions.ashfall_pack_06,
        materials = {
            { material = "wood", count = 2 },
            { material = "rope", count = 1 },
            { material = "fabric", count = 2 },
            { material = "leather", count = 1 },
            { material = "fur", count = 2 }
        },
        skillRequirements = {
            survivalTiers.master
        },
        category = this.categories.equipment,
        soundType = "wood",
    },
    {
        id = "ashfall_fur_cloak",
        previewMesh = "ashfall\\craft\\cloak_fur_preview.nif",
        description = itemDescriptions.ashfall_fur_cloak,
        materials = {
            { material = "fur", count = 4 },
        },
        skillRequirements = {
            survivalTiers.master
        },
        category = this.categories.equipment,
        soundType = "fabric",
    },
}
this.tanningRackRecipes = {
    {
        id = "ashfall_leather",
        name = "Leather",
        description = itemDescriptions.ashfall_leather,
        materials = {
            { material = "hide", count = 1 }
        },
        soundType = "leather",
    }
}

this.menuEvent = "Ashfall:ActivateBushcrafting"
this.menuActivators = {
    {
        name = "Bushcrafting",
        type = "event",
        id = this.menuEvent,
        recipes = this.bushCraftingRecipes,
        defaultFilter = "skill"
    },
    {
        name = "Tanning Rack",
        type = "event",
        id = "Ashfall:ActivateTanningRack",
        recipes = this.tanningRackRecipes,
    }
}


return this