--Common
local this = {}
this.config = require("mer.ashfall.config.config")
this.staticConfigs = require("mer.ashfall.config.staticConfigs")
this.helper = require("mer.ashfall.common.helperFunctions")
this.defaultValues = require ("mer.ashfall.MCM.defaultConfig")

--set up logger
local logLevel = this.config.getConfig().logLevel

this.log = require("mer.ashfall.common.logger").new{
    name = "Ashfall",
    --outputFile = "Ashfall.log",
    logLevel = logLevel
}


--Returns if an object is blocked by the MCM
function this.getIsBlocked(obj)
    local cfg = this.config.getConfig()
    local mod = obj.sourceMod and obj.sourceMod:lower()
    return (
        cfg.blocked[obj.id] or
        cfg.blocked[mod]
    )
end
--[[
    Skills
]]
local skillModule = include("OtherSkills.skillModule")
this.skills = {}
--INITIALISE SKILLS--
this.skillStartValue = 10
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

    skillModule.registerSkill(
        "Ashfall:Survival", 
        {    
            name = "Survival", 
            icon = "Icons/ashfall/survival.dds",
            value = this.skillStartValue,
            attribute = tes3.attribute.endurance,
            description = "The Survival skill determines your ability to deal with harsh weather conditions and perform actions such as creating campfires effectively and cooking food with them. A higher survival skill also reduces the chance of getting food poisoning or dysentery from drinking dirty water.",
            specialization = tes3.specialization.stealth
        }
    )

    -- skillModule.registerSkill(
    --     "Ashfall:Cooking", 
    --     {    
    --         name = "Cooking", 
    --         icon = "Icons/ashfall/cooking.dds",
    --         value = this.skillStartValue,
    --         attribute = tes3.attribute.intelligence,
    --         description = "The cooking skill determines your effectiveness at cooking meals. The higher your cooking skill, the higher the nutritional value of cooked meats and vegetables, and the stronger the buffs given by stews. A higher cooking skill also increases the time before food will burn on a grill.",
    --         specialization = tes3.specialization.magic
    --     }
    -- )

    this.skills.survival = skillModule.getSkill("Ashfall:Survival")
    --this.skills.cooking = skillModule.getSkill("Ashfall:Cooking")

    this.log:info("Ashfall skills registered")
end
event.register("OtherSkills:Ready", onSkillsReady)


--Setup local configs. 
local function initialiseLocalSettings()
    --this.log:info("initialising category %s", category.id)
    for setting, value in pairs(this.defaultValues) do
        if this.config.getConfig()[setting] == nil then
            this.config.getConfig()[setting] = value
            this.log:info( "Initialising local data %s to %s", setting, value )
        end
    end
end

--INITIALISE COMMON--
local dataLoadedOnce = false
local function onLoaded()
    if not skillModule then
        this.helper.messageBox({
            message = "Skills Module is not installed! This is a requirement for Ashfall and the mod will NOT work without it.", 
            buttons = {
                {
                    text = "Exit game and go to Skills Module Nexus page",
                    callback = function()
                        os.execute("start https://www.nexusmods.com/morrowind/mods/46034")
                        os.exit()
                    end
                },
                {
                    text = "Continue with a broken game"
                }
            } 
        })
    end

    if ( skillModule.version == nil ) or ( skillModule.version < 1.4 ) then

        this.helper.messageBox({
            message = "Outdated version of Skills Module detected.", 
            buttons = {
                {
                    text = "Exit game and go to Skills Module Nexus page",
                    callback = function()
                        os.execute("start https://www.nexusmods.com/morrowind/mods/46034")
                        os.exit()
                    end
                },
                {
                    text = "Continue"
                }
            } 
        })
    end

    --Persistent data stored on player reference 
    -- ensure data table exists
    local data = tes3.player.data
    data.Ashfall = data.Ashfall or {}

    -- create a public shortcut
    this.data = data.Ashfall

    this.data.currentStates = this.data.currentStates or {}
    this.data.wateredCells = this.data.wateredCells or {}
    --initialise mod config
    initialiseLocalSettings()

    this.log:info("Common Data loaded successfully")
    event.trigger("Ashfall:dataLoaded")

    if not dataLoadedOnce then
        dataLoadedOnce = true
        event.trigger("Ashfall:dataLoadedOnce")
    end
end
event.register("loaded", onLoaded)


return this
