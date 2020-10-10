local this = {}

function this.getFoodType(obj)
    local foodType =  this.ingredTypes[obj.id]
    -- if not foodType and obj.objectType == tes3.objectType.ingredient then
    --     foodType = this.TYPE.misc
    -- end
    return foodType
end

--Handles special case for pre-cooked meat
function this.getFoodTypeResolveMeat(obj)

    local foodType = this.getFoodType(obj)
    if foodType == this.TYPE.cookedMeat then
        foodType = this.TYPE.meat
    end
    return foodType
end


function this.getNutrition(obj)
    return this.nutrition[this.getFoodType(obj)]
end

function this.getNutritionForFoodType(foodType)
    return this.nutrition[foodType]
end

function this.getGrillValues(obj)
    return this.grillValues[this.getFoodType(obj)]
end

function this.getGrillValuesForFoodType(foodType)
    return this.grillValues[foodType]
end

function this.getStewBuffForId(obj)
    return this.stewBuffs[this.getFoodType(obj)]
end

function this.getStewBuffForFoodType(foodType)
    if foodType == this.TYPE.cookedMeat then
        foodType = this.TYPE.meat
    end
    return this.stewBuffs[foodType]
end

function this.getStewBuffList()
    return this.stewBuffs
end

function this.getFoodData(obj, resolveMeat)
    local foodType = resolveMeat and this.getFoodTypeResolveMeat(obj) or this.getFoodType(obj)
    if not foodType then return nil end
    return {
        foodType = foodType,
        nutrition = this.getNutritionForFoodType(foodType),
        grillValues = this.getGrillValuesForFoodType(foodType),
        stewBuff = this.getStewBuffForFoodType(foodType)
    }
end

function this.isStewNotSoup(stewLevels)
    local isStew = false
    for stewType, _ in pairs(stewLevels) do
        local data = this.getStewBuffForFoodType(stewType)
        if data.notSoup then isStew = true end
    end
    return isStew
end

this.TYPE = {
    meat = "Meat",
    cookedMeat = "Meat (Cooked)",
    egg = "Egg",
    vegetable = "Vegetable",
    mushroom = "Mushroom",
    seasoning = "Seasoning",
    herb = "Herb",
    food = "Food",
    misc = nil
}

this.stewBuffs = {
    [this.TYPE.meat] = { 
        notSoup = true,
        stewNutrition = 1.0,
        min = 10, max = 30, 
        id = "ashfall_stew_hearty",
        tooltip = "A hearty meat stew that fortifies your health.",
    }, -- fortify health
    [this.TYPE.vegetable] = { 
        notSoup = true,
        stewNutrition = 0.9,
        min = 10, max = 30, 
        id = "ashfall_stew_nutritious",
        tooltip = "A nutritious vegetable stew that fortifies your fatigue.",
    }, --fortify fatigue
    [this.TYPE.mushroom] = { 
        notSoup = true,
        stewNutrition = 0.8,
        min = 10, max = 25, 
        id = "ashfall_stew_chunky",
        tooltip = "A chunky mushroom stew that fortifies your magicka.",
    }, --fortify magicka
    [this.TYPE.seasoning] = { 
        notSoup = false,
        stewNutrition = 0.3,
        min = 5, max = 20, 
        id = "ashfall_stew_tasty",
        tooltip = "A tasty seasoned soup that fortifies your agility.",
    }, --fortify agility
    [this.TYPE.herb] = { 
        notSoup = false,
        stewNutrition = 0.4,
        min = 5, max = 20, 
        id = "ashfall_stew_aromatic",
        tooltip = "An aromatic soup, rich in herbs,that fortifies your personality.",
        } -- fortify personality
}

--min: fully cooked multi at lowest cooking skill
--max fully cooked multi at highest cooking skill
this.grillValues = {
    [this.TYPE.meat] = { min = 2.5, max = 3.0 },
    [this.TYPE.egg] = { min = 2.5, max = 3.0 },
    [this.TYPE.vegetable] = { min = 2.2, max = 2.7 },
    [this.TYPE.mushroom] = { min = 2.0, max = 2.5 },
}

--Nutrition at weight==1.0
this.nutrition = {
    [this.TYPE.meat] = 12,
    [this.TYPE.cookedMeat] = (12 * this.grillValues[this.TYPE.meat].min), 
    [this.TYPE.egg] = 10,
    [this.TYPE.vegetable] = 14,
    [this.TYPE.mushroom] = 13,
    [this.TYPE.seasoning] = 8,
    [this.TYPE.herb] = 10,
    [this.TYPE.food] = 30,
    --[this.TYPE.misc] = 0,
}

