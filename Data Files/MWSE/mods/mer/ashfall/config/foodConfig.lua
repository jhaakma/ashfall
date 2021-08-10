local this = {}

this.cookedMulti = 2.0
this.burntMulti = 0.8

function this.getFoodType(obj)
    local foodType =  this.ingredTypes[obj.id:lower()]
    -- if not foodType and obj.objectType == tes3.objectType.ingredient then
    --     foodType = this.type.misc
    -- end
    return foodType
end



--Handles special case for pre-cooked meat
function this.getFoodTypeResolveMeat(obj)

    local foodType = this.getFoodType(obj)
    if foodType == this.type.cookedMeat then
        foodType = this.type.meat
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
    if foodType == this.type.cookedMeat then
        foodType = this.type.meat
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

function this.addFood(id, foodType)
    this.ingredTypes[id:lower()] = this.type[foodType]
end

this.type = {
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
    [this.type.meat] = { 
        notSoup = true,
        stewNutrition = 1.0,
        min = 10, max = 30, 
        id = "ashfall_stew_hearty",
        tooltip = "A hearty meat stew that fortifies your health.",
        ingredTooltip = "Adds Fortify Health buff."
    }, -- fortify health
    [this.type.vegetable] = { 
        notSoup = true,
        stewNutrition = 0.9,
        min = 10, max = 30, 
        id = "ashfall_stew_nutritious",
        tooltip = "A nutritious vegetable stew that fortifies your fatigue.",
        ingredTooltip = "Adds Fortify Fatigue buff"
    }, --fortify fatigue
    [this.type.mushroom] = { 
        notSoup = true,
        stewNutrition = 0.8,
        min = 10, max = 25, 
        id = "ashfall_stew_chunky",
        tooltip = "A chunky mushroom stew that fortifies your magicka.",
        ingredTooltip = "Adds Fortify Magicka buff."
    }, --fortify magicka
    [this.type.seasoning] = { 
        notSoup = false,
        stewNutrition = 0.3,
        min = 5, max = 20, 
        id = "ashfall_stew_tasty",
        tooltip = "A tasty seasoned soup that fortifies your agility.",
        ingredTooltip = "Adds Fortify Agility buff."
    }, --fortify agility
    [this.type.herb] = { 
        notSoup = false,
        stewNutrition = 0.4,
        min = 5, max = 20, 
        id = "ashfall_stew_aromatic",
        tooltip = "An aromatic soup, rich in herbs,that fortifies your personality.",
        ingredTooltip = "Adds Fortify Personality buff."
        } -- fortify personality
}

--min: fully cooked multi at lowest cooking skill
--max fully cooked multi at highest cooking skill
this.grillValues = {
    [this.type.meat] = { min = 1.5, max = 1.7 },
    [this.type.egg] = { min = 1.5, max = 1.7 },
    [this.type.vegetable] = { min = 1.3, max = 1.5 },
    [this.type.mushroom] = { min = 1.2, max = 1.4 },
}

--Nutrition at weight==1.0
this.nutrition = {
    [this.type.meat] = 12,
    [this.type.cookedMeat] = (12 * this.grillValues[this.type.meat].min), 
    [this.type.egg] = 10,
    [this.type.vegetable] = 14,
    [this.type.mushroom] = 13,
    [this.type.seasoning] = 8,
    [this.type.herb] = 10,
    [this.type.food] = 30,
    --[this.type.misc] = 0,
}

