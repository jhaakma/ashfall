local ashfall = include("mer.ashfall.interop")
if ashfall then
    ashfall.registerActivators {
        SP_Bm_Flora_TreePineS_01 = "tree",
        SP_Bm_Flora_TreePineS_02 = "tree",
        SP_Bm_Flora_TreePineS_03 = "tree",
        SP_Bm_Flora_TreePineS_04 = "tree",
        SP_Bm_Flora_TreePineS_05 = "tree",
        SP_Bm_Flora_TreePineS_06 = "tree",
        SP_Bm_Flora_TreePineS_07 = "tree",
        SP_Bm_Flora_TreePineG_01 = "tree",
        SP_Bm_Flora_TreePineG_02 = "tree",
        SP_Bm_Flora_TreePineG_03 = "tree",
        SP_Bm_Flora_TreePineG_04 = "tree",
        SP_Bm_Flora_TreePineG_05 = "tree",
        SP_Bm_Flora_TreePineG_06 = "tree",
        SP_Bm_Flora_TreePineG_07 = "tree",
        SP_Bm_Flora_TreePineH_01 = "tree",
        SP_Bm_Flora_TreePineH_02 = "tree",
        SP_Bm_Flora_TreePineH_03 = "tree",
        SP_Bm_Flora_TreePineH_04 = "tree",
        SP_Bm_Flora_TreePineH_05 = "tree",
        SP_Bm_Flora_TreePineH_06 = "tree",
        SP_Bm_Flora_TreePineH_07 = "tree",
        SP_flora_bm_log_03F = "wood",
        SP_flora_bm_log_01F = "wood"
        }
    ashfall.registerHeatSources {
    SP_Nor_SetSkaal_I_Fireplace_01 = 100,
    SP_Bm_Colony_I_Fireplace_01 = 100
    }
    ashfall.registerClimates {
    ["Sea of Ghosts Region"] = 'polar'
    }
end