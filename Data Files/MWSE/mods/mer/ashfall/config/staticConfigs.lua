local this = {}

this.activatorConfig = require("mer.Ashfall.config.activatorConfig")
this.conditionConfig = require("mer.Ashfall.config.conditionConfig")
this.foodConfig = require("mer.Ashfall.config.foodConfig")
this.teaConfig = require("mer.Ashfall.config.teaConfig")
this.ratingsConfig = require("mer.Ashfall.config.ratingsConfig")
this.campfireConfig = require("mer.Ashfall.config.campfireConfig")

this.objectIds = {
    firewood = "ashfall_firewood",
    campfire = "ashfall_campfire",
    cookingPot = "ashfall_cooking_pot",
    grill = "ashfall_grill",
    kettle = "ashfall_kettle",
    bedroll = "ashfall_bedroll",
    bedroll_ashl = "ashfall_bedroll_ashl",
    coveredBedroll = "ashfall_cbroll_misc",
    canvasTent = "ashfall_tent_misc",
    ashlanderTent = "ashfall_tent_ashl_misc",
    woodaxe = "ashfall_woodaxe",
    pack_b = "ashfall_backpack_b",
    pack_w = "ashfall_backpack_w",
    pack_n = "ashfall_backpack_n",
}
this.crateIds = {
    camping = "ashfall_crate_camping",
    food = "ashfall_crate_food",
}


--Campfire values
this.hotWaterHeatValue = 80
this.stewWaterCooldownAmount = 50
this.stewIngredientCooldownAmount = 20
this.stewMealCapacity = 4
this.firewoodFuelMulti = 2
this.maxWoodInFire = 15

--Tent mappings for activating a misc item into activator
this.tentMiscToActiveMap = {
    ashfall_tent_test_misc = "ashfall_tent_test_active",
    ashfall_tent_misc = "ashfall_tent_active",
    ashfall_tent_ashl_misc = "ashfall_tent_ashl_active",
    ashfall_tent_canv_b_misc = "ashfall_tent_canv_b_active",
    
}
this.tentActiveToMiscMap = {}
for miscId, activeId in pairs(this.tentMiscToActiveMap) do
    this.tentActiveToMiscMap[activeId] = miscId
end


--Ids for various fallen branches
this.branchIds = {
    ashfall_branch_ac_01 = "ashfall_branch_ac_01",
    ashfall_branch_ac_02 = "ashfall_branch_ac_02",
    ashfall_branch_ac_03 = "ashfall_branch_ac_03",


    ashfall_branch_ai_01 = "ashfall_branch_ai_01",
    ashfall_branch_ai_02 = "ashfall_branch_ai_02",
    ashfall_branch_ai_03 = "ashfall_branch_ai_03",

    ashfall_branch_ash_01 = "ashfall_branch_ash_01",
    ashfall_branch_ash_02 = "ashfall_branch_ash_02",
    ashfall_branch_ash_03 = "ashfall_branch_ash_03",

    ashfall_branch_bc_01 = "ashfall_branch_bc_01",
    ashfall_branch_bc_02 = "ashfall_branch_bc_02",
    ashfall_branch_bc_03 = "ashfall_branch_bc_03",

    ashfall_branch_gl_01 = "ashfall_branch_gl_01",
    ashfall_branch_gl_02 = "ashfall_branch_gl_02",
    ashfall_branch_gl_03 = "ashfall_branch_gl_03",

    ashfall_branch_wg_01 = "ashfall_branch_wg_01",
    ashfall_branch_wg_02 = "ashfall_branch_wg_02",
    ashfall_branch_wg_03 = "ashfall_branch_wg_03",
}