this.ingredTypes = {
    ["ingred_human_meat_01"] = this.type.meat,
    ["ingred_adamantium_ore_01"] = this.type.misc,
    ["ingred_alit_hide_01"] = this.type.misc,
    ["ingred_bc_ampoule_pod"] = this.type.misc,
    ["ingred_ash_salts_01"] = this.type.seasoning,
    ["ingred_ash_yam_01"] = this.type.vegetable,
    ["ingred_bear_pelt"] = this.type.misc,
    ["ingred_bittergreen_petals_01"] = this.type.herb,
    ["ingred_black_anther_01"] = this.type.herb,
    ["ingred_black_lichen_01"] = this.type.misc,
    ["ingred_bloat_01"] = this.type.misc,
    ["ingred_blood_innocent_unique"] = this.type.misc,
    ["ingred_bonemeal_01"] = this.type.misc,
    ["ingred_bread_01"] = this.type.food,
    ["ingred_bread_01_uni2"] = this.type.food,
    ["ingred_boar_leather"] = this.type.misc,
    ["ingred_bc_bungler's_bane"] = this.type.mushroom,
    ["ingred_chokeweed_01"] = this.type.herb,
    ["ingred_bc_coda_flower"] = this.type.herb,
    ["ingred_comberry_01"] = this.type.herb,
    ["ingred_corkbulb_root_01"] = this.type.vegetable,
    ["ingred_corprus_weepings_01"] = this.type.misc,
    ["ingred_crab_meat_01"] = this.type.meat,
    ["ingred_daedra_skin_01"] = this.type.misc,
    ["ingred_cursed_daedras_heart_01"] = this.type.misc,
    ["ingred_daedras_heart_01"] = this.type.misc,
    ["ingred_dae_cursed_diamond_01"] = this.type.misc,
    ["ingred_diamond_01"] = this.type.misc,
    ["ingred_dreugh_wax_01"] = this.type.misc,
    ["ingred_durzog_meat_01"] = this.type.meat,
    ["ingred_ectoplasm_01"] = this.type.misc,
    ["ingred_dae_cursed_emerald_01"] = this.type.misc,
    ["ingred_emerald_01"] = this.type.misc,
    ["ingred_fire_petal_01"] = this.type.herb,
    ["ingred_fire_salts_01"] = this.type.seasoning,
    ["ingred_eyeball_unique"] = this.type.misc,
    ["ingred_frost_salts_01"] = this.type.seasoning,
    ["ingred_ghoul_heart_01"] = this.type.misc,
    ["ingred_guar_hide_girith"] = this.type.misc,
    ["ingred_gold_kanet_01"] = this.type.herb,
    ["ingred_golden_sedge_01"] = this.type.herb,
    ["ingred_eyeball"] = this.type.misc,
    ["ingred_gravedust_01"] = this.type.misc,
    ["ingred_gravetar_01"] = this.type.misc,
    ["ingred_green_lichen_01"] = this.type.misc,
    ["ingred_guar_hide_01"] = this.type.misc,
    ["ingred_hackle-lo_leaf_01"] = this.type.herb,
    ["ingred_innocent_heart"] = this.type.misc,
    ["ingred_udyrfrykte_heart"] = this.type.misc,
    ["ingred_wolf_heart"] = this.type.meat,
    ["ingred_heartwood_01"] = this.type.misc,
    ["ingred_heather_01"] = this.type.herb,
    ["ingred_holly_01"] = this.type.herb,
    ["ingred_horker_tusk_01"] = this.type.misc,
    ["ingred_horn_lily_bulb_01"] = this.type.vegetable,
    ["ingred_hound_meat_01"] = this.type.meat,
    ["ingred_bc_hypha_facia"] = this.type.mushroom,
    ["ingred_kagouti_hide_01"] = this.type.misc,
    ["ingred_kresh_fiber_01"] = this.type.herb,
    ["ingred_kwama_cuttle_01"] = this.type.meat,
    ["ingred_6th_corprusmeat_05"] = this.type.meat,
    ["food_kwama_egg_02"] = this.type.egg,
    ["ingred_6th_corprusmeat_01"] = this.type.meat,
    ["ingred_lloramor_spines_01"] = this.type.herb,
    ["ingred_russula_01"] = this.type.mushroom,
    ["ingred_marshmerrow_01"] = this.type.vegetable,
    ["ingred_guar_hide_marsus"] = this.type.misc,
    ["ingred_meadow_rye_01"] = this.type.herb,
    ["ingred_6th_corprusmeat_06"] = this.type.meat,
    ["ingred_6th_corprusmeat_03"] = this.type.meat,
    ["ingred_scrib_jelly_02"] = this.type.meat,
    ["ingred_moon_sugar_01"] = this.type.misc,
    ["ingred_muck_01"] = this.type.misc,
    ["ingred_bread_01_uni3"] = this.type.food,
    ["ingred_netch_leather_01"] = this.type.misc,
    ["ingred_nirthfly_stalks_01"] = this.type.herb,
    ["ingred_noble_sedge_01"] = this.type.herb,
    ["ingred_dae_cursed_pearl_01"] = this.type.misc,
    ["ingred_pearl_01"] = this.type.misc,
    ["ingred_emerald_pinetear"] = this.type.misc,
    ["poison_goop00"] = this.type.misc,
    ["ingred_racer_plumes_01"] = this.type.misc,
    ["ingred_rat_meat_01"] = this.type.meat,
    ["ingred_dae_cursed_raw_ebony_01"] = this.type.misc,
    ["ingred_raw_ebony_01"] = this.type.misc,
    ["ingred_raw_glass_01"] = this.type.misc,
    ["ingred_raw_glass_tinos"] = this.type.misc,
    ["ingred_raw_stalhrim_01"] = this.type.misc,
    ["ingred_red_lichen_01"] = this.type.misc,
    ["ingred_resin_01"] = this.type.misc,
    ["ingred_belladonna_01"] = this.type.herb,
    ["ingred_gold_kanet_unique"] = this.type.herb,
    ["ingred_roobrush_01"] = this.type.herb,
    ["ingred_dae_cursed_ruby_01"] = this.type.misc,
    ["ingred_ruby_01"] = this.type.misc,
    ["ingred_saltrice_01"] = this.type.vegetable,
    ["ingred_scales_01"] = this.type.misc,
    ["ingred_scamp_skin_01"] = this.type.misc,
    ["ingred_scathecraw_01"] = this.type.herb,
    ["ingred_scrap_metal_01"] = this.type.misc,
    ["ingred_scrib_cabbage_01"] = this.type.vegetable,
    ["ingred_scrib_jelly_01"] = this.type.meat,
    ["ingred_scrib_jerky_01"] = this.type.food,
    ["ingred_scuttle_01"] = this.type.food,
    ["ingred_shalk_resin_01"] = this.type.misc,
    ["ingred_sload_soap_01"] = this.type.misc,
    ["ingred_6th_corprusmeat_07"] = this.type.meat,
    ["food_kwama_egg_01"] = this.type.egg,
    ["ingred_6th_corprusmeat_02"] = this.type.meat,
    ["ingred_snowbear_pelt_unique"] = this.type.misc,
    ["ingred_snowwolf_pelt_unique"] = this.type.misc,
    ["ingred_bc_spore_pod"] = this.type.herb,
    ["ingred_stoneflower_petals_01"] = this.type.herb,
    ["ingred_sweetpulp_01"] = this.type.herb,
    ["ingred_timsa-come-by_01"] = this.type.herb,
    ["ingred_trama_root_01"] = this.type.vegetable,
    ["ingred_treated_bittergreen_uniq"] = this.type.herb,
    ["ingred_belladonna_02"] = this.type.herb,
    ["ingred_vampire_dust_01"] = this.type.misc,
    ["ingred_coprinus_01"] = this.type.mushroom,
    ["ingred_void_salts_01"] = this.type.seasoning,
    ["ingred_wickwheat_01"] = this.type.herb,
    ["ingred_willow_anther_01"] = this.type.herb,
    ["ingred_wolf_pelt"] = this.type.misc,
    ["ingred_wolfsbane_01"] = this.type.misc,
    ["ingred_6th_corprusmeat_04"] = this.type.meat,

    --tr meats

    ["t_ingfood_apple_01"] = this.type.food,
    ["t_ingfood_appleskyrim_01"] = this.type.food,
    ["t_ingfood_blackberry_01"] = this.type.food,
    ["t_ingfood_breadcolovian_01"] = this.type.food,
    ["t_ingfood_breadcolovian_02"] = this.type.food,
    ["t_ingfood_breadcolovianmw_01"] = this.type.food,
    ["t_ingfood_breadcolovianmw_02"] = this.type.food,
    ["t_ingfood_breaddeshaan_01"] = this.type.food,
    ["t_ingfood_breaddeshaan_02"] = this.type.food,
    ["t_ingfood_breaddeshaan_03"] = this.type.food,
    ["t_ingfood_breaddeshaan_04"] = this.type.food,
    ["t_ingfood_breaddeshaan_05"] = this.type.food,
    ["t_ingfood_breadflat_01"] = this.type.food,
    ["t_ingfood_breadflat_02"] = this.type.food,
    ["t_ingfood_breadflat_03"] = this.type.food,
    ["t_ingfood_carrot_01"] = this.type.vegetable,
    ["t_ingfood_cheesecolovian_01"] = this.type.food,
    ["t_ingfood_cheesenord_01"] = this.type.food,
    ["t_ingfood_cheesewheelnord_01"] = this.type.food,
    ["t_ingfood_cheesewheelnord_02"] = this.type.food,
    ["t_ingfood_cloudycorn_01"] = this.type.food,
    ["t_ingfood_cookie_01"] = this.type.food,
    ["t_ingfood_cookie_02"] = this.type.food,
    ["t_ingfood_eggchicken_01"] = this.type.egg,
    ["t_ingfood_eggmolecrab_01"] = this.type.egg,
    ["t_ingfood_eggornada_01"] = this.type.egg,
    ["t_ingfood_fig_01"] = this.type.food,
    ["t_ingfood_fig_dried_01"] = this.type.food,
    ["t_ingfood_fishbrowntrout_01"] = this.type.meat,
    ["t_ingfood_fishchrysophant_01"] = this.type.meat,
    ["t_ingfood_fishcod_01"] = this.type.meat,
    ["t_ingfood_fishcoddried_01"] = this.type.food,
    ["t_ingfood_fishleapertail_01"] = this.type.meat,
    ["t_ingfood_fishlongfinfilet_01"] = this.type.cookedmeat,
    ["t_ingfood_fishpike_01"] = this.type.meat,
    ["t_ingfood_fishpikeperch_01"] = this.type.meat,
    ["t_ingfood_fishsalmon_01"] = this.type.meat,
    ["t_ingfood_fishslaughterdried_01"] = this.type.food,
    ["t_ingfood_fishslaughterdried_02"] = this.type.food,
    ["t_ingfood_fishslaughterdried_03"] = this.type.food,
    ["t_ingfood_fishspr_01"] = this.type.meat,
    ["t_ingfood_fishstrid_01"] = this.type.meat,
    ["t_ingfood_flour_01"] = this.type.food,
    ["t_ingfood_garlic_01"] = this.type.food,
    ["t_ingfood_grape_01"] = this.type.food,
    ["t_ingfood_grape_02"] = this.type.food,
    ["t_ingfood_grapewrothgarian_01"] = this.type.food,
    ["t_ingfood_honey_01"] = this.type.food,
    ["t_ingfood_indureta_01"] = this.type.food,
    ["t_ingfood_ironrye_01"] = this.type.food,
    ["t_ingfood_leek_01"] = this.type.herb,
    ["t_ingfood_lyco_01"] = this.type.food,
    ["t_ingfood_meatalit_01"] = this.type.meat,
    ["t_ingfood_meatbeef_01"] = this.type.meat,
    ["t_ingfood_meatboar_01"] = this.type.meat,
    ["t_ingfood_meatboar_02"] = this.type.meat,
    ["t_ingfood_meatboarroast_02"] = this.type.cookedmeat,
    ["t_ingfood_meatchicken_01"] = this.type.meat,
    ["t_ingfood_meatchickenroast_01"] = this.type.cookedmeat,
    ["t_ingfood_meatcliffracer_01"] = this.type.meat,
    ["t_ingfood_meatdurzog_01"] = this.type.cookedmeat,
    ["t_ingfood_meatguar_01"] = this.type.meat,
    ["t_ingfood_meatham_01"] = this.type.meat,
    ["t_ingfood_meathorker_01"] = this.type.meat,
    ["t_ingfood_meatkagouti_01"] = this.type.meat,
    ["t_ingfood_meatkwama_01"] = this.type.meat,
    ["t_ingfood_meatmutton_01"] = this.type.meat,
    ["t_ingfood_meatnixhoundroast_01"] = this.type.cookedmeat,
    ["t_ingfood_meatornada_01"] = this.type.meat,
    ["t_ingfood_meatparastylus_01"] = this.type.meat,
    ["t_ingfood_meatrat_01"] = this.type.cookedmeat,
    ["t_ingfood_meatratroast_01"] = this.type.cookedmeat,
    ["t_ingfood_meatvenison_01"] = this.type.meat,
    ["t_ingfood_meatvenisonroast_01"] = this.type.cookedmeat,
    ["t_ingfood_olives_01"] = this.type.food,
    ["t_ingfood_onion_01"] = this.type.food,
    ["t_ingfood_poppadgourd_01"] = this.type.food,
    ["t_ingfood_potato_01"] = this.type.vegetable,
    ["t_ingfood_radish_01"] = this.type.food,
    ["t_ingfood_rice_01"] = this.type.food,
    ["t_ingfood_scribpie_01"] = this.type.food,
    ["t_ingfood_silverpalmfruit_01"] = this.type.food,
    ["t_ingfood_snowberry_01"] = this.type.food,
    ["t_ingfood_strawberry_01"] = this.type.food,
    ["t_ingfood_sweetroll_01"] = this.type.food,
    ["t_ingfood_tomato_01"] = this.type.vegetable,
    ["t_ingfood_trinityfruit_01"] = this.type.food,
    ["t_ingfood_wasabipowder_01"] = this.type.food,
    ["t_ingfood_wasabiroot_01"] = this.type.food,
    ["t_ingfood_wheat_01"] = this.type.food,

    --cannibals
    
    ["mor_redguard_heart"] = this.type.meat,
    ["mor_redguard_flesh"] = this.type.meat,
    ["mor_redguard_eye"] = this.type.meat,
    ["mor_redguard_brain"] = this.type.meat,
    ["mor_orc_heart"] = this.type.meat,
    ["mor_orc_flesh"] = this.type.meat,
    ["mor_orc_eye"] = this.type.meat,
    ["mor_orc_brain"] = this.type.meat,
    ["mor_nord_heart"] = this.type.meat,
    ["mor_nord_flesh"] = this.type.meat,
    ["mor_nord_brain"] = this.type.meat,
    ["mor_nord_bones"] = this.type.misc,
    ["mor_khajiit_heart"] = this.type.meat,
    ["mor_khajiit_flesh"] = this.type.meat,
    ["mor_khajiit_eye"] = this.type.meat,
    ["mor_khajiit_ear"] = this.type.meat,
    ["mor_khajiit_brain"] = this.type.meat,
    ["mor_intestine"] = this.type.meat,
    ["mor_imperial_tongue"] = this.type.meat,
    ["mor_imperial_heart"] = this.type.meat,
    ["mor_imperial_flesh"] = this.type.meat,
    ["mor_imperial_eye"] = this.type.meat,
    ["mor_imperial_brain"] = this.type.meat,
    ["mor_dunmer_heart"] = this.type.meat,
    ["mor_dunmer_flesh"] = this.type.meat,
    ["mor_dunmer_eye"] = this.type.meat,
    ["mor_dunmer_brain"] = this.type.meat,
    ["mor_breton_heart"] = this.type.meat,
    ["mor_breton_flesh"] = this.type.meat,
    ["mor_breton_eye"] = this.type.meat,
    ["mor_breton_brain"] = this.type.meat,
    ["mor_bosmer_heart"] = this.type.misc,
    ["mor_bosmer_flesh"] = this.type.meat,
    ["mor_bosmer_eye"] = this.type.meat,
    ["mor_bosmer_brain"] = this.type.meat,
    ["mor_argo_tail"] = this.type.meat,
    ["mor_argo_heart"] = this.type.meat,
    ["mor_argo_flesh"] = this.type.meat,
    ["mor_argo_eye"] = this.type.meat,
    ["mor_arg_brain"] = this.type.meat,
    ["mor_altmer_heart"] = this.type.meat,
    ["mor_altmer_flesh"] = this.type.meat,
    ["mor_altmer_brain"] = this.type.meat,
    ["mor_altmer_eye"] = this.type.meat,    
    
    --pl creatures
    
    ["plx_wasp_sting"] = this.type.misc,
    ["plx_vissed_meat"] = this.type.meat,
    ["plx_squirrel_tail"] = this.type.misc,
    ["plx_slarsa_meat"] = this.type.meat,
    ["plx_scorp_sting"] = this.type.misc,
    ["plx_rhurlymn_meat"] = this.type.meat,
    ["plx_rat_meat_d"] = this.type.misc,
    ["plx_rat_meat_b"] = this.type.misc,
    ["plx_raptor_meat"] = this.type.meat,
    ["plx_rabbit_foot"] = this.type.misc,
    ["plx_netch_jelly"] = this.type.misc,
    ["plx_moose_antlers"] = this.type.misc,
    ["plx_kagouti_meat_b"] = this.type.misc,
    ["plx_kagouti_meat"] = this.type.meat,
    ["plx_ingred_spidersilk"] = this.type.misc,
    ["plx_ingred_shell_shalk"] = this.type.misc,
    ["plx_ingred_shell_scrib"] = this.type.misc,
    ["plx_ingred_shell_scarab"] = this.type.misc,
    ["plx_ingred_shell_para"] = this.type.misc,
    ["plx_ingred_shell_beetle4"] = this.type.misc,
    ["plx_ingred_shell_beetle3"] = this.type.misc,
    ["plx_ingred_shell_beetle2"] = this.type.misc,
    ["plx_ingred_shell_beetle1"] = this.type.misc,
    ["plx_ingred_paraflesh"] = this.type.meat,
    ["plx_ingred_kriin_hide"] = this.type.misc,
    ["plx_ingred_kriin_flesh"] = this.type.meat,
    ["plx_ingred_hellhound"] = this.type.meat,
    ["plx_ingred_daedricbat"] = this.type.misc,
    ["plx_imp_glands"] = this.type.misc,
    ["plx_hound_meat_d"] = this.type.misc,
    ["plx_hound_meat_b"] = this.type.misc,
    ["plx_guar_meat"] = this.type.meat,
    ["plx_grom"] = this.type.misc,
    ["plx_gargoyle_grains"] = this.type.misc,
    ["plx_crab_meat_d"] = this.type.misc,
    ["plx_butterfly_wing"] = this.type.misc,
    ["plx_butterfly2_wing"] = this.type.misc,
    ["plx_alit_meat_d"] = this.type.misc,
    ["plx_alit_meat_b"] = this.type.misc,
    ["plx_alit_meat"] = this.type.meat,

    
    --abot's water life and birds
    
    ["ab01ingred_bee"] = this.type.misc,
    ["ab01ingred_bird_meat"] = this.type.meat,
    ["ab01ingred_bird_plumes"] = this.type.misc,
    ["ab01ingred_butt01wing"] = this.type.misc,
    ["ab01ingred_butt02wing"] = this.type.misc,
    ["ab01ingred_butt03wing"] = this.type.misc,
    ["ab01ingred_butt04wing"] = this.type.misc,
    ["ab01ingred_chiton01"] = this.type.misc,
    ["ab01ingred_chiton02"] = this.type.misc,
    ["ab01ingred_chiton03"] = this.type.misc,
    ["ab01ingred_chiton04"] = this.type.misc,
    ["ab01ingred_chiton05"] = this.type.misc,
    ["ab01ingred_chiton06"] = this.type.misc,
    ["ab01ingred_chiton07"] = this.type.misc,
    ["ab01ingred_chiton08"] = this.type.misc,
    ["ab01ingred_chiton09"] = this.type.misc,
    ["ab01ingred_chiton10"] = this.type.misc,
    ["ab01ingred_coral01"] = this.type.misc,
    ["ab01ingred_coral02"] = this.type.misc,
    ["ab01ingred_coral03"] = this.type.misc,
    ["ab01ingred_coral04"] = this.type.misc,
    ["ab01ingred_coral05"] = this.type.misc,
    ["ab01ingred_coral06"] = this.type.misc,
    ["ab01ingred_coral07"] = this.type.misc,
    ["ab01ingred_coral08"] = this.type.misc,
    ["ab01ingred_coral09"] = this.type.misc,
    ["ab01ingred_egg02"] = this.type.egg,
    ["ab01ingred_egggold"] = this.type.egg,
    ["ab01ingred_firefly"] = this.type.misc,
    ["ab01ingred_greymatter"] = this.type.misc,
    ["ab01ingred_grom"] = this.type.misc,
    ["ab01ingred_jellyfish"] = this.type.misc,
    ["ab01ingred_manateefin"] = this.type.misc,
    ["ab01ingred_octopus"] = this.type.misc,
    ["ab01ingred_penguinfin"] = this.type.misc,
    ["ab01ingred_sandcoin01"] = this.type.misc,
    ["ab01ingred_sandcoin02"] = this.type.misc,
    ["ab01ingred_sandcoin03"] = this.type.misc,
    ["ab01ingred_sandcoin04"] = this.type.misc,
    ["ab01ingred_sandcoin05"] = this.type.misc,
    ["ab01ingred_sandcoin06"] = this.type.misc,
    ["ab01ingred_sandcoin07"] = this.type.misc,
    ["ab01ingred_sandcoin08"] = this.type.misc,
    ["ab01ingred_seahorse"] = this.type.misc,
    ["ab01ingred_sealblubber"] = this.type.misc,
    ["ab01ingred_seastar01"] = this.type.meat,
    ["ab01ingred_seastar02"] = this.type.meat,
    ["ab01ingred_seastar03"] = this.type.meat,
    ["ab01ingred_seastar05"] = this.type.meat,
    ["ab01ingred_seastar06"] = this.type.meat,
    ["ab01ingred_seastar07"] = this.type.meat,
    ["ab01ingred_sharkjaws"] = this.type.misc,
    ["ab01ingred_sharktooth"] = this.type.misc,
    ["ab01ingred_shell01"] = this.type.misc,
    ["ab01ingred_shell02"] = this.type.misc,
    ["ab01ingred_shell03"] = this.type.misc,
    ["ab01ingred_shell04"] = this.type.misc,
    ["ab01ingred_shell05"] = this.type.misc,
    ["ab01ingred_shell06"] = this.type.misc,
    ["ab01ingred_shell07"] = this.type.misc,
    ["ab01ingred_snailgoo"] = this.type.misc,
    ["ab01ingred_snailgoop"] = this.type.misc,
    ["ab01ingred_spermwhaletooth"] = this.type.misc,
    ["ab01ingred_turtlemeat"] = this.type.meat,
    ["db_vegi_batfur"] = this.type.misc,
    ["db_vegi_batwing"] = this.type.misc,
    ["fka_feathers"] = this.type.misc,
    ["ll_ingr_sponge1"] = this.type.misc,
    ["ll_ingr_sponge2"] = this.type.misc,
    ["ll_ingr_sponge3"] = this.type.misc,
    ["ndib_ingred_pearl_black"] = this.type.misc,
    ["nom_food_fish"] = this.type.meat,
    ["nom_food_fish_fat_01"] = this.type.meat,
    ["nom_food_fish_fat_02"] = this.type.meat,
    ["nom_food_meat"] = this.type.meat,
    ["ab01ingred_barnacles01"] = this.type.misc,
    ["ab01ingred_alga05"] = this.type.herb,
    ["ab01ingred_alga04"] = this.type.herb,
    ["ab01ingred_alga03"] = this.type.herb,
    ["ab01ingred_alga02"] = this.type.herb,
    ["ab01ingred_alga01"] = this.type.herb,

    
    --danae's cliff racers
    ["mc_racer_raw"] = this.type.meat,
    
    --my custom

    ["mer_ingfood_fish"] = this.type.meat,
    
    --tr
    ["t_ingspice_saffron_01"] = this.type.seasoning,
    ["t_ingspice_pepper_01"] = this.type.seasoning,
    ["t_ingspice_nigella_01"] = this.type.seasoning,    
    ["t_ingspice_muscat_01"] = this.type.seasoning,
    ["t_ingspice_hibiscus_01"] = this.type.herb,
    ["t_ingspice_curcuma_01"] = this.type.seasoning,
    ["t_ingspice_cardamon_01"] = this.type.seasoning,
    ["t_ingspice_anise_01"] = this.type.seasoning,
    ["t_ingfood_meathorse_01"] = this.type.meat,
    ["t_ingfood_meatarenthjerky_01"]= this.type.food,
    ["t_ingfood_gooseb01"] = this.type.food,
    ["t_ingfood_eggseagull_01"] = this.type.egg,
    ["t_ingfood_bridethornberry_01"] = this.type.food,
    ["t_ingflor_summerbolete_01"] = this.type.mushroom,
    ["t_ingflor_rustrussula_01"] = this.type.mushroom,
    ["t_ingflor_primrose_01"] = this.type.herb,
    ["t_ingflor_lavender_01"] = this.type.herb,
    ["t_ingflor_kingbolete_01"] = this.type.mushroom,
    ["t_ingflor_ginseng_01"] = this.type.herb,
    ["t_ingflor_chokeberry_01"] = this.type.herb,
    ["t_ingflor_cairnbolete_01"] = this.type.mushroom,
    ["t_ingflor_cabbage_02"] = this.type.vegetable,
    ["t_ingflor_cabbage_01"] = this.type.vegetable,
    ["t_ingflor_aspyrtea_01"] = this.type.herb,
    ["t_ingflor_templedome_01"] = this.type.mushroom,
    ["t_ingflor_bluefoot_01"] = this.type.mushroom,

    --nom (ul)
    ["nom_food_a_apple"] = this.type.food,
    ["nom_food_a_lemon"] = this.type.food,
    ["nom_food_ash_yam"] = this.type.food,
    ["nom_food_bittergreen"] = this.type.food,
    ["nom_food_boiled_rice"] = this.type.food,
    ["nom_food_boiled_rice2"] = this.type.food,
    ["nom_food_cabbage"] = this.type.food,
    ["nom_food_corkbulb_roast"] = this.type.food,
    ["nom_food_crab_slice"] = this.type.food,
    ["nom_food_egg2"] = this.type.egg,
    ["nom_food_fruit_salad"] = this.type.food,
    ["nom_food_grilled_fish"] = this.type.food,
    ["nom_food_hackle-lo"] = this.type.food,
    ["nom_food_lemon_fish"] = this.type.food,
    ["nom_food_marshmerrow"] = this.type.food,
    ["nom_food_meat_grilled2"] = this.type.food,
    ["nom_food_moon_pudding"] = this.type.food,
    ["nom_food_omelette"] = this.type.food,
    ["nom_food_omelette_crab"] = this.type.food,
    ["nom_food_pie_appl"] = this.type.food,
    ["nom_food_pie_comb"] = this.type.food,
    ["nom_food_rat_pie"] = this.type.food,
    ["nom_food_salted_fish"] = this.type.food,
    ["nom_food_soup_onion"] = this.type.food,
    ["nom_food_soup_rat"] = this.type.food,
    ["nom_sltw_food_a_onion"] = this.type.food,
    ["nom_sltw_food_bread_corn"] = this.type.food,
    ["nom_sltw_food_cookiebig"] = this.type.food,
    ["nom_sltw_food_cookiesmall"] = this.type.food,
    ["nom_food_bread_ash"] = this.type.food,
    ["nom_food_guar_rib_grill"] = this.type.food,
    ["nom_food_jerky_guar"] = this.type.food,
    ["nom_food_torall"] = this.type.food,
    ["nom_food_rice_delight"] = this.type.food,
    ["nom_food_lard"] = this.type.food,
    ["nom_food_racer_morsel"] = this.type.food,
    ["nom_food_skewer_kag"] = this.type.food,
    ["nom_food_sausage_guar"] = this.type.food,
    ["nom_food_soup_seaweed"] = this.type.food,
    ["nom_food_sweetroll"] = this.type.food,
    ["nom_salt"] = this.type.seasoning,
    ["nom_sugar"] = this.type.seasoning,
    ["nom_yeast"] = this.type.mushroom,

  --st alchemy
    ["ingred_daedroth_claw_sa"] = this.type.misc,
    ["ingred_dunmer_bone_sa"] = this.type.misc,
    ["ingred_dwemer_grease_sa"] = this.type.misc,
    ["ingred_dwemer_pipe_sa"] = this.type.misc,
    ["ingred_feather_sa"] = this.type.misc,
    ["ingred_fishegg_st"] = this.type.egg,
    ["ingred_frostspore_st"] = this.type.misc,
    ["ingred_goldnugget_sa"] = this.type.misc,
    ["ingred_hunger_tongue_sa"] = this.type.meat,
    ["ingred_kelp_st"] = this.type.vegetable,
    ["ingred_kollop_meat_st"] = this.type.meat,
    ["ingred_lead_st"] = this.type.misc,
    ["ingred_lich_dust_sa"] = this.type.misc,
    ["ingred_moss_st"] = this.type.misc,
    ["ingred_mycena_cap_st"] = this.type.mushroom,
    ["ingred_namira_cap_st"] = this.type.mushroom,
    ["ingred_netchjelly_st"] = this.type.misc,
    ["ingred_nocturnal_crepidotus_st"] = this.type.misc,
    ["ingred_ogrim_flesh_sa"] = this.type.meat,
    ["ingred_opal_sa"] = this.type.misc,
    ["ingred_salt_fish_sa"] = this.type.meat,
    ["ingred_sapphire_sa"] = this.type.misc,
    ["ingred_silvernugget_st"] = this.type.misc,
    ["ingred_spidersilk_st"] = this.type.misc,
    ["ingred_wolf_jaw_st"] = this.type.misc,
    ["ingred_wolf_meat_sa"] = this.type.meat,
    ["ingred_wolf_ribs_sa"] = this.type.meat,
    ["tm_honeycomb"] = this.type.food,
    ["ingred_bear_meat_sa"] = this.type.meat,

    --morrowind crafting (alchemy)
    ["mc_ashyam_baked"] = this.type.food,--"baked ash yam"
    ["mc_berry_pie"] = this.type.food,--"mixed berry pie"
    ["mc_potluckstew"] = this.type.food,--"pot luck stew"
    ["mc_bubble_squeak"] = this.type.food,--"bubble and squeak"
    ["mc_chefsalad"] = this.type.food,--"chef salad"
    ["mc_cookie"] = this.type.food,--"gramcookie"
    ["mc_crabmeat_cooked"] = this.type.cookedmeat,--"steamed crab"
    ["mc_durzog_cooked"] = this.type.cookedmeat,--"cooked durzog meat"
    ["mc_felaril"] = this.type.food,--"felaril"
    ["mc_fish_cooked"] = this.type.cookedmeat,--"grilled slaughterfish"
    ["mc_fried_mushroom"] = this.type.food,--"fried mushrooms"
    ["mc_glowpotsoup"] = this.type.food,--"glowpot soup"
    ["mc_guar_cooked"] = this.type.cookedmeat,--"cooked guar meat"
    ["mc_kagarine"] = this.type.food,--"kagarine"
    ["mc_guarherdpie"] = this.type.food,--"guarherd pie"
    ["mc_guarstew"] = this.type.food,--"guar stew"
    ["mc_mushroomsoup"] = this.type.food,--"mushroom soup"
    ["mc_plains_pie"] = this.type.food,--"plains pie"
    ["mc_pot_pie"] = this.type.food,--"pot pie"
    ["mc_potatosalad"] = this.type.food,--"potato salad"
    ["mc_quiche"] = this.type.food,--"quiche"
    ["mc_racerrevenge"] = this.type.food,--"racer revenge soup"
    ["mc_root_soup"] = this.type.food,--"root soup"
    ["mc_ryebread"] = this.type.food,--"rye bread"
    ["mc_scuttle_soup"] = this.type.food,--"scuttle soup"
    ["mc_seafood_medley"] = this.type.food,--"seafood medley"
    ["mc_seafood_stew"] = this.type.food,--"seafood stew"
    ["mc_spice_soup"] = this.type.food,--"spice soup"
    ["mc_suncake"] = this.type.food,--"suncake"
    ["mc_swamproll"] = this.type.food,--"swamp roll"
    ["mc_sweetyam_pie"] = this.type.food,--"sweet yam pie"
    ["mc_trailbroth"] = this.type.food,--"trail broth"
    ["mc_wheatroll"] = this.type.food,--"wheat roll"
    ["mc_hound_cooked"] = this.type.cookedmeat,--"cooked hound steak"
    ["mc_kagouti_cooked"] = this.type.cookedmeat,--"cooked kagouti steak"
    ["mc_kwamalarge"] = this.type.food,--"large boiled kwama egg"
    ["mc_kwamasmall"] = this.type.food,--"small boiled kwama egg"
    ["mc_mixedgreens"] = this.type.food,--"mixed greens salad"
    ["mc_potato_baked"] = this.type.food,--"baked potato"
    ["mc_racer_cooked"] = this.type.food,--"cooked cliff racer breast"
    ["mc_ricetreat"] = this.type.food,--"saltrice crispy treat"
    ["mc_rat_cooked"] = this.type.food,--"cooked rat steak"
    ["mc_sweetbread"] = this.type.food,--"sweetbread"
    ["mc_sweetcake"] = this.type.food,--"sweetcake"
    ["mc_trailcake"] = this.type.food,--"trailcake"
    ["mc_ricebread"] = this.type.food,--"rice bread"
    ["mc_wheatbread"] = this.type.food,--"wheat bread"
    ["mc_sow_milk"] = this.type.food,--"bottle of sow's milk"

    --morrowind crafting - raw ingredients
    ["mc_onion"] = this.type.vegetable,--"raw onion"
    ["mc_garlic"] = this.type.seasoning,--"raw garlic"
    ["mc_potato_raw"] = this.type.vegetable,--"raw potato"
    ["mc_fish_raw"] = this.type.meat,--"raw slaughterfish filet"
    ["mc_kagouti_raw"] = this.type.meat,--"raw kagouti"
    ["mc_fish_bladder"] = this.type.meat,--"slaughterfish bladder"
    ["mc_sausagepod"] = this.type.mushroom,--"sausagepod"
    ["mc_sugar"] = this.type.seasoning,--"sugar"
    ["mc_kanet_butter"] = this.type.seasoning,--"kanet butter",

    --Morrowind Jobs
    ["jobcookedashyam"] = this.type.food,
    ["jobcookedbittergreenpetals"] = this.type.food,
    ["jobcookedcrabmeat"] = this.type.cookedMeat,
    ["jobcookeddurzogmeat"] = this.type.cookedMeat,
    ["jobcookedhackleloleaf"] = this.type.food,
    ["jobcookedhoundmeat"] = this.type.cookedMeat,
    ["jobcookedlargekwamaegg"] = this.type.food,
    ["jobcookedmarshmerrow"] = this.type.food,
    ["jobcookedratmeat"] = this.type.cookedMeat,
    ["jobcookedsaltrice"] = this.type.food,
    ["jobcookedscales"] = this.type.food,
    ["jobcookedsmallkwamaegg"] = this.type.food,
    ["jobsalt"] = this.type.seasoning,
    ["jobssashyamsoup"] = this.type.food,
    ["jobssbittergreensoup"] = this.type.food,
    ["jobssgoblinstew"] = this.type.food,
    ["jobsshackleloleafsoup"] = this.type.food,
    ["jobsshoundstew"] = this.type.food,
    ["jobssmarshmerrowsoup"] = this.type.food,
    ["jobssratstew"] = this.type.food,
    ["jobssvegetablesoup"] = this.type.food,
    ["jobslaughterfishsmallfood"] = this.type.meat,
    ["jobslaughterfishfood"] = this.type.meat,

    --OAAB
    ["ab_ingcrea_guarmeat_01"] = this.type.meat,
    ["ab_ingcrea_horsemeat01"] = this.type.foomeatd,
    ["ab_ingcrea_sfmeat_01"] = this.type.meat,
    ["ab_ingflor_bloodgrass_01"] = this.type.herb,
    ["ab_ingflor_bloodgrass_02"] = this.type.herb,
    ["ab_ingflor_bluekanet_01"] = this.type.herb,
    ["ab_ingflor_dustcap"] = this.type.mushroom,
    ["ab_ingflor_fomentarius"] = this.type.mushroom,
    ["ab_ingflor_glmuscaria_01"] = this.type.mushroom,
    ["ab_ingflor_urnula"] = this.type.mushroom,
    ["ab_ingflor_vimuscaria_01"] = this.type.mushroom,
    ["ab_ingfood_kwamaeggcentcut"] = this.type.food,
    ["ab_ingfood_kwamaeggcentwrap"] = this.type.food,
    ["ab_ingfood_kwamaloaf"] = this.type.food,
    ["ab_ingfood_saltricebread"] = this.type.food,
    ["ab_ingfood_saltriceporridge"] = this.type.food,
    ["ab_ingfood_scuttlepie"] = this.type.food,
    ["ab_ingfood_sweetroll"] = this.type.food,

    --Food of Tamriel
    ["1foodbreadslice"] = this.type.food,
    ["1foodcliffracerwing"] = this.type.food,
    ["1foodguarjerky"] = this.type.food,
    ["1foodomlet"] = this.type.food,
    ["1foodscrib"] = this.type.food,
    ["1foodscribleg"] = this.type.food,
    ["1mushroomfood"] = this.type.food,
    ["1pumkinfood"] = this.type.food,
    ["2foodpeach"] = this.type.food,
    ["Cakefood1"] = this.type.food,
    ["cakefood2"] = this.type.food,
    ["cheese3"] = this.type.food,
    ["Cherry1"] = this.type.food,
    ["chickenbreastfood1"] = this.type.food,
    ["cornfood1"] = this.type.food,
    ["lemon1"] = this.type.food,

    --Children of Morrowind
    ["1em_apple"] = this.type.food,
    ["1em_apple2"] = this.type.food,
    ["1em_candybag1"] = this.type.food,
    ["1em_child_candy1"] = this.type.food,
    ["1em_child_candy2"] = this.type.food,
    ["1em_child_candy3"] = this.type.food,
    ["1em_child_candy4"] = this.type.food,
    ["1em_chocrat"] = this.type.food,
    ["1em_combegg"] = this.type.food,
    ["1em_fruitdrop"] = this.type.food,
    ["1em_lollipop1a"] = this.type.food,
    ["1em_lollipop2a"] = this.type.food,
    ["1em_lollipop3a"] = this.type.food,
    ["1em_lollipop4a"] = this.type.food,

    --other
    ["ingred_kollop_meat_01"] = this.type.meat,

    --Rebirth
    ["mr_berries"] = this.type.herb,
    ["mr_crab_pudding"] = this.type.food,
    ["mr_guar_meat"] = this.type.meat,
    ["mr_guar_sausage"] = this.type.cookedMeat,
    ["mr_kwama_egg_blight"] = this.type.egg,
    ["mr_marshmerrow_boiled"] = this.type.food,
    ["mr_nether_salt"] = this.type.seasoning,
    ["mr_sweetroll"] = this.type.food,
    ["mr_wind_salt"] = this.type.seasoning,
}

return this