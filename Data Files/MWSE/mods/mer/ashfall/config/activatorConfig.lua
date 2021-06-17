local Activator = require("mer.ashfall.objects.Activator")
local this = {}

this.types = {
    waterSource = "waterSource",
    dirtyWaterSource = "dirtyWaterSource",
    cookingUtensil = "cookingUtensil",
    fire = "fire",
    campfire = "campfire",
    woodSource = "woodSource",
    vegetation = "vegetation",
    branch = "branch",
    cauldron = "cauldron",
    cushion = "cushion",
}

this.list = {}
this.list.waterDirty = Activator:new{ 
    name = "Water (Dirty)", 
    type = this.types.dirtyWaterSource,
    mcmSetting = "enableThirst",
    ids = {
        ["ex_vivec_waterfall_01"] = true,
        ["ex_vivec_waterfall_03"] = true,
        ["ex_vivec_waterfall_05"] = true,
        ["ex_vivec_p_water"] = true,
        ["in_om_waterfall"] = true,
        ["in_om_waterfall_small"] = true,
        ["tr_m3_oe_plaza_water_"] = true,
        -- TR
        ["t_glb_terrwatersew_waterfall_01"] = true,
        ["t_glb_terrwatersew_waterfall_02"] = true,
        ["t_glb_terrwatersew_waterfall_03"] = true,
        ["t_glb_terrwater_circle1024_01"] = true,
        ["t_glb_terrwater_circle128_01"] = true,
        ["t_glb_terrwater_circle2048_01"] = true,
        ["t_glb_terrwater_circle256_01"] = true,
        ["t_glb_terrwater_circle512_01"] = true,
        ["t_glb_terrwater_circle64_01"] = true,
        ["t_glb_terrwater_curveflw256_01"] = true,
        ["t_glb_terrwater_curveflw256s_01"] = true,
        ["t_glb_terrwater_curveflw512_01"] = true,
        ["t_glb_terrwater_curveflw512s_01"] = true,
        ["t_glb_terrwater_curverpd256_01"] = true,
        ["t_glb_terrwater_curverpd256s_01"] = true,
        ["t_glb_terrwater_curverpd512_01"] = true,
        ["t_glb_terrwater_curverpd512s_01"] = true,
        ["t_glb_terrwater_rectflw256_01"] = true,
        ["t_glb_terrwater_rectflw256_02"] = true,
        ["t_glb_terrwater_rectflw256_03"] = true,
        ["t_glb_terrwater_rectrpd256_01"] = true,
        ["t_glb_terrwater_rectrpd256_02"] = true,
        ["t_glb_terrwater_rectrpd256_03"] = true,
        ["t_glb_terrwater_rectstill256_01"] = true,
        ["t_glb_terrwater_rectstill256_02"] = true,
        ["t_glb_terrwater_rectstill256_03"] = true,
        ["t_glb_terrwater_sqrflw1024_01"] = true,
        ["t_glb_terrwater_sqrflw256_01"] = true,
        ["t_glb_terrwater_sqrflw512_01"] = true,
        ["t_glb_terrwater_sqrstill1024_01"] = true,
        ["t_glb_terrwater_sqrstill256_01"] = true,
        ["t_glb_terrwater_sqrstill512_01"] = true,
        ["t_com_set_waterwheel_01"] = true,
        ["t_de_sethla_x_watercbnarsis_01"] = true,
        ["t_de_sethla_x_waternarsis_01"] = true,
        ["t_de_sethla_x_waternarsis_0"] = true,
        ["t_de_sethla_x_waternarsis_03"] = true,
        --Wolli
        ["terrwater_circle"] = true,
    }
}
this.list.water = this.list.waterDirty
this.list.waterClean = Activator:new{ 
    name = "Water", 
    type = this.types.waterSource,
    mcmSetting = nil,
    ids = {
        ["t_com_var_barrelwater_01"] = true,
    }
}
this.list.basin = Activator:new{
    name = "Basin",
    type = this.types.waterSource,
    mcmSetting = nil,
    ids = {
        ["act_basin_telv_wood"] = true --UL
    }
}
this.list.waterJug = Activator:new{
    name = "Water Jug",
    type = this.types.waterSource,
    mcmSetting = nil,
    ids = {
        ["a_water_jug"] = true --Yurts
    }
}
this.list.well = Activator:new{ 
    name = "Well", 
    type = this.types.waterSource,
    mcmSetting = nil,
    ids = {
        ["mr_hlaalu_well_01"] = true,
        ["ex_nord_well_01"] = true,
        ["ex_nord_well_01a"] = true,
        ["furn_well00"] = true,
        ["rm_well"] = true,
        ["t_de_setveloth_x_well"] = true,

        ["act_bm_well_01"] = true,

        -- nom
        ["nom_ac_pool"] = true,
        ["nom_ashland_pool"] = true,
        ["nom_basin"] = true,
        ["nom_bc_pool00"] = true,
        ["nom_bc_pool01"] = true,
        ["nom_mh_spuot"] = true,
        ["nom_midevil_well"] = true,
        ["nom_pump_dunmer"] = true,
        ["nom_pump_dwemer"] = true,
        ["nom_pump_imperial"] = true,
        ["nom_source_ac"] = true,
        ["nom_source_bc"] = true,
        ["nom_source_eraben"] = true,
        ["nom_source_mh"] = true,
        ["nom_source_strong02"] = true,
        ["nom_source_strong03"] = true,
        ["nom_source_urshilaku"] = true,
        ["nom_source_zainab"] = true,
        ["nom_strong02_pool"] = true,
        ["nom_strong03_pool"] = true,
        ["nom_water_barrel"] = true,
        ["nom_water_round"] = true,
        ["nom_water_round_ani"] = true,
        ["nom_water_spray"] = true,
        ["nom_water_spray_fab"] = true,
        ["nom_well_common_01"] = true,
        ["nom_well_mh_01"] = true,
        ["nom_well_nord_01"] = true,
        ["nom_well_nord_colony1"] = true,
        ["nomni_ex_hlaalu_well"] = true,
        ["nomni_ex_redoran_well"] = true,
        ["nomni_ex_t_wellpod"] = true,
        ["nomni_well_common_strong1"] = true,

        -- tr
        ["tr_m3_oe_plaza_water_uni"] = true,
        ["t_de_sethla_x_well_01"] = true,
        ["t_de_setind_x_well_01"] = true,
        ["t_de_setveloth_x_well_01"] = true,

        --rebirth
        ["mr_hlaalu_fountain"] = true,
        ["mr_redoran_well"] = true,

        --well diversified
        ["_ex_hlaalu_well"] = true,
        ["izi_hlaalu_well"] = true,
        ["ex_imp_well_01"] = true,
        ["ex_s_well_01"] = true,
        ["bw_ex_hlaalu_well"] = true,
        ["rp_wooden_well"] = true,

        --MD
        ["ab_ex_velwellfountain"] = true,

        --OAAB
        ["mr_imp_well"] = true,
    } 
}
this.list.keg = Activator:new{ 
    name = "Keg", 
    type = this.types.waterSource,
    mcmSetting = nil,
    ids = {
        ["ashfall_kegstand_00"] = true,
        ["kegstand"] = true,
        ["furn_com_kegstand"] = true,
        ["furn_de_kegstand"] = true,
        ["nom_kegstand_emp_de"] = true,
        ["nom_kegstand_emp"] = true,
    },
    owned = true,
}
this.list.vegetation = Activator:new{
    name = "Vegetation",
    type = this.types.vegetation,
    mcmSetting = "enableBushcrafting",
    patterns = {
        ["_grass_"] = true,
        ["_bush_"] = true,
        ["_kelp_"] = true,
        ["_fern_"] = true
    }
}
this.list.tree = Activator:new{ 
    name = "Tree",
    type = this.types.woodSource,
    mcmSetting = nil,
    patterns = {
        ["flora_ash_log"] = true,
        ["flora_ashtree"] = true,
        ["flora_bc_knee"] = true,
        ["flora_bc_log"] = true,
        ["flora_bc_tree"] = true,
        ["flora_bm_log"] = true,
        ["flora_bm_snow_log"] = true,
        ["flora_bm_snowstump"] = true,
        ["flora_bm_treestump"] = true,
        ["flora_emp_parasol"] = true,
        ["flora_root_wg"] = true,
        ["flora_tree"] = true,
        ["vurt_baobab"] = true,
        ["vurt_bctree"] = true,
        ["vurt_bentpalm"] = true,
        ["vurt_decstree"] = true,
        ["vurt_neentree"] = true,
        ["vurt_palm"] = true,
        ["vurt_unicy"] = true,
        ["floraat_tree_"] = true,
        ['flora_t_mushroom'] = true,
        ["pine_tree"] = true,--vsw
        ["mr_flora_graze_tree "] = true, --Rebirth
        ["floraat_tree"] = true, --TR
        ['florabw_tree'] = true, --TR
        ['florach_tree'] = true, --TR
        ['floragc_tree'] = true, --TR    
        ['floragh_tree'] = true, --TR
        ['florahl_tree'] = true, --TR
        ['florajm_tree'] = true, --TR
        ['florakp_tree'] = true, --TR
        ['florakstr_tree'] = true, --TR
        ['floravm_tree'] = true, --TR
        ['floraww_tree'] = true, --TR
        
    },
}
this.list.wood = Activator:new{ 
    name = "Wood",
    type = this.types.woodSource,
    mcmSetting = nil,
    patterns = {
        ["flora_ashtree"] = true,
        ["flora_ash_log"] = true,
        ["flora_bc_knee"] = true,
        ["flora_bc_log"] = true,
        ["flora_bc_tree"] = true,
        ["flora_bm_log"] = true,
        ["flora_bm_snow_log"] = true,
        ["flora_bm_snowstump"] = true,
        ["flora_bm_treestump"] = true,
        ["flora_emp_parasol"] = true,
        ["flora_root_wg"] = true,
        ["flora_tree"] = true,
        ["vurt_baobab"] = true,
        ["vurt_bctree"] = true,
        ["vurt_bentpalm"] = true,
        ["vurt_decstree"] = true,
        ["vurt_neentree"] = true,
        ["vurt_palm"] = true,
        ["vurt_unicy"] = true,
        --["furn_log"] = true
    }
}
this.list.fire = Activator:new{ 
    name = "Fire", 
    type = this.types.fire,
    mcmSetting = "enableCooking",
    patterns = {
        ["firepit_f"] = true,
        ["firepit_lit"] = true,
        ["firepit_roaring"] = true,
        --["light_pitfire"] = true,
        ["light_logpile"] = true
    }
}

