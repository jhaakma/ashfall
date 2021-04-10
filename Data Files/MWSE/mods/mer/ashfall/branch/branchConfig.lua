local this = {}

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
    ['moesring mountains region'] = branchGroups.solstheim,
    ['felsaad coast region'] = branchGroups.solstheim,
    ['isinfier plains region'] = branchGroups.solstheim,
    ['brodir grove region'] = branchGroups.solstheim,
    ['thirsk region'] = branchGroups.solstheim,
    ['hirstaang forest region'] = branchGroups.solstheim,
    --Vvardenfell
    ['sheogorad'] = branchGroups.azurasCoast,

    ["Azura's Coast Region"] = branchGroups.azurasCoast,
    ['ascadian isles region'] = branchGroups.ascadianIsles,
    ['grazelands region'] = branchGroups.grazelands,
    ['bitter coast region'] = branchGroups.bitterCoast,
    ['west gash region'] = branchGroups.westGash,
    ['ashlands region'] = branchGroups.ashlands,
    ['molag mar region'] = branchGroups.ashlands,
    ['red mountain region'] = branchGroups.ashlands,
}

this.textureMapping = {
    ['tx_bark_01'] = branchGroups.azurasCoast,
    ['textures\\tx_mushroom_01'] = branchGroups.azurasCoast,
    ['textures\\tx_mushroom_02'] = branchGroups.azurasCoast,

    ['tx_bark_02'] = branchGroups.ascadianIsles,

    ['tx_bc_bark_02'] = branchGroups.bitterCoast,

    ['textures\\tx_ashtree_bark_01'] = branchGroups.ashlands,
    ['textures\\tx_ashtree_bark_02'] = branchGroups.ashlands,
    ['textures\\tx_ashtree_bark_03'] = branchGroups.ashlands,

    ['tx_bark_06'] = branchGroups.grazelands,

    ['tx_bark_04'] = branchGroups.westGash,
    ['tx_bark_05'] = branchGroups.westGash
}

this.idMapping = {
    _ac_ = branchGroups.azurasCoast,
    _ai_ = branchGroups.ascadianIsles,
    _bc_ = branchGroups.bitterCoast,
    _al_ = branchGroups.ashlands,
    _gl_ = branchGroups.grazelands,
    _wg_ = branchGroups.westGash,
}

return this