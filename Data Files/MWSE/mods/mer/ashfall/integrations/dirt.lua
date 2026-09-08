local Dirt = require("mer.ashfall.clay.Dirt")

---@type Ashfall.DirtType.data[]
local dirtTypes = {
    {
        id = "dirt",
        name = "Dirt",
        textures = {
            "Tx_ashlands_04",
            "Tx_ashlands_06",
            "Tx_ashlands_07",
            "Tx_ashlands_08",
            "mc_dirt",
            "pc_DirtHay",
            "pc_tx_ch_dirt_01",
            "pc_tx_dm_dirt_01",
            "pc_tx_dm_dirt_02",
            "pc_tx_kp_dirt1",
            "pc_tx_kp_dirt2",
            "Tx_AC_dirt_01",
            "Tx_AC_dirt_02",
            "Tx_AI_dirt_01",
            "Tx_AI_dirtpatch_01",
            "Tx_AI_tilled_dirt_01",
            "Tx_BC_dirt",
            "tx_bm_dirt_01",
            "tx_bm_dirt_snow_01",
            "tx_bm_entrancedirt",
            "tx_dirt_carve",
            "tx_dirt_floor",
            "tx_dirt_tiled",
            "Tx_GL_dirt_01",
            "Tx_GL_dirt_02",
            "tx_ma_dirtash",
            "tx_planter_dirt",
            "tx_s_dirtfloor",
            "tx_sky_FA_dirt_01",
            "tx_sky_FA_dirt_02",
            "tx_skyrim_dirt_01",
            "tx_skyrim_dirt_02",
            "tx_skyrim_dirt_03",
            "tx_skyrim_dirt_04",
            "tx_skyrim_dirt_05",
            "tx_skyrim_dirt_06",
            "tx_skyrim_dirt_rough_01",
            "tx_skyrim_dirt_snow_01",
            "tx_skyrim_dirt_snow_04",
            "tx_skyrim_dirt_snow_05",
            "tx_skyrim_dirt_vil_sn_01",
            "tx_skyrim_dirtpatch01",
            "tx_skyrim_ham_dirt_01",
            "tx_skyrim_ham_dirt_02",
            "tx_skyrim_swampdirt",
            "Tx_WG_dirtscrub_01",
            "Tx_AC_dirtroad_01",
            "Tx_AI_dirtroad_01",
            "Tx_dirtroad_01",
            "Tx_GL_dirtroad_01",
            "Tx_WG_dirtroad_01",
        }
    },
    {
        id = "sand",
        name = "Sand",
        textures = {
            "pc_tx_gc_sand1",
            "pc_tx_gc_sand2",
            "pc_tx_gc_sand3",
            "Tx_sand_01",
            "Tx_sand_02",
        }
    },
    {
        id = "mud",
        name = "Mud",
        textures = {
            "pc_tx_dm_mud_01",
            "pc_tx_gc_mud_river",
            "Tx_AI_mudflats_01",
            "tx_bc_mud",
            "tx_sky_FA_mud_01",
            "tx_skyrim_dm_mud",
            "tx_skyrim_dm_mudice",
            "tx_skyrim_dm_mudsnow",
            "tx_skyrim_mud_01",
            "tx_skyrim_sewer_mud_01",
            "tx_coastal_rock_01",
        }
    },
}

for _, data in ipairs(dirtTypes) do
    Dirt.registerDirtType(data)
end