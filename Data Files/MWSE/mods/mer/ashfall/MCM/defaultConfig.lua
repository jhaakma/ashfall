
---@class Ashfall.MCMConfig
local mcmConfig = {
    showHints = true,
    --Check if there is a new version of the mod available
    checkForUpdates = false,
    --intro setup
    doIntro = false,
    manualTimeScale = 20,
    overrideTimeScale = true,
    overrideFood = true,
    --dev stuff
    logLevel = "INFO",
    devFeatures = false,
    debugMode = false,
    blocked = {},

    rayTestUpdateMilliseconds = 250,

    campingMerchants = {},
    foodWaterMerchants = {},


    waterBaseCost = 1,
    stewBaseCost = 8,
    enableTemperatureEffects = true,
    enableHunger = true,
    enableThirst = true,
    enableTiredness = true,
    enableSickness = true,
    enableBlight = true,
    enableDiseasedMeat = true,
    enableEnvironmentSickness = true,
    enableSkinning = true,
    enableBranchPlacement = true,
    enableCooking = false,--depreciated
    bushcraftingEnabled = true,

    showTemp = true,
    showHunger = true,
    showThirst = true,
    showTiredness = true,
    showWetness = false,
    showSickness = true,

    startingEquipment = false,

    --Misc
    modifierHotKey = {
        keyCode = tes3.scanCode.lShift
    },
    needsCanKill = false,
    showFrostBreath = true,
    illegalHarvest = true,
    canCampInSettlements = false,
    canCampIndoors = false,
    canRestOnGround = false,
    showBackpacks = true,
    atronachRecoverMagickaDrinking = true,
    potionsHydrate = true,
    seeThroughTents = true,
    disableHarvested = true,

    naturalMaterialsMultiplier = 50,
    globalColdEffect = 0,
    globalWarmEffect = 0,
    hungerRate = 20,
    thirstRate = 30,
    loseSleepRate = 50,
    loseSleepWaiting = 30,
    gainSleepRate = 30,
    gainSleepBed = 60,
    restingNeedsMultiplier = 0.5,
    travelingNeedsMultiplier = 0.5,

    warmthValues = {
        armor = {},
        clothing = {}
    },
}
return mcmConfig