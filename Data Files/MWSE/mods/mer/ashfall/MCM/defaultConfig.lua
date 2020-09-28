
return {
    --intro setup
    doIntro = true, 
    manualTimeScale = 20,
    overrideTimeScale = false,
    overrideFood = false,

    logLevel = "INFO",
    blocked = {},
    campingMerchants = {
        ["arrille"] = true,--seyda neen trader
        ["ra'virr"] = true,--balmora trader
        ["mebestian ence"] = true,--pelagiad trader
        ["alveno andules"] = true,--vivec pawnbroker
        ["goldyn belaram"] = true,--suran pawnbroker
        ["irgola"] = true,--caldera pawnbroker
        ["clagius clanler"] = true,--balmora outfitter
        ["fadase selvayn"] = true,--tel branora trader
        ["tiras sadus"] = true,--ald'ruhn trader
        ["heifnir"] = true,--dagon fel trader
        ["ancola"] = true,--sadrith mora trader
        ["ababael timsar-dadisun"] = true,--super pro ashlander merchant
        ["shulki ashunbabi"] = true,--Gnisis trader
        ["perien aurelie"] = true, --hla-oad pawnbroker
        ["thongar"] = true,--khuul trader/fake inkeeper
        ["vasesius viciulus"] = true,--molag mar trader
        ["baissa"] = true,--vivec foreign quarter trader
        ["sedam omalen"] = true,--ald velothi's only trader
    },
    foodWaterMerchants = {
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
    enableTemperatureEffects = true,
    enableHunger = true,
    enableThirst = true,
    enableTiredness = true,
    enableSickness = true,
    enableBlightness = true,
    enableDiseasedMeat = true,
    enableEnvironmentSickness = true,

    enableCooking = false,--depreciated

    showTemp = true,
    showHunger = true,
    showThirst = true,
    showTiredness = true,
    showWetness = false,
    showSickness = true,

    startingEquipment = false,
    modifierHotKey = {
        keyCode = tes3.scanCode.lShift
    },
    enableBranchPlacement = true,
    needsCanKill = false,
    showFrostBreath = true,
    illegalHarvest = true,

    hungerRate = 20,
    thirstRate = 30,
    loseSleepRate = 50,
    loseSleepWaiting = 30,
    gainSleepRate = 30,
    gainSleepBed = 60,
}