--sort branches into general groups
local branchGroups = {
    azurasCoast = {
        this.branchIds.ashfall_branch_ac_01,
        this.branchIds.ashfall_branch_ac_02,
        this.branchIds.ashfall_branch_ac_03,
    },
    ascadianIsles = {
        this.branchIds.ashfall_branch_ai_01,
        this.branchIds.ashfall_branch_ai_02,
        this.branchIds.ashfall_branch_ai_03,
    },
    ashlands = {
        this.branchIds.ashfall_branch_ash_01,
        this.branchIds.ashfall_branch_ash_02,
        this.branchIds.ashfall_branch_ash_03,
    },
    bitterCoast = {
        this.branchIds.ashfall_branch_bc_01,
        this.branchIds.ashfall_branch_bc_02,
        this.branchIds.ashfall_branch_bc_03,
    },
    grazelands = {
        this.branchIds.ashfall_branch_gl_01,
        this.branchIds.ashfall_branch_gl_02,
        this.branchIds.ashfall_branch_gl_03,
    },
    westGash = {
        this.branchIds.ashfall_branch_wg_01,
        this.branchIds.ashfall_branch_wg_02,
        this.branchIds.ashfall_branch_wg_03,
    },

}
this.defaultBranchGroup = branchGroups.ascadianIsles
--assign regions to branch groups
this.branchRegions = {
    --solsthiem
    ['Moesring Mountains Region'] = branchGroups.solstheim,
    ['Felsaad Coast Region'] = branchGroups.solstheim,
    ['Isinfier Plains Region'] = branchGroups.solstheim,
    ['Brodir Grove Region'] = branchGroups.solstheim,
    ['Thirsk Region'] = branchGroups.solstheim,
    ['Hirstaang Forest Region'] = branchGroups.solstheim,
    --Vvardenfell
    ['Sheogorad'] = branchGroups.azurasCoast,

    ["Azura's Coast Region"] = branchGroups.azurasCoast,
    ['Ascadian Isles Region'] = branchGroups.ascadianIsles,
    ['Grazelands Region'] = branchGroups.grazelands,
    ['Bitter Coast Region'] = branchGroups.bitterCoast,
    ['West Gash Region'] = branchGroups.westGash,
    ['Ashlands Region'] = branchGroups.ashlands,
    ['Molag Mar Region'] = branchGroups.ashlands,
    ['Red Mountain Region'] = branchGroups.ashlands,
}

--For placement magic
this.placementConfig = {
    ashfall_bedroll_ashl = { blockIllegal = true, maxSteepness = 0.4 },
    ashfall_bedroll = { blockIllegal = true, maxSteepness = 0.4 },
    ashfall_cbroll_misc = { blockIllegal = true, maxSteepness = 0.4, drop = -15 },
    
    ashfall_tent_misc = { maxSteepness = 0.4, drop = -8},
    ashfall_tent_ashl_misc = { maxSteepness = 0.4, drop = -8},
    ashfall_tent_canv_b_misc = { maxSteepness = 0.4, drop = -8},
    ashfall_tent_test_misc = { maxSteepness = 0.4, drop = -8},

    ashfall_tent_active = { maxSteepness = 0.4, drop = 50},
    ashfall_tent_ashl_active = { maxSteepness = 0.4, drop = 50},
    ashfall_tent_canv_b_active = { maxSteepness = 0.4, drop = 50},
    ashfall_tent_test_active = { maxSteepness = 0.4, drop = 50},

    a_bed_roll = { blockIllegal = true, maxSteepness = 0.4 },

    ashfall_firewood = { maxSteepness = 0.5, hasVertAlign  = true }
}

this.capacities = {
    cookingPot = 120,
    kettle = 100,
    potion = 15,
    MAX = 240
}

this.bottleConfig = {
    cup = { capacity = 25, weight = 2 },
    glass = { capacity = 25, weight = 2 },
    goblet = { capacity = 25, weight = 2 },
    mug = { capacity = 30, weight = 2 },
    tankard = { capacity = 30, weight = 2 },

    --expensive, small, good weight efficiency
    flask = { 
        capacity = 90, 
        value = 9,
        weight = 3 ,
    }, --waterPerDollar = 10, waterPerWeight = 30

    limewareFlask = { 
        capacity = 90,
        weight = 4 ,
    }, --waterPerDollar = 10, waterPerWeight = 30

    --cheap, small, medium weight efficiency
    bottle = { 
        capacity = 100, 
        value = 3,
        weight = 4,
    },-- waterPerDollar = 33, waterPerWeight = 25

    --Pots: cheap, medium sized, low weight efficiency
    pot = {
        holdsStew = true,
        capacity = 120,
        value = 4,
        weight = 6
    },--waterPerDollar = 30, waterPerWeight = 20
    redwarePot = {
        holdsStew = true,
        capacity = 120,
        value = 7,
        weight = 5
    },--waterPerDollar = 17, waterPerWeight = 24

    --cheap, very large, low weight efficiency
    jug = { 
        capacity = 220, 
        value = 5, 
        weight = 10 
    },--waterPerDollar = 44, waterPerWeight = 22

    --Pitchers tend to be best for large storage at home, not very portable

    --cheap, large, low weight efficiency
    pitcher = { 
        capacity = 200, 
        value = 7, 
        weight = 8,
    },--waterPerDollar = 25, waterPerWeight = 25

    --very cheap, large, very low weight efficiency
    metalPitcher = {
        capacity = 200, 
        value = 5, 
        weight = 8 
    },--waterPerDollar = 100, waterPerWeight = 25

    --expensive, large, medium weight efficiency
    redwarePitcher = { 
        capacity = 220, 
        value = 12, 
        weight = 8 
    },--waterPerDollar = 25, waterPerWeight = 27.5

    --Expensive, large, medium weight efficiency
    silverwarePitcher = { 
        capacity = 210, 
        value = 30, 
        weight = 7,
    },--waterPerDollar = 7, waterPerWeight = 28.5


    --Expensive, large, medium weight efficiency
    dwarvenPitcher = { 
        capacity = 240, 
        value = 40, 
        weight = 8 
    }, --waterPerDollar = 5.5, waterPerWeight = 30
} 