this.ingredTypes = {
    ["ingred_human_meat_01"] = this.TYPE.meat,
    ["ingred_adamantium_ore_01"] = this.TYPE.misc,
    ["ingred_alit_hide_01"] = this.TYPE.misc,
    ["ingred_bc_ampoule_pod"] = this.TYPE.misc,
    ["ingred_ash_salts_01"] = this.TYPE.seasoning,
    ["ingred_ash_yam_01"] = this.TYPE.vegetable,
    ["ingred_bear_pelt"] = this.TYPE.misc,
    ["ingred_bittergreen_petals_01"] = this.TYPE.herb,
    ["ingred_black_anther_01"] = this.TYPE.herb,
    ["ingred_black_lichen_01"] = this.TYPE.misc,
    ["ingred_bloat_01"] = this.TYPE.misc,
    ["ingred_blood_innocent_unique"] = this.TYPE.misc,
    ["ingred_bonemeal_01"] = this.TYPE.misc,
    ["ingred_bread_01"] = this.TYPE.food,
    ["ingred_bread_01_UNI2"] = this.TYPE.food,
    ["ingred_boar_leather"] = this.TYPE.misc,
    ["ingred_bc_bungler's_bane"] = this.TYPE.mushroom,
    ["ingred_chokeweed_01"] = this.TYPE.herb,
    ["ingred_bc_coda_flower"] = this.TYPE.herb,
    ["ingred_comberry_01"] = this.TYPE.herb,
    ["ingred_corkbulb_root_01"] = this.TYPE.vegetable,
    ["ingred_corprus_weepings_01"] = this.TYPE.misc,
    ["ingred_crab_meat_01"] = this.TYPE.meat,
    ["ingred_daedra_skin_01"] = this.TYPE.misc,
    ["ingred_cursed_daedras_heart_01"] = this.TYPE.misc,
    ["ingred_daedras_heart_01"] = this.TYPE.misc,
    ["ingred_Dae_cursed_diamond_01"] = this.TYPE.misc,
    ["ingred_diamond_01"] = this.TYPE.misc,
    ["ingred_dreugh_wax_01"] = this.TYPE.misc,
    ["ingred_durzog_meat_01"] = this.TYPE.meat,
    ["ingred_ectoplasm_01"] = this.TYPE.misc,
    ["ingred_Dae_cursed_emerald_01"] = this.TYPE.misc,
    ["ingred_emerald_01"] = this.TYPE.misc,
    ["ingred_fire_petal_01"] = this.TYPE.herb,
    ["ingred_fire_salts_01"] = this.TYPE.seasoning,
    ["ingred_eyeball_unique"] = this.TYPE.misc,
    ["ingred_frost_salts_01"] = this.TYPE.seasoning,
    ["ingred_ghoul_heart_01"] = this.TYPE.misc,
    ["ingred_guar_hide_girith"] = this.TYPE.misc,
    ["ingred_gold_kanet_01"] = this.TYPE.herb,
    ["Ingred_golden_sedge_01"] = this.TYPE.herb,
    ["ingred_eyeball"] = this.TYPE.misc,
    ["ingred_gravedust_01"] = this.TYPE.misc,
    ["ingred_gravetar_01"] = this.TYPE.misc,
    ["ingred_green_lichen_01"] = this.TYPE.misc,
    ["ingred_guar_hide_01"] = this.TYPE.misc,
    ["ingred_hackle-lo_leaf_01"] = this.TYPE.herb,
    ["ingred_innocent_heart"] = this.TYPE.misc,
    ["ingred_udyrfrykte_heart"] = this.TYPE.misc,
    ["ingred_wolf_heart"] = this.TYPE.meat,
    ["ingred_heartwood_01"] = this.TYPE.misc,
    ["ingred_heather_01"] = this.TYPE.herb,
    ["ingred_holly_01"] = this.TYPE.herb,
    ["ingred_horker_tusk_01"] = this.TYPE.misc,
    ["Ingred_horn_lily_bulb_01"] = this.TYPE.vegetable,
    ["ingred_hound_meat_01"] = this.TYPE.meat,
    ["ingred_bc_hypha_facia"] = this.TYPE.mushroom,
    ["ingred_kagouti_hide_01"] = this.TYPE.misc,
    ["ingred_kresh_fiber_01"] = this.TYPE.herb,
    ["ingred_kwama_cuttle_01"] = this.TYPE.meat,
    ["ingred_6th_corprusmeat_05"] = this.TYPE.meat,
    ["food_kwama_egg_02"] = this.TYPE.egg,
    ["ingred_6th_corprusmeat_01"] = this.TYPE.meat,
    ["Ingred_lloramor_spines_01"] = this.TYPE.herb,
    ["ingred_russula_01"] = this.TYPE.mushroom,
    ["ingred_marshmerrow_01"] = this.TYPE.vegetable,
    ["ingred_guar_hide_marsus"] = this.TYPE.misc,
    ["Ingred_meadow_rye_01"] = this.TYPE.herb,
    ["ingred_6th_corprusmeat_06"] = this.TYPE.meat,
    ["ingred_6th_corprusmeat_03"] = this.TYPE.meat,
    ["ingred_scrib_jelly_02"] = this.TYPE.meat,
    ["ingred_moon_sugar_01"] = this.TYPE.misc,
    ["ingred_muck_01"] = this.TYPE.misc,
    ["ingred_bread_01_UNI3"] = this.TYPE.food,
    ["ingred_netch_leather_01"] = this.TYPE.misc,
    ["Ingred_nirthfly_stalks_01"] = this.TYPE.herb,
    ["Ingred_noble_sedge_01"] = this.TYPE.herb,
    ["ingred_Dae_cursed_pearl_01"] = this.TYPE.misc,
    ["ingred_pearl_01"] = this.TYPE.misc,
    ["ingred_emerald_pinetear"] = this.TYPE.misc,
    ["poison_goop00"] = this.TYPE.misc,
    ["ingred_racer_plumes_01"] = this.TYPE.misc,
    ["ingred_rat_meat_01"] = this.TYPE.meat,
    ["ingred_Dae_cursed_raw_ebony_01"] = this.TYPE.misc,
    ["ingred_raw_ebony_01"] = this.TYPE.misc,
    ["ingred_raw_glass_01"] = this.TYPE.misc,
    ["ingred_raw_glass_tinos"] = this.TYPE.misc,
    ["ingred_raw_Stalhrim_01"] = this.TYPE.misc,
    ["ingred_red_lichen_01"] = this.TYPE.misc,
    ["ingred_resin_01"] = this.TYPE.misc,
    ["ingred_belladonna_01"] = this.TYPE.herb,
    ["ingred_gold_kanet_unique"] = this.TYPE.herb,
    ["ingred_roobrush_01"] = this.TYPE.herb,
    ["ingred_Dae_cursed_ruby_01"] = this.TYPE.misc,
    ["ingred_ruby_01"] = this.TYPE.misc,
    ["ingred_saltrice_01"] = this.TYPE.vegetable,
    ["ingred_scales_01"] = this.TYPE.misc,
    ["ingred_scamp_skin_01"] = this.TYPE.misc,
    ["ingred_scathecraw_01"] = this.TYPE.herb,
    ["ingred_scrap_metal_01"] = this.TYPE.misc,
    ["Ingred_scrib_cabbage_01"] = this.TYPE.meat,
    ["ingred_scrib_jelly_01"] = this.TYPE.meat,
    ["ingred_scrib_jerky_01"] = this.TYPE.food,
    ["ingred_scuttle_01"] = this.TYPE.food,
    ["ingred_shalk_resin_01"] = this.TYPE.misc,
    ["ingred_sload_soap_01"] = this.TYPE.misc,
    ["ingred_6th_corprusmeat_07"] = this.TYPE.meat,
    ["food_kwama_egg_01"] = this.TYPE.egg,
    ["ingred_6th_corprusmeat_02"] = this.TYPE.meat,
    ["ingred_snowbear_pelt_unique"] = this.TYPE.misc,
    ["ingred_snowwolf_pelt_unique"] = this.TYPE.misc,
    ["ingred_bc_spore_pod"] = this.TYPE.herb,
    ["ingred_stoneflower_petals_01"] = this.TYPE.herb,
    ["Ingred_sweetpulp_01"] = this.TYPE.herb,
    ["Ingred_timsa-come-by_01"] = this.TYPE.herb,
    ["ingred_trama_root_01"] = this.TYPE.vegetable,
    ["ingred_treated_bittergreen_uniq"] = this.TYPE.herb,
    ["ingred_belladonna_02"] = this.TYPE.herb,
    ["ingred_vampire_dust_01"] = this.TYPE.misc,
    ["ingred_coprinus_01"] = this.TYPE.mushroom,
    ["ingred_void_salts_01"] = this.TYPE.seasoning,
    ["ingred_wickwheat_01"] = this.TYPE.herb,
    ["ingred_willow_anther_01"] = this.TYPE.herb,
    ["ingred_wolf_pelt"] = this.TYPE.misc,
    ["ingred_wolfsbane_01"] = this.TYPE.misc,
    ["ingred_6th_corprusmeat_04"] = this.TYPE.meat,

    --TR meats

    ["T_IngFood_Apple_01"] = this.TYPE.food,
    ["T_IngFood_AppleSkyrim_01"] = this.TYPE.food,
    ["T_IngFood_Blackberry_01"] = this.TYPE.food,
    ["T_IngFood_BreadColovian_01"] = this.TYPE.food,
    ["T_IngFood_BreadColovian_02"] = this.TYPE.food,
    ["T_IngFood_BreadColovianMw_01"] = this.TYPE.food,
    ["T_IngFood_BreadColovianMw_02"] = this.TYPE.food,
    ["T_IngFood_BreadDeshaan_01"] = this.TYPE.food,
    ["T_IngFood_BreadDeshaan_02"] = this.TYPE.food,
    ["T_IngFood_BreadDeshaan_03"] = this.TYPE.food,
    ["T_IngFood_BreadDeshaan_04"] = this.TYPE.food,
    ["T_IngFood_BreadDeshaan_05"] = this.TYPE.food,
    ["T_IngFood_BreadFlat_01"] = this.TYPE.food,
    ["T_IngFood_BreadFlat_02"] = this.TYPE.food,
    ["T_IngFood_BreadFlat_03"] = this.TYPE.food,
    ["T_IngFood_Carrot_01"] = this.TYPE.vegetable,
    ["T_IngFood_CheeseColovian_01"] = this.TYPE.food,
    ["T_IngFood_CheeseNord_01"] = this.TYPE.food,
    ["T_IngFood_CheeseWheelNord_01"] = this.TYPE.food,
    ["T_IngFood_CheeseWheelNord_02"] = this.TYPE.food,
    ["T_IngFood_CloudyCorn_01"] = this.TYPE.food,
    ["T_IngFood_Cookie_01"] = this.TYPE.food,
    ["T_IngFood_Cookie_02"] = this.TYPE.food,
    ["T_IngFood_EggChicken_01"] = this.TYPE.egg,
    ["T_IngFood_EggMolecrab_01"] = this.TYPE.egg,
    ["T_IngFood_EggOrnada_01"] = this.TYPE.egg,
    ["T_IngFood_Fig_01"] = this.TYPE.food,
    ["T_IngFood_Fig_Dried_01"] = this.TYPE.food,
    ["T_IngFood_FishBrowntrout_01"] = this.TYPE.meat,
    ["T_IngFood_FishChrysophant_01"] = this.TYPE.meat,
    ["T_IngFood_FishCod_01"] = this.TYPE.meat,
    ["T_IngFood_FishCodDried_01"] = this.TYPE.food,
    ["T_IngFood_FishLeaperTail_01"] = this.TYPE.meat,
    ["T_IngFood_FishLongfinFilet_01"] = this.TYPE.cookedMeat,
    ["T_IngFood_FishPike_01"] = this.TYPE.meat,
    ["T_IngFood_FishPikeperch_01"] = this.TYPE.meat,
    ["T_IngFood_FishSalmon_01"] = this.TYPE.meat,
    ["T_IngFood_FishSlaughterDried_01"] = this.TYPE.food,
    ["T_IngFood_FishSlaughterDried_02"] = this.TYPE.food,
    ["T_IngFood_FishSlaughterDried_03"] = this.TYPE.food,
    ["T_IngFood_FishSpr_01"] = this.TYPE.meat,
    ["T_IngFood_FishStrid_01"] = this.TYPE.meat,
    ["T_IngFood_Flour_01"] = this.TYPE.food,
    ["T_IngFood_Garlic_01"] = this.TYPE.food,
    ["T_IngFood_Grape_01"] = this.TYPE.food,
    ["T_IngFood_Grape_02"] = this.TYPE.food,
    ["T_IngFood_GrapeWrothgarian_01"] = this.TYPE.food,
    ["T_IngFood_Honey_01"] = this.TYPE.food,
    ["T_IngFood_Indureta_01"] = this.TYPE.food,
    ["T_IngFood_Ironrye_01"] = this.TYPE.food,
    ["T_IngFood_Leek_01"] = this.TYPE.herb,
    ["T_IngFood_Lyco_01"] = this.TYPE.food,
    ["T_IngFood_MeatAlit_01"] = this.TYPE.meat,
    ["T_IngFood_MeatBeef_01"] = this.TYPE.meat,
    ["T_IngFood_MeatBoar_01"] = this.TYPE.meat,
    ["T_IngFood_MeatBoar_02"] = this.TYPE.meat,
    ["T_IngFood_MeatBoarRoast_02"] = this.TYPE.cookedMeat,
    ["T_IngFood_MeatChicken_01"] = this.TYPE.meat,
    ["T_IngFood_MeatChickenRoast_01"] = this.TYPE.cookedMeat,
    ["T_IngFood_MeatCliffracer_01"] = this.TYPE.meat,
    ["T_IngFood_MeatDurzog_01"] = this.TYPE.cookedMeat,
    ["T_IngFood_MeatGuar_01"] = this.TYPE.meat,
    ["T_IngFood_MeatHam_01"] = this.TYPE.meat,
    ["T_IngFood_MeatHorker_01"] = this.TYPE.meat,
    ["T_IngFood_MeatKagouti_01"] = this.TYPE.meat,
    ["T_IngFood_MeatKwama_01"] = this.TYPE.meat,
    ["T_IngFood_MeatMutton_01"] = this.TYPE.meat,
    ["T_IngFood_MeatNixhoundRoast_01"] = this.TYPE.cookedMeat,
    ["T_IngFood_MeatOrnada_01"] = this.TYPE.meat,
    ["T_IngFood_MeatParastylus_01"] = this.TYPE.meat,
    ["T_IngFood_MeatRat_01"] = this.TYPE.cookedMeat,
    ["T_IngFood_MeatRatRoast_01"] = this.TYPE.cookedMeat,
    ["T_IngFood_MeatVenison_01"] = this.TYPE.meat,
    ["T_IngFood_MeatVenisonRoast_01"] = this.TYPE.cookedMeat,
    ["T_IngFood_Olives_01"] = this.TYPE.food,
    ["T_IngFood_Onion_01"] = this.TYPE.food,
    ["T_IngFood_PoppadGourd_01"] = this.TYPE.food,
    ["T_IngFood_Potato_01"] = this.TYPE.vegetable,
    ["T_IngFood_Radish_01"] = this.TYPE.food,
    ["T_IngFood_Rice_01"] = this.TYPE.food,
    ["T_IngFood_ScribPie_01"] = this.TYPE.food,
    ["T_IngFood_SilverPalmfruit_01"] = this.TYPE.food,
    ["T_IngFood_Snowberry_01"] = this.TYPE.food,
    ["T_IngFood_Strawberry_01"] = this.TYPE.food,
    ["T_IngFood_Sweetroll_01"] = this.TYPE.food,
    ["T_IngFood_Tomato_01"] = this.TYPE.vegetable,
    ["T_IngFood_TrinityFruit_01"] = this.TYPE.food,
    ["T_IngFood_WasabiPowder_01"] = this.TYPE.food,
    ["T_IngFood_WasabiRoot_01"] = this.TYPE.food,
    ["T_IngFood_Wheat_01"] = this.TYPE.food,

    --Cannibals
    
    ["MOR_redguard_heart"] = this.TYPE.meat,
    ["MOR_redguard_flesh"] = this.TYPE.meat,
    ["MOR_redguard_eye"] = this.TYPE.meat,
    ["MOR_redguard_brain"] = this.TYPE.meat,
    ["MOR_orc_heart"] = this.TYPE.meat,
    ["MOR_orc_flesh"] = this.TYPE.meat,
    ["MOR_orc_eye"] = this.TYPE.meat,
    ["MOR_orc_brain"] = this.TYPE.meat,
    ["MOR_nord_heart"] = this.TYPE.meat,
    ["MOR_nord_flesh"] = this.TYPE.meat,
    ["MOR_nord_brain"] = this.TYPE.meat,
    ["MOR_nord_bones"] = this.TYPE.misc,
    ["MOR_khajiit_heart"] = this.TYPE.meat,
    ["MOR_khajiit_flesh"] = this.TYPE.meat,
    ["MOR_khajiit_eye"] = this.TYPE.meat,
    ["MOR_khajiit_ear"] = this.TYPE.meat,
    ["MOR_khajiit_brain"] = this.TYPE.meat,
    ["MOR_intestine"] = this.TYPE.meat,
    ["MOR_imperial_tongue"] = this.TYPE.meat,
    ["MOR_imperial_heart"] = this.TYPE.meat,
    ["MOR_Imperial_flesh"] = this.TYPE.meat,
    ["MOR_imperial_eye"] = this.TYPE.meat,
    ["MOR_imperial_brain"] = this.TYPE.meat,
    ["MOR_dunmer_heart"] = this.TYPE.meat,
    ["MOR_dunmer_flesh"] = this.TYPE.meat,
    ["MOR_dunmer_eye"] = this.TYPE.meat,
    ["MOR_dunmer_brain"] = this.TYPE.meat,
    ["MOR_breton_heart"] = this.TYPE.meat,
    ["MOR_breton_flesh"] = this.TYPE.meat,
    ["MOR_breton_eye"] = this.TYPE.meat,
    ["MOR_breton_brain"] = this.TYPE.meat,
    ["MOR_bosmer_heart"] = this.TYPE.misc,
    ["MOR_bosmer_flesh"] = this.TYPE.meat,
    ["MOR_bosmer_eye"] = this.TYPE.meat,
    ["MOR_bosmer_brain"] = this.TYPE.meat,
    ["MOR_argo_tail"] = this.TYPE.meat,
    ["MOR_argo_heart"] = this.TYPE.meat,
    ["MOR_argo_flesh"] = this.TYPE.meat,
    ["MOR_argo_eye"] = this.TYPE.meat,
    ["MOR_arg_brain"] = this.TYPE.meat,
    ["MOR_altmer_heart"] = this.TYPE.meat,
    ["MOR_altmer_flesh"] = this.TYPE.meat,
    ["MOR_altmer_brain"] = this.TYPE.meat,
    ["MOR_altmer_eye"] = this.TYPE.meat,	
    
    --PL Creatures
    
    ["plx_wasp_sting"] = this.TYPE.misc,
    ["plx_vissed_meat"] = this.TYPE.meat,
    ["plx_squirrel_tail"] = this.TYPE.misc,
    ["plx_slarsa_meat"] = this.TYPE.meat,
    ["plx_scorp_sting"] = this.TYPE.misc,
    ["plx_Rhurlymn_meat"] = this.TYPE.meat,
    ["plx_rat_meat_D"] = this.TYPE.misc,
    ["plx_rat_meat_B"] = this.TYPE.misc,
    ["plx_raptor_meat"] = this.TYPE.meat,
    ["plx_rabbit_foot"] = this.TYPE.misc,
    ["plx_netch_jelly"] = this.TYPE.misc,
    ["plx_moose_antlers"] = this.TYPE.misc,
    ["plx_kagouti_meat_B"] = this.TYPE.misc,
    ["plx_kagouti_meat"] = this.TYPE.meat,
    ["plx_ingred_spidersilk"] = this.TYPE.misc,
    ["plx_ingred_shell_shalk"] = this.TYPE.misc,
    ["plx_ingred_shell_scrib"] = this.TYPE.misc,
    ["plx_ingred_shell_scarab"] = this.TYPE.misc,
    ["plx_ingred_Shell_Para"] = this.TYPE.misc,
    ["plx_ingred_shell_beetle4"] = this.TYPE.misc,
    ["plx_ingred_shell_beetle3"] = this.TYPE.misc,
    ["plx_ingred_shell_beetle2"] = this.TYPE.misc,
    ["plx_ingred_shell_beetle1"] = this.TYPE.misc,
    ["plx_ingred_paraflesh"] = this.TYPE.meat,
    ["plx_ingred_kriin_hide"] = this.TYPE.misc,
    ["plx_ingred_kriin_flesh"] = this.TYPE.meat,
    ["plx_ingred_HellHound"] = this.TYPE.meat,
    ["plx_ingred_daedricbat"] = this.TYPE.misc,
    ["plx_imp_glands"] = this.TYPE.misc,
    ["plx_hound_meat_D"] = this.TYPE.misc,
    ["plx_hound_meat_B"] = this.TYPE.misc,
    ["plx_guar_meat"] = this.TYPE.meat,
    ["plx_grom"] = this.TYPE.misc,
    ["plx_gargoyle_grains"] = this.TYPE.misc,
    ["plx_crab_meat_D"] = this.TYPE.misc,
    ["plx_butterfly_wing"] = this.TYPE.misc,
    ["plx_butterfly2_wing"] = this.TYPE.misc,
    ["plx_alit_meat_D"] = this.TYPE.misc,
    ["plx_alit_meat_B"] = this.TYPE.misc,
    ["plx_alit_meat"] = this.TYPE.meat,

    
    --Abot's Water Life and Birds
    
    ["ab01ingred_bee"] = this.TYPE.misc,
    ["ab01ingred_bird_meat"] = this.TYPE.meat,
    ["ab01ingred_bird_plumes"] = this.TYPE.misc,
    ["ab01ingred_butt01wing"] = this.TYPE.misc,
    ["ab01ingred_butt02wing"] = this.TYPE.misc,
    ["ab01ingred_butt03wing"] = this.TYPE.misc,
    ["ab01ingred_butt04wing"] = this.TYPE.misc,
    ["ab01ingred_chiton01"] = this.TYPE.misc,
    ["ab01ingred_chiton02"] = this.TYPE.misc,
    ["ab01ingred_chiton03"] = this.TYPE.misc,
    ["ab01ingred_chiton04"] = this.TYPE.misc,
    ["ab01ingred_chiton05"] = this.TYPE.misc,
    ["ab01ingred_chiton06"] = this.TYPE.misc,
    ["ab01ingred_chiton07"] = this.TYPE.misc,
    ["ab01ingred_chiton08"] = this.TYPE.misc,
    ["ab01ingred_chiton09"] = this.TYPE.misc,
    ["ab01ingred_chiton10"] = this.TYPE.misc,
    ["ab01ingred_coral01"] = this.TYPE.misc,
    ["ab01ingred_coral02"] = this.TYPE.misc,
    ["ab01ingred_coral03"] = this.TYPE.misc,
    ["ab01ingred_coral04"] = this.TYPE.misc,
    ["ab01ingred_coral05"] = this.TYPE.misc,
    ["ab01ingred_coral06"] = this.TYPE.misc,
    ["ab01ingred_coral07"] = this.TYPE.misc,
    ["ab01ingred_coral08"] = this.TYPE.misc,
    ["ab01ingred_coral09"] = this.TYPE.misc,
    ["ab01ingred_egg02"] = this.TYPE.egg,
    ["ab01ingred_eggGold"] = this.TYPE.egg,
    ["ab01ingred_firefly"] = this.TYPE.misc,
    ["ab01ingred_greyMatter"] = this.TYPE.misc,
    ["ab01ingred_grom"] = this.TYPE.misc,
    ["ab01ingred_jellyFish"] = this.TYPE.misc,
    ["ab01ingred_manateeFin"] = this.TYPE.misc,
    ["ab01ingred_octopus"] = this.TYPE.misc,
    ["ab01ingred_penguinFin"] = this.TYPE.misc,
    ["ab01ingred_sandCoin01"] = this.TYPE.misc,
    ["ab01ingred_sandCoin02"] = this.TYPE.misc,
    ["ab01ingred_sandCoin03"] = this.TYPE.misc,
    ["ab01ingred_sandCoin04"] = this.TYPE.misc,
    ["ab01ingred_sandCoin05"] = this.TYPE.misc,
    ["ab01ingred_sandCoin06"] = this.TYPE.misc,
    ["ab01ingred_sandCoin07"] = this.TYPE.misc,
    ["ab01ingred_sandCoin08"] = this.TYPE.misc,
    ["ab01ingred_seaHorse"] = this.TYPE.misc,
    ["ab01ingred_sealBlubber"] = this.TYPE.misc,
    ["ab01ingred_seaStar01"] = this.TYPE.meat,
    ["ab01ingred_seaStar02"] = this.TYPE.meat,
    ["ab01ingred_seaStar03"] = this.TYPE.meat,
    ["ab01ingred_seaStar05"] = this.TYPE.meat,
    ["ab01ingred_seaStar06"] = this.TYPE.meat,
    ["ab01ingred_seaStar07"] = this.TYPE.meat,
    ["ab01ingred_sharkJaws"] = this.TYPE.misc,
    ["ab01ingred_sharkTooth"] = this.TYPE.misc,
    ["ab01ingred_shell01"] = this.TYPE.misc,
    ["ab01ingred_shell02"] = this.TYPE.misc,
    ["ab01ingred_shell03"] = this.TYPE.misc,
    ["ab01ingred_shell04"] = this.TYPE.misc,
    ["ab01ingred_shell05"] = this.TYPE.misc,
    ["ab01ingred_shell06"] = this.TYPE.misc,
    ["ab01ingred_shell07"] = this.TYPE.misc,
    ["ab01ingred_snailGoo"] = this.TYPE.misc,
    ["ab01ingred_snailGoop"] = this.TYPE.misc,
    ["ab01ingred_spermwhaleTooth"] = this.TYPE.misc,
    ["ab01ingred_turtleMeat"] = this.TYPE.meat,
    ["db_vegi_batfur"] = this.TYPE.misc,
    ["db_vegi_batwing"] = this.TYPE.misc,
    ["FKA_feathers"] = this.TYPE.misc,
    ["LL_Ingr_Sponge1"] = this.TYPE.misc,
    ["LL_Ingr_Sponge2"] = this.TYPE.misc,
    ["LL_Ingr_Sponge3"] = this.TYPE.misc,
    ["ndib_ingred_pearl_black"] = this.TYPE.misc,
    ["NOM_food_fish"] = this.TYPE.meat,
    ["NOM_food_fish_fat_01"] = this.TYPE.meat,
    ["NOM_food_fish_fat_02"] = this.TYPE.meat,
    ["NOM_food_meat"] = this.TYPE.meat,
    ["ab01ingred_barnacles01"] = this.TYPE.misc,
    ["ab01ingred_alga05"] = this.TYPE.herb,
    ["ab01ingred_alga04"] = this.TYPE.herb,
    ["ab01ingred_alga03"] = this.TYPE.herb,
    ["ab01ingred_alga02"] = this.TYPE.herb,
    ["ab01ingred_alga01"] = this.TYPE.herb,


    
    --Danae's Cliff Racers
    ["mc_racer_raw"] = this.TYPE.meat,
    
    --My custom

    ["mer_ingfood_fish"] = this.TYPE.meat,
    
    --TR
    ["T_IngSpice_Saffron_01"] = this.TYPE.seasoning,
	["T_IngSpice_Pepper_01"] = this.TYPE.seasoning,
	["T_IngSpice_Nigella_01"] = this.TYPE.seasoning,	
	["T_IngSpice_Muscat_01"] = this.TYPE.seasoning,
	["T_IngSpice_Hibiscus_01"] = this.TYPE.herb,
	["T_IngSpice_Curcuma_01"] = this.TYPE.seasoning,
	["T_IngSpice_Cardamon_01"] = this.TYPE.seasoning,
	["T_IngSpice_Anise_01"] = this.TYPE.seasoning,
	["T_IngFood_MeatHorse_01"] = this.TYPE.meat,
	["T_IngFood_MeatArenthJerky_01"]= this.TYPE.food,
	["T_IngFood_Gooseb01"] = this.TYPE.food,
	["T_IngFood_EggSeagull_01"] = this.TYPE.egg,
	["T_IngFood_BridethornBerry_01"] = this.TYPE.food,
	["T_IngFlor_SummerBolete_01"] = this.TYPE.mushroom,
	["T_IngFlor_RustRussula_01"] = this.TYPE.mushroom,
	["T_IngFlor_Primrose_01"] = this.TYPE.herb,
	["T_IngFlor_Lavender_01"] = this.TYPE.herb,
	["T_IngFlor_KingBolete_01"] = this.TYPE.mushroom,
	["T_IngFlor_Ginseng_01"] = this.TYPE.herb,
	["T_IngFlor_Chokeberry_01"] = this.TYPE.herb,
	["T_IngFlor_CairnBolete_01"] = this.TYPE.mushroom,
	["T_IngFlor_Cabbage_02"] = this.TYPE.vegetable,
	["T_IngFlor_Cabbage_01"] = this.TYPE.vegetable,
    ["T_IngFlor_AspyrTea_01"] = this.TYPE.herb,
    ["T_IngFlor_TempleDome_01"] = this.TYPE.mushroom,
    

    --NOM (UL)
    ["NOM_food_a_apple"] = this.TYPE.food,
    ["NOM_food_a_lemon"] = this.TYPE.food,
    ["NOM_food_ash_yam"] = this.TYPE.food,
    ["NOM_food_bittergreen"] = this.TYPE.food,
    ["NOM_food_boiled_rice"] = this.TYPE.food,
    ["NOM_food_boiled_rice2"] = this.TYPE.food,
    ["NOM_food_cabbage"] = this.TYPE.food,
    ["NOM_food_corkbulb_roast"] = this.TYPE.food,
    ["NOM_food_crab_slice"] = this.TYPE.food,
    ["NOM_food_egg2"] = this.TYPE.egg,
    ["NOM_food_fruit_salad"] = this.TYPE.food,
    ["NOM_food_grilled_fish"] = this.TYPE.food,
    ["NOM_food_hackle-lo"] = this.TYPE.food,
    ["NOM_food_lemon_fish"] = this.TYPE.food,
    ["NOM_food_marshmerrow"] = this.TYPE.food,
    ["NOM_food_meat_grilled2"] = this.TYPE.food,
    ["NOM_food_moon_pudding"] = this.TYPE.food,
    ["NOM_food_omelette"] = this.TYPE.food,
    ["NOM_food_omelette_crab"] = this.TYPE.food,
    ["NOM_food_pie_appl"] = this.TYPE.food,
    ["NOM_food_pie_comb"] = this.TYPE.food,
    ["NOM_food_rat_pie"] = this.TYPE.food,
    ["NOM_food_salted_fish"] = this.TYPE.food,
    ["NOM_food_soup_onion"] = this.TYPE.food,
    ["NOM_food_soup_rat"] = this.TYPE.food,
    ["NOM_sltw_food_a_onion"] = this.TYPE.food,
    ["NOM_sltw_food_bread_corn"] = this.TYPE.food,
    ["NOM_sltw_food_cookiebig"] = this.TYPE.food,
    ["NOM_sltw_food_cookiesmall"] = this.TYPE.food,
    ["NOM_food_bread_ash"] = this.TYPE.food,
    ["NOM_food_guar_rib_grill"] = this.TYPE.food,
    ["NOM_food_jerky_guar"] = this.TYPE.food,
    ["NOM_food_torall"] = this.TYPE.food,
    ["NOM_food_rice_delight"] = this.TYPE.food,
    ["NOM_food_lard"] = this.TYPE.food,
    ["NOM_food_racer_morsel"] = this.TYPE.food,
    ["NOM_food_skewer_kag"] = this.TYPE.food,
    ["NOM_food_sausage_guar"] = this.TYPE.food,
    ["NOM_food_soup_seaweed"] = this.TYPE.food,
    ["NOM_food_sweetroll"] = this.TYPE.food,
    ["NOM_salt"] = this.TYPE.seasoning,
    ["NOM_sugar"] = this.TYPE.seasoning,
    ["NOM_yeast"] = this.TYPE.mushroom,

  --ST Alchemy
    ["ingred_daedroth_claw_SA"] = this.TYPE.misc,
    ["ingred_dunmer_bone_SA"] = this.TYPE.misc,
    ["ingred_dwemer_grease_SA"] = this.TYPE.misc,
    ["ingred_dwemer_pipe_SA"] = this.TYPE.misc,
    ["ingred_feather_SA"] = this.TYPE.misc,
    ["ingred_fishegg_ST"] = this.TYPE.egg,
    ["ingred_frostspore_ST"] = this.TYPE.misc,
    ["ingred_goldnugget_SA"] = this.TYPE.misc,
    ["ingred_hunger_tongue_SA"] = this.TYPE.meat,
    ["ingred_kelp_ST"] = this.TYPE.vegetable,
    ["ingred_kollop_meat_ST"] = this.TYPE.meat,
    ["ingred_lead_ST"] = this.TYPE.misc,
    ["ingred_lich_dust_SA"] = this.TYPE.misc,
    ["ingred_moss_ST"] = this.TYPE.misc,
    ["ingred_mycena_cap_ST"] = this.TYPE.mushroom,
    ["ingred_namira_cap_ST"] = this.TYPE.mushroom,
    ["ingred_netchjelly_ST"] = this.TYPE.misc,
    ["ingred_nocturnal_crepidotus_ST"] = this.TYPE.misc,
    ["ingred_ogrim_flesh_SA"] = this.TYPE.meat,
    ["ingred_opal_SA"] = this.TYPE.misc,
    ["ingred_salt_fish_SA"] = this.TYPE.meat,
    ["ingred_sapphire_SA"] = this.TYPE.misc,
    ["ingred_silvernugget_ST"] = this.TYPE.misc,
    ["ingred_spidersilk_ST"] = this.TYPE.misc,
    ["ingred_wolf_jaw_ST"] = this.TYPE.misc,
    ["ingred_wolf_meat_SA"] = this.TYPE.meat,
    ["ingred_wolf_ribs_SA"] = this.TYPE.misc,
    ["TM_honeycomb"] = this.TYPE.food,

    --Morrowind Crafting (alchemy)
    ["mc_ashyam_baked"] = this.TYPE.food,--"Baked Ash Yam"
    ["mc_berry_pie"] = this.TYPE.food,--"Mixed Berry Pie"
    ["mc_potluckstew"] = this.TYPE.food,--"Pot Luck Stew"
    ["mc_bubble_squeak"] = this.TYPE.food,--"Bubble and Squeak"
    ["mc_chefsalad"] = this.TYPE.food,--"Chef Salad"
    ["mc_cookie"] = this.TYPE.food,--"Gramcookie"
    ["mc_crabmeat_cooked"] = this.TYPE.cookedMeat,--"Steamed Crab"
    ["mc_durzog_cooked"] = this.TYPE.cookedMeat,--"Cooked Durzog Meat"
    ["mc_felaril"] = this.TYPE.food,--"Felaril"
    ["mc_fish_cooked"] = this.TYPE.cookedMeat,--"Grilled Slaughterfish"
    ["mc_fried_mushroom"] = this.TYPE.food,--"Fried Mushrooms"
    ["mc_glowpotsoup"] = this.TYPE.food,--"Glowpot Soup"
    ["mc_guar_cooked"] = this.TYPE.cookedMeat,--"Cooked Guar Meat"
    ["mc_kagarine"] = this.TYPE.food,--"Kagarine"
    ["mc_guarherdpie"] = this.TYPE.food,--"Guarherd Pie"
    ["mc_guarstew"] = this.TYPE.food,--"Guar Stew"
    ["mc_mushroomsoup"] = this.TYPE.food,--"Mushroom Soup"
    ["mc_plains_pie"] = this.TYPE.food,--"Plains Pie"
    ["mc_pot_pie"] = this.TYPE.food,--"Pot Pie"
    ["mc_potatosalad"] = this.TYPE.food,--"Potato Salad"
    ["mc_quiche"] = this.TYPE.food,--"Quiche"
    ["mc_racerrevenge"] = this.TYPE.food,--"Racer Revenge Soup"
    ["mc_root_soup"] = this.TYPE.food,--"Root Soup"
    ["mc_ryebread"] = this.TYPE.food,--"Rye Bread"
    ["mc_scuttle_soup"] = this.TYPE.food,--"Scuttle Soup"
    ["mc_seafood_medley"] = this.TYPE.food,--"Seafood Medley"
    ["mc_seafood_stew"] = this.TYPE.food,--"Seafood Stew"
    ["mc_spice_soup"] = this.TYPE.food,--"Spice Soup"
    ["mc_suncake"] = this.TYPE.food,--"Suncake"
    ["mc_swamproll"] = this.TYPE.food,--"Swamp Roll"
    ["mc_sweetyam_pie"] = this.TYPE.food,--"Sweet Yam Pie"
    ["mc_trailbroth"] = this.TYPE.food,--"Trail Broth"
    ["mc_wheatroll"] = this.TYPE.food,--"Wheat Roll"
    ["mc_hound_cooked"] = this.TYPE.cookedMeat,--"Cooked Hound Steak"
    ["mc_kagouti_cooked"] = this.TYPE.cookedMeat,--"Cooked Kagouti Steak"
    ["mc_kwamalarge"] = this.TYPE.food,--"Large Boiled Kwama Egg"
    ["mc_kwamasmall"] = this.TYPE.food,--"Small Boiled Kwama Egg"
    ["mc_mixedgreens"] = this.TYPE.food,--"Mixed Greens Salad"
    ["mc_potato_baked"] = this.TYPE.food,--"Baked Potato"
    ["mc_racer_cooked"] = this.TYPE.food,--"Cooked Cliff Racer Breast"
    ["mc_ricetreat"] = this.TYPE.food,--"Saltrice Crispy Treat"
    ["mc_rat_cooked"] = this.TYPE.food,--"Cooked Rat Steak"
    ["mc_sweetbread"] = this.TYPE.food,--"Sweetbread"
    ["mc_sweetcake"] = this.TYPE.food,--"Sweetcake"
    ["mc_trailcake"] = this.TYPE.food,--"Trailcake"
    ["mc_ricebread"] = this.TYPE.food,--"Rice Bread"
    ["mc_wheatbread"] = this.TYPE.food,--"Wheat Bread"
    ["mc_sow_milk"] = this.TYPE.food,--"Bottle of Sow's Milk"
}





return this