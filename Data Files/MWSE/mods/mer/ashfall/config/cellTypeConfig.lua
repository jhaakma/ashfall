local this = {}

--[[interiorTempValues = {
    default = -10,
    sewer = -20,
    eggmine = -30,
    ruin = -35,
    dungeon = -40,
    cave = -45,
    tomb = -50,
    barrow = -65
}]]

this.cellTypes = {
    {
        id = "Abandoned",
        statics = {
            "in_stronghold",
            "in_strong",
            "in_strongruin",
            "in_sewer",
            "t_ayl_dngruin",
            "t_bre_dngruin",
            "t_de_dngrtrongh",
            "t_he_dngdirenni",
            "t_imp_dngruincyr",
            "t_imp_dngsewers",
            "in_om_",
        },
        patterns = {},
        temp = -20
    },
    {
        id = "Ice Caves",
        statics = {
            "bm_ic_",
            "bm_ka",
        },
        patterns = {},
        temp = -65
    },
    {
        id = "Caves",
        statics = {
            "in_moldcave",
            "in_mudcave",
            "in_lavacave",
            "in_pycave",
            "in_bonecave",
            "in_bc_cave",
            "in_m_sewer",
            "in_sewer",
            "ab_in_kwama",
            "ab_in_lava",
            "ab_in_mvcave",
            "t_cyr_cavegc",
            "t_glb_cave",
            "t_mw_cave",
            "t_sky_cave"
        },
        patterns = { " cave" },
        temp = -35
    },
    {
        id = "Daedric",
        statics = {
            "in_dae_hall",
            "in_dae_room",
            "in_dae_pillar",
            "t_dae_dngruin"
        },
        patterns = {},
        temp = -15
    },
    {
        id = "Dwemer",
        statics = {
            "in_dwrv_hall",
            "in_dwrv_corr",
            "in_dwe_corr",
            "in_dwe_archway",
            "t_dwe_dngruin",
        },
        patterns = {},
        temp = -20
    },
    {
        id = "Tomb",
        statics = {},
        patterns = {" tomb", " crypt", " catacomb" },
        temp = -45
    },
    {
        id = "Sewer",
        statics = {},
        patterns = {" sewer", " sewers" },
        temp = -20
    },
    {
        id = "Egg Mine",
        statics = {},
        patterns = {" eggmine", " egg mine" },
        temp = -30
    },
    {
        id = "Barrow",
        statics = {},
        patterns = {" barrow" },
        temp = -55
    },

}

return this