local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local overrides = require("mer.ashfall.config.overrides")
local this = {}
local newGame
local checkingChargen
local charGen
local charGenValues = {
    newGame = 10,
    charGenFinished = -1
}

function this.doNeeds(needs)
    for setting, value in pairs(needs) do
        common.log:debug("Setting %s to %s", setting, value)
        config[setting] = value
    end
    event.trigger("Ashfall:UpdateHud")
end

function this.doTimeScale()
    local timeScale = config.manualTimeScale
    tes3.setGlobal("TimeScale", timeScale)
end

function this.doOverrides()
    for id, override in pairs(overrides) do
        local item = tes3.getObject(id)
        if item then
            common.log:trace("Overriding values for %s", item.id)
            item.value = override.value or item.value
            item.weight = override.weight or item.weight
        else
            common.log:trace("%s not found", id)
        end
    end
end

function this.confirmManualConfigure()
    return
end


function this.doDefaultSettings()
    tes3.messageBox("Ashfall using default settings.")
    config.doIntro = false
    config.overrideFood = true
    config.manualTimeScale = common.defaultValues.manualTimeScale
    this.doTimeScale()
    this.doOverrides()
    this.doNeeds({
        enableTemperatureEffects = true,
        enableHunger = true,
        enableThirst = true,
        enableTiredness = true,
        enableSickness = true,
        enableBlightness = true,
    })
end

function this.confirmDefaultSettings()
    local message = string.format(
        "Default Settings: All needs enabled. Timescale set to 20. Item weights and values adjusted. \n\nYou can change this setting in the MCM menu at any time. Proceed?",
        common.defaultValues.manualTimeScale
    )
    common.helper.messageBox{
        message = message,
        buttons = {
            { text = "Okay", callback = this.doDefaultSettings
        },
            { text = "Go back", callback = this.startAshfall }
        }
    }
end


function this.doVanillaSettings()
    tes3.messageBox("Ashfall using vanilla settings (no changes).")
    config.doIntro = false
    config.overrideTimeScale = false
    config.overrideFood = false
    this.doNeeds({
        enableTemperatureEffects = true,
        enableHunger = true,
        enableThirst = true,
        enableTiredness = true,
        enableSickness = true,
        enableBlightness = true,
    })
end
function this.confirmVanillaSettings()
    common.helper.messageBox{
        message = "Vanilla Settings: no changes to timescale or item values. \n\nYou can change this setting in the MCM menu at any time. Proceed?",
        buttons = {
            { text = "Okay", callback = this.doVanillaSettings },
            { text = "Go back", callback = this.startAshfall }
        }
    }
end

function this.disableAshfall()
    tes3.messageBox("Needs mechanics are disabled.")
    config.doIntro = false
    config.overrideTimeScale = false
    config.overrideFood = false
    this.doNeeds({
        enableTemperatureEffects = false,
        enableHunger = false,
        enableThirst = false,
        enableTiredness = false,
        enableSickness = false,
        enableBlightness = false,
    })
end


function this.startAshfall()
    
    if config.doIntro == true then
        local introMessage = (
            "Welcome to Ashfall! \n"..
            "Please take a moment to configure the start-up options. \n"..
            "You will only have to do this once."
        )
        local buttons = {
            -- {
            --     text = "Configure",
            --     callback = this.confirmManualConfigure
            -- },
            {
                text = "Use Default Settings (Recommended)",
                callback = this.confirmDefaultSettings
            },
            {
                text = "Use Vanilla Settings",
                callback = this.confirmVanillaSettings
            },
            {
                text = "Disable Ashfall",
                callback = this.disableAshfall
            }
        }
        common.helper.messageBox{ message = introMessage, buttons = buttons}
    else
        --initialise defaults
        
        if config.overrideTimeScale and newGame then
            this.doTimeScale()
        end
        local doOverrideFood = config.overrideFood
        if doOverrideFood then
            common.log:debug("Overriding ingredient values")
            this.doOverrides()
        end

    end
end


local function checkCharGen()
    if charGen.value == charGenValues.newGame then
        newGame = true
    elseif newGame and charGen.value == charGenValues.charGenFinished then
        checkingChargen = false
        event.unregister("simulate", checkCharGen)
        timer.start{
            type = timer.simulate,
            duration = 2.0, --If clashes with char backgrounds, mess with this
            callback = this.startAshfall
        }
        if config.startingEquipment then
            mwscript.addItem{reference=tes3.player, item="misc_com_bucket_metal"}
            mwscript.addItem{reference=tes3.player, item="misc_com_bottle_10"}
            mwscript.addItem{reference=tes3.player, item="ashfall_bedroll"}
            mwscript.addItem{reference=tes3.player, item="ashfall_woodaxe"}
        end
    end
end


local function onDataLoaded(e)

    newGame = nil --reset so we can check chargen state again
    charGen = tes3.findGlobal("CharGenState")
    if charGen.value == charGenValues.charGenFinished then
        this.startAshfall()
    else
        --Only reregister if necessary. If new game was started during
        --  chargen of previous game, this will already be running
        if not checkingChargen then
            event.register("simulate", checkCharGen)
            checkingChargen = true
        end
    end
end

event.register("Ashfall:dataLoaded", onDataLoaded )