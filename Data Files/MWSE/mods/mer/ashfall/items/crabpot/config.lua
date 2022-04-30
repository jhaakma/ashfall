local crabpotConfig = {
    maxCrabs = 3,
    --1 crab every 4 days in a non-crab cell, at minimum depth, at 0 survival skill
    crabsPerHour = (1/96),
    variance = 0.25,
    --When crabs are present, catch rate goes up to one per day
    crabCellEffect = 4.0,
    --Or two per day at max depth
    crabRateWaterEffect = 2.0,
    maxWaterDepth = 200,
    interval = 0.5,
    --At max skill, max depth, crab cell = catch 4 per day
    skillEffect = 2.0,--at 100
    skillProgress = 2,
}

crabpotConfig.miscToActiveMap = {
    ashfall_crabpot_01_m = "ashfall_crabpot_01_a",
    ashfall_crabpot_02_m = "ashfall_crabpot_02_a",
}
crabpotConfig.activeToMiscMap = {}
for misc, active in pairs(crabpotConfig.miscToActiveMap) do
    crabpotConfig.activeToMiscMap[active] = misc
end

return crabpotConfig