this.bottleList = {
    --glasses
    misc_de_glass_green_01 = this.bottleConfig.glass,
    misc_de_glass_yellow_01 = this.bottleConfig.glass,
    --cups
    misc_com_redware_cup = this.bottleConfig.cup,
    misc_com_wood_cup_01 = this.bottleConfig.cup,
    misc_com_wood_cup_02 = this.bottleConfig.cup,
    misc_lw_cup = this.bottleConfig.cup,
    misc_imp_silverware_cup = this.bottleConfig.cup,
    misc_imp_silverware_cup_01 = this.bottleConfig.cup,

    --goblets
    misc_com_metal_goblet_01 = this.bottleConfig.goblet,
    misc_com_metal_goblet_02 = this.bottleConfig.goblet,
    misc_de_goblet_01 = this.bottleConfig.goblet,
    misc_de_goblet_02 = this.bottleConfig.goblet,
    misc_de_goblet_03 = this.bottleConfig.goblet,
    misc_de_goblet_04 = this.bottleConfig.goblet,
    misc_de_goblet_05 = this.bottleConfig.goblet,
    misc_de_goblet_06 = this.bottleConfig.goblet,
    misc_de_goblet_07 = this.bottleConfig.goblet,
    misc_de_goblet_08 = this.bottleConfig.goblet,
    misc_de_goblet_09 = this.bottleConfig.goblet,
    misc_dwrv_goblet00 = this.bottleConfig.goblet,
    misc_dwrv_goblet10 = this.bottleConfig.goblet,
    misc_dwrv_goblet00_uni = this.bottleConfig.goblet,
    misc_dwrv_goblet10_uni = this.bottleConfig.goblet,
    misc_dwrv_goblet10_tgcp = this.bottleConfig.goblet,
    misc_de_goblet_01_redas = this.bottleConfig.goblet,

    --tankards
    misc_com_tankard_01 = this.bottleConfig.tankard,
    misc_de_tankard_01 = this.bottleConfig.tankard,


    --mugs
    misc_dwrv_mug00 = this.bottleConfig.mug,
    misc_dwrv_mug00_uni = this.bottleConfig.mug,

    --flasks
    misc_flask_01 = this.bottleConfig.flask,
    misc_flask_02 = this.bottleConfig.flask,
    misc_flask_03 = this.bottleConfig.flask,
    misc_flask_04 = this.bottleConfig.flask,

    misc_com_redware_flask = this.bottleConfig.flask,
    misc_lw_flask = this.bottleConfig.limewareFlask,

    --bottles
    misc_com_bottle_01 = this.bottleConfig.bottle,
    misc_com_bottle_02 = this.bottleConfig.bottle,
    misc_com_bottle_04 = this.bottleConfig.bottle,
    misc_com_bottle_05 = this.bottleConfig.bottle,
    misc_com_bottle_06 = this.bottleConfig.bottle,
    
    misc_com_bottle_08 = this.bottleConfig.bottle,
    misc_com_bottle_09 = this.bottleConfig.bottle,
    misc_com_bottle_10 = this.bottleConfig.bottle,
    misc_com_bottle_11 = this.bottleConfig.bottle,
    misc_com_bottle_13 = this.bottleConfig.bottle,
    misc_com_bottle_14 = this.bottleConfig.bottle,
    misc_com_bottle_14_float = this.bottleConfig.bottle,
    misc_com_bottle_15 = this.bottleConfig.bottle,

    --pots
    misc_de_pot_blue_01 = this.bottleConfig.pot,
    misc_de_pot_blue_02 = this.bottleConfig.pot,
    misc_de_pot_glass_peach_01 = this.bottleConfig.pot,
    misc_de_pot_glass_peach_02 = this.bottleConfig.pot,
    misc_de_pot_green_01 = this.bottleConfig.pot,
    misc_de_pot_mottled_01 = this.bottleConfig.pot,
    --redware pots
    misc_de_pot_redware_01 = this.bottleConfig.redwarePot,
    misc_de_pot_redware_02 = this.bottleConfig.redwarePot,
    misc_de_pot_redware_03 = this.bottleConfig.redwarePot,
    misc_de_pot_redware_04 = this.bottleConfig.redwarePot,
    misc_de_pot_redware_04_uni = this.bottleConfig.redwarePot,

    --jugs
    misc_com_bottle_03 = this.bottleConfig.jug,
    misc_com_bottle_07 = this.bottleConfig.jug,
    misc_com_bottle_07_float = this.bottleConfig.jug,
    misc_com_bottle_12 = this.bottleConfig.jug,

    --pitchers
    misc_de_pitcher_01 = this.bottleConfig.pitcher,
    misc_com_redware_pitcher = this.bottleConfig.redwarePitcher,
    misc_com_pitcher_metal_01 = this.bottleConfig.metalPitcher,
    misc_imp_silverware_pitcher = this.bottleConfig.silverwarePitcher,
    misc_imp_silverware_pitcher_uni = this.bottleConfig.silverwarePitcher,

    misc_dwrv_pitcher00 = this.bottleConfig.dwarvenPitcher,
    misc_dwrv_pitcher00_uni = this.bottleConfig.dwarvenPitcher,
}



