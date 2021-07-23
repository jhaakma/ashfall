
return {
    --intro setup
    doIntro = true, 
    manualTimeScale = 20,
    overrideTimeScale = false,
    overrideFood = false,

    --dev stuff
    logLevel = "INFO",
    devFeatures = false,
    blocked = {},

    campingMerchants = {
        ["arrille"] = true,--seyda neen trader - high elf - 800
        ["ra'virr"] = true,--balmora trader - khajiit - 600 gold
        ["mebestian ence"] = true,--pelagiad trader - Breton - 449 gold
        ["alveno andules"] = true,--vivec pawnbroker - Dark Elf - 200
        ["goldyn belaram"] = true,--suran pawnbroker - Dark Elf - 450
        ["irgola"] = true,--caldera pawnbroker - Redguard - 500
        ["clagius clanler"] = true,--balmora outfitter - Imperial - 800
        ["fadase selvayn"] = true,--tel branora trader - Dark Elf - 500
        ["tiras sadus"] = true,--ald'ruhn trader - Dark Elf - 799
        ["heifnir"] = true,--dagon fel trader - Nord - 700
        ["ancola"] = true,--sadrith mora trader - Redguard - 800
        ["ababael timsar-dadisun"] = true,--super pro ashlander merchant - Dark Elf - what 9000
        ["shulki ashunbabi"] = true,--Gnisis trader - Dark Elf - 400
        ["perien aurelie"] = true, --hla-oad pawnbroker - Breton - 150
        ["thongar"] = true,--khuul trader/fake inkeeper - Nord - 1200
        ["vasesius viciulus"] = true,--molag mar trader - Imperial - 1000
        ["baissa"] = true,--vivec foreign quarter trader - Khajiit - 100
        ["sedam omalen"] = true,--ald velothi's only trader - Dark Elf 400
    },
    foodWaterMerchants = {
        ["arrille"] = true,--seyda neen trader
        ["helviane desele"] = true,--suran madame
        ["ashumanu eraishah"] = true,--suran tradehouse
        ["fryfnhild"] = true,--dagon fel taverness
        ["thongar"] = true,--khuul trader/fake inkeeper
        ["brathus dals"] = true,--vivec hlaalu district
        ["drarayne girith"] = true,--tel aruhn plot and plaster shop
        ["selkirnemus"] = true,--molag mar Pilgrims Rest
        ["orns omaren"] = true,--molag mar St. Veloth's Hostel
        ["moroni uvelas"] = true,--Vivec St. Brewer's and Fishmongers
        ["sedam omalen"] = true,--ald velothi's only trader
    },


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
    enableBranchPlacement = true,
    enableCooking = false,--depreciated
    enableBushcrafting = false,
    
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
    showBackpacks = true,
    atronachRecoverMagickaDrinking = true,
    potionsHydrate = true,
    seeThroughTents = true,

    hungerRate = 20,
    thirstRate = 30,
    loseSleepRate = 50,
    loseSleepWaiting = 30,
    gainSleepRate = 30,
    gainSleepBed = 60,

    warmthValues = {
        armor = {},
        clothing = {}
    },
}