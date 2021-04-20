local this = {}

--Tent mappings for activating a misc item into activator
this.tentMiscToActiveMap = {
    --legacy tents
    ashfall_tent_test_misc = "ashfall_tent_test_active",
    ashfall_tent_misc = "ashfall_tent_active",
    ashfall_tent_ashl_misc = "ashfall_tent_ashl_active",
    ashfall_tent_canv_b_misc = "ashfall_tent_canv_b_active",

    --modular tents
    ashfall_tent_base_m = 'ashfall_tent_base_a',
    ashfall_tent_qual_m = 'ashfall_tent_qual_a'
    
}
this.tentActivetoMiscMap = {}
for miscId, activeId in pairs(this.tentMiscToActiveMap) do
    this.tentActivetoMiscMap[activeId] = miscId
end

this.coverToMeshMap = {
    ashfall_cov_straw = "ashfall\\tent\\cover_straw.nif",
    ashfall_cov_thatch = "ashfall\\tent\\cover_thatch.nif",
    ashfall_cov_ashl = "ashfall\\tent\\cover_ashl.nif",
}

this.trinketToMeshMap = {
    ashfall_trinket_censer = "ashfall\\tent\\trink_censer_a.nif",
    ashfall_trinket_flower = "ashfall\\tent\\trink_flower_a.nif",
    ashfall_trinket_chimes = "ashfall\\tent\\trink_chimes_a.nif",
    ashfall_trinket_tooth = "ashfall\\tent\\trink_tooth_a.nif",
}

this.tempMultis = {
    legacy = 0.70,
    uncovered = 0.85,
    ashfall_cov_straw = 0.70,
    ashfall_cov_thatch = 0.70,
    ashfall_cov_ashl = 0.70
}


return this