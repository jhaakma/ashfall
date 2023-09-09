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
local skillModule = include("OtherSkills.skillModule")
this.skills = {}
--INITIALISE SKILLS--
local function onSkillsReady()
    if not skillModule then
        timer.start({
            callback = function()
                tes3.messageBox({message = "Please install Skills Module", buttons = {"Okay"} })
            end,
            type = timer.simulate,
            duration = 1.0
        })

    end

    if ( skillModule.version == nil ) or ( skillModule.version < 1.4 ) then
        timer.start({
            callback = function()
                tes3.messageBox({message = string.format("Please update Skills Module"), buttons = {"Okay"} })
            end,
            type = timer.simulate,
            duration = 1.0
        })
    end

    local skills = {
        survival = {
            id = "Ashfall:Survival",
            name = "Survival",
            icon = "Icons/ashfall/survival.dds",
            value = 10,
            attribute = tes3.attribute.endurance,
            description = "The Survival skill determines your ability to deal with harsh weather conditions and perform actions such as creating campfires effectively and cooking food with them. A higher survival skill also reduces the chance of getting food poisoning or dysentery from drinking dirty water.",
            specialization = tes3.specialization.stealth
        },
        bushcrafting = {
            id = "Bushcrafting",
            name = "Bushcrafting",
            icon = "Icons/ashfall/bushcrafting.dds",
            value = 10,
            attribute = tes3.attribute.intelligence,
            description = "The Bushcrafting skill determines your ability to craft items from materials gathered in the wilderness. A higher bushcrafting skill unlocks more crafting recipes.",
            specialization = tes3.specialization.combat
        }
    }
    for skill, data in pairs(skills) do
        this.log:debug("Registering %s skill", skill)
        skillModule.registerSkill(data.id, data)
        this.skills[skill] = skillModule.getSkill(data.id)
    end
    this.log:info("Ashfall skills registered")
end
event.register("OtherSkills:Ready", onSkillsReady)


local function initData()
    tes3.player.data.Ashfall = tes3.player.data.Ashfall or {}
    tes3.player.data.Ashfall.currentStates = tes3.player.data.Ashfall.currentStates or {}
    tes3.player.data.Ashfall.wateredCells = tes3.player.data.Ashfall.wateredCells or {}
    tes3.player.data.Ashfall.trinketEffects = tes3.player.data.Ashfall.trinketEffects or {}
end

---@class Ashfall.playerData
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
---@field hungerEffect number
---@field thirstEffect number
---@field drinkingRain boolean
---@field drinkingWaterType string
---@field isSheltered boolean
---@field wetness number
---@field hazardTemp number
---@field sunShaded boolean
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
