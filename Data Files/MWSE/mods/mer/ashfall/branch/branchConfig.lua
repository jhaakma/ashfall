local this = {}

local daysToRefresh = 3
this.hoursToRefresh = 24 * daysToRefresh
this.minBranchesPerTree = 0
this.maxBranchesPerTree = 2
this.minDistanceFromTree = 100
this.maxDistanceFromTree = 350
this.maxSteepness = 0.7
--sort branches into general groups
this.branchGroups = {
    azurasCoast = {
        "ashfall_branch_ac_01",
        "ashfall_branch_ac_02",
        "ashfall_branch_ac_03",
    },
    ascadianIsles = {
        "ashfall_branch_ai_01",
        "ashfall_branch_ai_02",
        "ashfall_branch_ai_03",
    },
    ashlands = {
        "ashfall_branch_ash_01",
        "ashfall_branch_ash_02",
        "ashfall_branch_ash_03",
    },
    bitterCoast = {
        "ashfall_branch_bc_01",
        "ashfall_branch_bc_02",
        "ashfall_branch_bc_03",
    },
    grazelands = {
        "ashfall_branch_gl_01",
        "ashfall_branch_gl_02",
        "ashfall_branch_gl_03",
    },
    westGash = {
        "ashfall_branch_wg_01",
        "ashfall_branch_wg_02",
        "ashfall_branch_wg_03",
    },
}

--Ids for various fallen branches
this.branchIds = {}
for _, ids in pairs(this.branchGroups) do
    for _, id in ipairs(ids) do
        this.branchIds[id] = true
    end
end

this.defaultBranchGroup = this.branchGroups.ascadianIsles
--assign regions to branch groups
this.branchRegions = {
    --solsthiem
    ['moesring mountains region'] = this.branchGroups.solstheim,
    ['felsaad coast region'] = this.branchGroups.solstheim,
    ['isinfier plains region'] = this.branchGroups.solstheim,
    ['brodir grove region'] = this.branchGroups.solstheim,
    ['thirsk region'] = this.branchGroups.solstheim,
    ['hirstaang forest region'] = this.branchGroups.solstheim,
    --Vvardenfell
    ['sheogorad'] = this.branchGroups.azurasCoast,

    ["Azura's Coast Region"] = this.branchGroups.azurasCoast,
    ['ascadian isles region'] = this.branchGroups.ascadianIsles,
    ['grazelands region'] = this.branchGroups.grazelands,
    ['bitter coast region'] = this.branchGroups.bitterCoast,
    ['west gash region'] = this.branchGroups.westGash,
    ['ashlands region'] = this.branchGroups.ashlands,
    ['molag mar region'] = this.branchGroups.ashlands,
    ['red mountain region'] = this.branchGroups.ashlands,
}

this.textureMapping = {
    ['tx_bark_01'] = this.branchGroups.azurasCoast,
    ['textures\\tx_mushroom_01'] = this.branchGroups.azurasCoast,
    ['textures\\tx_mushroom_02'] = this.branchGroups.azurasCoast,

    ['tx_bark_02'] = this.branchGroups.ascadianIsles,

    ['tx_bc_bark_02'] = this.branchGroups.bitterCoast,

    ['textures\\tx_ashtree_bark_01'] = this.branchGroups.ashlands,
    ['textures\\tx_ashtree_bark_02'] = this.branchGroups.ashlands,
    ['textures\\tx_ashtree_bark_03'] = this.branchGroups.ashlands,

    ['tx_bark_06'] = this.branchGroups.grazelands,

    ['tx_bark_04'] = this.branchGroups.westGash,
    ['tx_bark_05'] = this.branchGroups.westGash
}

this.patternMapping = {
    _ac_ = this.branchGroups.azurasCoast,
    _ai_ = this.branchGroups.ascadianIsles,
    _bc_ = this.branchGroups.bitterCoast,
    _al_ = this.branchGroups.ashlands,
    _gl_ = this.branchGroups.grazelands,
    _wg_ = this.branchGroups.westGash,
}

this.idMapping = {}

return this