this.interiorTempValues = {
    default = 0,
    sewer = -20,
    eggmine = -30,
    ruin = -35,
    dungeon = -40,
    cave = -45,
    tomb = -50, 
    barrow = -65
}
this.interiorTempPatterns = {
    [" sewers"]     = this.interiorTempValues.sewer,
    [" eggmine"]     = this.interiorTempValues.eggmine,
    [" egg mine"]     = this.interiorTempValues.eggmine,
    [" grotto"]     = this.interiorTempValues.dungeon,
    [" dungeon"]    = this.interiorTempValues.dungeon,
    [" tomb"]         = this.interiorTempValues.tomb,
    [" crypt"]         = this.interiorTempValues.tomb,
    [" catacomb"]     = this.interiorTempValues.tomb,
    [" cave"]         = this.interiorTempValues.cave,
    [" barrow"]     = this.interiorTempValues.barrow,

    --caves
    ["abanabi"] = this.interiorTempValues.cave,
    ["abernanit"] = this.interiorTempValues.cave,
    ["abinabi"] = this.interiorTempValues.cave,
    ["adanumuran"] = this.interiorTempValues.cave,
    ["addamasartus"] = this.interiorTempValues.cave,
    ["aharnabi"] = this.interiorTempValues.cave,
    ["aharunartus"] = this.interiorTempValues.cave,
    ["ahinipalit"] = this.interiorTempValues.cave,
    ["ainab"] = this.interiorTempValues.cave,
    ["ainat"] = this.interiorTempValues.cave,
    ["ansi"] = this.interiorTempValues.cave,
    ["ashanammu"] = this.interiorTempValues.cave,
    ["ashinabi"] = this.interiorTempValues.cave,
    ["ashirbadon"] = this.interiorTempValues.cave,
    ["ashir-dan"] = this.interiorTempValues.cave,
    ["ashmelech"] = this.interiorTempValues.cave,
    ["assarnud"] = this.interiorTempValues.cave,
    ["assemanu"] = this.interiorTempValues.cave,
    ["assu"] = this.interiorTempValues.cave,
    ["assumanu"] = this.interiorTempValues.cave,
    ["bensamsi"] = this.interiorTempValues.cave,
    ["beshara"] = this.interiorTempValues.cave,
    ["cavern of the incarnate"] = this.interiorTempValues.cave,
    ["corprusarium"] = this.interiorTempValues.cave,
    ["dubdilla"] = this.interiorTempValues.cave,
    ["dun-ahhe"] = this.interiorTempValues.cave,
    ["habinbaes"] = this.interiorTempValues.cave,
    ["hassour"] = this.interiorTempValues.cave,
    ["hinnabi"] = this.interiorTempValues.cave,
    ["ibar-dad"] = this.interiorTempValues.cave,
    ["ilunibi"] = this.interiorTempValues.cave,
    ["kora-dur"] = this.interiorTempValues.cave,
    ["kudanat"] = this.interiorTempValues.cave,
    ["kumarahaz"] = this.interiorTempValues.cave,
    ["kunirai"] = this.interiorTempValues.cave,
    ["maba-ilu"] = this.interiorTempValues.cave,
    ["mallapi"] = this.interiorTempValues.cave,
    ["mamaea"] = this.interiorTempValues.cave,
    ["mannammu"] = this.interiorTempValues.cave,
    ["maran-adon"] = this.interiorTempValues.cave,
    ["masseranit"] = this.interiorTempValues.cave,
    ["mat"] = this.interiorTempValues.cave,
    ["milk"] = this.interiorTempValues.cave,
    ["minabi"] = this.interiorTempValues.cave,
    ["missamsi"] = this.interiorTempValues.cave,
    ["mount kand, cavern"] = this.interiorTempValues.cave,
    ["nallit"] = this.interiorTempValues.cave,
    ["nammu"] = this.interiorTempValues.cave,
    ["nissintu"] = this.interiorTempValues.cave,
    ["nund"] = this.interiorTempValues.cave,
    ["odaishah"] = this.interiorTempValues.cave,
    ["odibaal"] = this.interiorTempValues.cave,
    ["odirnamat"] = this.interiorTempValues.cave,
    ["palansour"] = this.interiorTempValues.cave,
    ["panat"] = this.interiorTempValues.cave,
    ["pinsun"] = this.interiorTempValues.cave,
    ["piran"] = this.interiorTempValues.cave,
    ["pulk"] = this.interiorTempValues.cave,
    ["punabi"] = this.interiorTempValues.cave,
    ["punammu"] = this.interiorTempValues.cave,
    ["punsabanit"] = this.interiorTempValues.cave,
    ["rissun"] = this.interiorTempValues.cave,
    ["salmantu"] = this.interiorTempValues.cave,
    ["sanabi"] = this.interiorTempValues.cave,
    ["sanit"] = this.interiorTempValues.cave,
    ["sargon"] = this.interiorTempValues.cave,
    ["saturan"] = this.interiorTempValues.cave,
    ["sennananit"] = this.interiorTempValues.cave,
    ["sha-adnius"] = this.interiorTempValues.cave,
    ["shal"] = this.interiorTempValues.cave,
    ["shallit"] = this.interiorTempValues.cave,
    ["sharapli"] = this.interiorTempValues.cave,
    ["shurinbaal"] = this.interiorTempValues.cave,
    ["shushan"] = this.interiorTempValues.cave,
    ["shushishi"] = this.interiorTempValues.cave,
    ["sinsibadon"] = this.interiorTempValues.cave,
    ["subdun"] = this.interiorTempValues.cave,
    ["sud"] = this.interiorTempValues.cave,
    ["surirulk"] = this.interiorTempValues.cave,
    ["tin-ahhe"] = this.interiorTempValues.cave,
    ["tukushapal"] = this.interiorTempValues.cave,
    ["ulummusa"] = this.interiorTempValues.cave,
    ["yakanalit"] = this.interiorTempValues.cave,
    ["yakin"] = this.interiorTempValues.cave,
    ["yasamsi"] = this.interiorTempValues.cave,
    ["yesamsi"] = this.interiorTempValues.cave,
    ["zainsipilu"] = this.interiorTempValues.cave,
    ["zaintirari"] = this.interiorTempValues.cave,
    ["zanabi"] = this.interiorTempValues.cave,
    ["zebabi"] = this.interiorTempValues.cave,
    ["zenarbael"] = this.interiorTempValues.cave,

    --ruins
    ["aleft"] = this.interiorTempValues.ruin,
    ["arkngthand"] = this.interiorTempValues.ruin,
    ["arkngthunch-sturdumz"] = this.interiorTempValues.ruin,
    ["bethamez"] = this.interiorTempValues.ruin,
    ["bthanchend"] = this.interiorTempValues.ruin,
    ["bthuand"] = this.interiorTempValues.ruin,
    ["bthungthumz"] = this.interiorTempValues.ruin,
    ["dagoth ur"] = this.interiorTempValues.ruin,
    ["druscashti"] = this.interiorTempValues.ruin,
    ["endusal"] = this.interiorTempValues.ruin,
    ["galom daeus"] = this.interiorTempValues.ruin,
    ["mudan"] = this.interiorTempValues.ruin,
    ["mzahnch"] = this.interiorTempValues.ruin,
    ["mzanchend"] = this.interiorTempValues.ruin,
    ["mzuleft"] = this.interiorTempValues.ruin,
    ["nchardahrk"] = this.interiorTempValues.ruin,
    ["nchardumz"] = this.interiorTempValues.ruin,
    ["nchuleft"] = this.interiorTempValues.ruin,
    ["nchuleftingth"] = this.interiorTempValues.ruin,
    ["nchurdamz"] = this.interiorTempValues.ruin,
    ["odrosal"] = this.interiorTempValues.ruin,
    ["tureynulal"] = this.interiorTempValues.ruin,
    ["vemynal"] = this.interiorTempValues.ruin,
}


return this