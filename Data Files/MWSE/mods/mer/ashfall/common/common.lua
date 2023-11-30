--Common
---@class Ashfall.Common
local this = {}
this.staticConfigs = require("mer.ashfall.config.staticConfigs")
this.helper = require("mer.ashfall.common.helperFunctions")
this.defaultValues = require ("mer.ashfall.MCM.defaultConfig")
this.messages = require("mer.ashfall.messages.messages")
local config = require("mer.ashfall.config").config
--set up logger
local logger = require("logging.logger")
---@type mwseLogger
this.log = logger.new{
    name = "Ashfall",
    --outputFile = "Ashfall.log",
    logLevel = config.logLevel,
}
this.loggers = {this.log}
this.createLogger = function(serviceName)
    local logger = logger.new{
        name = string.format("Ashfall - %s", serviceName),
        logLevel = config.logLevel,
        includeTimestamp = true,
    }
    table.insert(this.loggers, logger)
    return logger
end
this.helper.logger = this.createLogger("Helper")

--[[
    Skills
]]
---@type table<string, SkillsModule.Skill>
this.skills = {}

local function initData()
    tes3.player.data.Ashfall = tes3.player.data.Ashfall or {}
    tes3.player.data.Ashfall.currentStates = tes3.player.data.Ashfall.currentStates or {}
    tes3.player.data.Ashfall.wateredCells = tes3.player.data.Ashfall.wateredCells or {}
    tes3.player.data.Ashfall.trinketEffects = tes3.player.data.Ashfall.trinketEffects or {}
    tes3.player.data.Ashfall.backpacks = tes3.player.data.Ashfall.backpacks or {}
    tes3.player.data.Ashfall.sacks = tes3.player.data.Ashfall.sacks or {}
end

---@class Ashfall.playerData
---@field temp number
---@field baseTemp number
---@field tempLimit number
---@field sunTemp number
---@field weatherTemp number
---@field fireTemp number
---@field currentStates table<string, Ashfall.Condition> A list of the current condition states
---@field wateredCells table<string, boolean> A list of cells that have been watered
---@field trinketEffects table
---@field insideTent boolean
---@field insideCoveredBedroll boolean
---@field hasTentCover boolean
---@field tentTempMulti number
---@field globalColdEffect number
---@field globalWarmEffect number
---@field isSleeping boolean
---@field isWaiting boolean
---@field recoveringFatigue boolean
---@field cellBranchList table<string, boolean>
---@field teaDrank string
---@field teaBuffTimeLeft number
---@field lastTeaBuffUpdated number
---@field stewWarmEffect number
---@field blockForFade boolean
---@field mealTime number
---@field mealBuff number
---@field blockNeeds boolean
---@field blockHunger boolean
---@field blockThirst boolean
---@field blockSleepLoss boolean
---@field hungerEffect number
---@field thirstEffect number
---@field drinkingRain boolean
---@field drinkingWaterType string
---@field isSheltered boolean
---@field wetness number
---@field hazardTemp number
---@field sunShaded boolean
---@field nearCampfire boolean
---@field survivalEffect number
---@field lastTimeScriptsUpdated number The time in game hours at which the last update was run
---@field diedOfHunger boolean Set to true when the player is killed by hunger, to prevent the death message from showing multiple times
---@field valuesInitialised boolean Set to true when ScriptTimer updates have run at least once on this save
---@field inventorySelectTeaBrew boolean Set to true when the player is currently selecting a tea to brew
---@field backpacks table<string, boolean> a map of backpack objects which are to be registered on load
---@field sacks table<string, boolean> a map of sack objects which are to be registered as materials on load
this.data = setmetatable({}, {
    __index = function(t, key)
        if not ( tes3.player and tes3.player.data) then
            return nil
        end
        initData()
        return tes3.player.data.Ashfall[key]
    end,
    __newindex = function(t, key, value)
        if not ( tes3.player and tes3.player.data) then
            logger:error("Could not save data to player, tes3.player not available")
            return
        end
        initData()
        tes3.player.data.Ashfall[key] = value
    end
})

local function doUpgrades()
    --this.log:debug("Doing upgrades from previous version")
end

--INITIALISE COMMON--
local dataLoadedOnce = false
local function onLoaded()
    doUpgrades()
    this.log:info("Common Data loaded successfully")
    event.trigger("Ashfall:dataLoaded")
    if not dataLoadedOnce then
        dataLoadedOnce = true
        event.trigger("Ashfall:dataLoadedOnce")
    end
    --Now that the data is loaded, we need to update the food/water tiles
    tes3ui.updateInventoryTiles()
end
event.register("loaded", onLoaded)


return this
