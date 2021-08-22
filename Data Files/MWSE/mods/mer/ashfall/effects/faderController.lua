local this = {}
local common = require("mer.ashfall.common.common")
local conditionConfig = common.staticConfigs.conditionConfig
local fadeTime = 1.5

local faderConfigs = {
    freezing = {
        name = "Freezing",
        texture = "Textures/Ashfall/faders/frozen.dds",
        onSound = "ashfall_freeze",
        condition = "temp",
        conditionMax = conditionConfig.temp.states.freezing.max
    },
    scorching = {
        name = "Scorching",
        texture = "Textures/Ashfall/faders/scorching.dds",
        onSound = "ashfall_scorch",
        condition = "temp",
        conditionMin = conditionConfig.temp.states.scorching.min
    },

}
local function faderSetup()
    for _, faderConfig in pairs(faderConfigs) do
        faderConfig.fader = tes3fader.new()
        faderConfig.fader:setTexture(faderConfig.texture)
        faderConfig.fader:setColor({ color = { 0.5, 0.5, 0.5 }, flag = false })
        event.register("enterFrame",
            function()
                faderConfig.fader:update()
            end
        )
    end
end
event.register("fadersCreated", faderSetup)

local function setFading(faderConfig)
    faderConfig.isFading = true
    timer.start{
        type = timer.real,
        duration = fadeTime,
        callback = function()
            common.log:trace("Setting isFading back to false")
            faderConfig.isFading = false
        end
    }
end

local function fadeIn(faderConfig)
    faderConfig.active = true
    faderConfig.fader:fadeTo({ value = 0.5, duration = fadeTime})
    setFading(faderConfig)
    if faderConfig.onSound then
        local effectsChannel = 2
        tes3.playSound({ sound = faderConfig.onSound, mixChannel = effectsChannel })
    end
end

local function fadeOut(faderConfig)
    faderConfig.active = false
    faderConfig.fader:fadeOut({ duration = fadeTime })
    setFading(faderConfig)
    if faderConfig.offSound then
        local effectsChannel = 2
        tes3.playSound({ sound = faderConfig.offSound, mixChannel = effectsChannel })
    end
end


local function checkFaders()
    for _, faderConfig in pairs(faderConfigs) do
        if not faderConfig.isFading then
            common.log:trace("Not already fading, checking fade values")
            local condition = conditionConfig[faderConfig.condition]
            local currentValue = condition:getValue()

            local outOfBounds = false
            if faderConfig.conditionMin and currentValue < faderConfig.conditionMin then
                outOfBounds = true
            end
            if faderConfig.conditionMax and currentValue > faderConfig.conditionMax then
                outOfBounds = true
            end
            --Deactivate
            if outOfBounds and faderConfig.active then
                fadeOut(faderConfig)
            --Activate
            elseif not outOfBounds and not faderConfig.active then
                fadeIn(faderConfig)
            end
        else
            common.log:trace("wait until fader is finished")
        end
    end
end
event.register("simulate", checkFaders)

event.register("loaded", function()
    for _, faderConfig in pairs(faderConfigs) do
        faderConfig.isFading = false
        if faderConfig.active then
            fadeOut(faderConfig)
        end
    end
end)

return this