this.list.campfire = Activator:new{
    name = "Campfire", 
    type = this.types.campfire,
    mcmSetting = nil,
    ids = {
        ["ashfall_campfire"] = true,
        ["ashfall_campfire_static"] = true,
        ["ashfall_campfire_sup"] = true,
        ["ashfall_campfire_grill"] = true,
    },
    hasMenu = true,
    grillMinHeight = 21,
    grillMaxHeight = 50,
    grillDistance = 40
}

this.list.cushion = Activator:new{
    name = "Cushion",
    type = this.types.cushion,
    mcmSetting = nil,
    ids = {
        furn_de_cushion_round_01 = { height = 20 },
        furn_de_cushion_round_02 = { height = 20 },
        furn_de_cushion_round_03 = { height = 20 },
        furn_de_cushion_round_04 = { height = 20 },
        furn_de_cushion_round_05 = { height = 20 },
        furn_de_cushion_round_06 = { height = 20 },
        furn_de_cushion_round_07 = { height = 20 },
        furn_de_cushion_square_01 = { height = 10 },
        furn_de_cushion_square_02 = { height = 10 },
        furn_de_cushion_square_03 = { height = 10 },
        furn_de_cushion_square_04 = { height = 10 },
        furn_de_cushion_square_05 = { height = 10 },
        furn_de_cushion_square_06 = { height = 10 },
        furn_de_cushion_square_07 = { height = 10 },
        furn_de_cushion_square_08 = { height = 10 },
        furn_de_cushion_square_09 = { height = 10 },
    },
}

this.list.cauldron = Activator:new{
    name = "Cauldron",
    type = this.types.cauldron,
    mcmSetting = nil,
    ids = {
        ["furn_com_cauldron_02"] = true
    },
    isStewer = true
}

-- this.list.branch = Activator:new{
--     name = "Branch",
--     type = this.types.branch,
--     mcmSetting = nil,
--     ids = {
--         "ashfall_branch"
--     }
-- }

event.register("Ashfall:PrintActivatorIds", function(e)
    local activator = this.list[e.activator]
    mwse.log("printing ids for %s", e.activator)
    for id, _ in pairs(activator.ids) do
        mwse.log(id)
    end
end)

return this