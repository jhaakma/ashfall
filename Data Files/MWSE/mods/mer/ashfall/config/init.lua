local this = {}
this.configPath = "ashfall"
this.defaultConfig = require ("mer.ashfall.MCM.defaultConfig")
local inMemConfig = mwse.loadConfig(this.configPath, this.defaultConfig)

---@class Ashfall.Config : Ashfall.MCMConfig
---@field showHints boolean
---@field checkForUpdates boolean
---@field doIntro boolean
---@field manualTimeScale number
---@field overrideTimeScale boolean
---@field overrideFood boolean
---@field logLevel string
---@field devFeatures boolean
---@field debugMode boolean
---@field blocked table
---@field rayTestUpdateMilliseconds number
---@field campingMerchants table<string, boolean>
---@field foodWaterMerchants table<string, boolean>
---@field waterBaseCost number
---@field stewBaseCost number
---@field enableTemperatureEffects boolean
---@field enableHunger boolean
---@field enableThirst boolean
---@field enableTiredness boolean
---@field enableSickness boolean
---@field enableBlight boolean
---@field enableDiseasedMeat boolean
---@field enableEnvironmentSickness boolean
---@field enableSkinning boolean
---@field enableBranchPlacement boolean
---@field enableCooking boolean
---@field bushcraftingEnabled boolean
---@field showTemp boolean
---@field showHunger boolean
---@field showThirst boolean
---@field showTiredness boolean
---@field showWetness boolean
---@field showSickness boolean
---@field startingEquipment boolean
---@field modifierHotKey table
---@field needsCanKill boolean
---@field showFrostBreath boolean
---@field illegalHarvest boolean
---@field canCampInSettlements boolean
---@field canCampIndoors boolean
---@field canRestOnGround boolean
---@field showBackpacks boolean
---@field atronachRecoverMagickaDrinking boolean
---@field potionsHydrate boolean
---@field seeThroughTents boolean
---@field disableHarvested boolean
---@field naturalMaterialsMultiplier number
---@field globalColdEffect number
---@field globalWarmEffect number
---@field hungerRate number
---@field thirstRate number
---@field loseSleepRate number
---@field loseSleepWaiting number
---@field gainSleepRate number
---@field gainSleepBed number
---@field restingNeedsMultiplier number
---@field travelingNeedsMultiplier number
---@field warmthValues table
this.config = setmetatable({
    save = function()
        mwse.saveConfig(this.configPath, inMemConfig)
    end
}, {
    __index = function(_, key)
        return inMemConfig[key]
    end,
    __newindex = function(_, key, value)
        inMemConfig[key] = value
    end,
})

return this