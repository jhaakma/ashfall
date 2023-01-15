local ActivatorController = require("mer.ashfall.activators.ActivatorController")
local common = require("mer.ashfall.common.common")
local logger = common.createLogger("activatorController")

local isBlocked
local function blockScriptedActivate(e)
    isBlocked = e.doBlock
end
event.register("BlockScriptedActivate", blockScriptedActivate)

local function onActivateKeyPressed(e)
    logger:trace("onActivateKeyPressed")
    if not isBlocked then
        ActivatorController.doTriggerActivate()
    end
end
event.register("Ashfall:ActivateButtonPressed", onActivateKeyPressed)


local function triggerActivateKey(e)
    if (e.keyCode == tes3.getInputBinding(tes3.keybind.activate).code) and (tes3.getInputBinding(tes3.keybind.activate).device == 0) then
        event.trigger("Ashfall:ActivateButtonPressed")
    end
end
event.register("keyDown", triggerActivateKey )


local function triggerActivateMouse(e)
    local keyIsDown = (e.button == tes3.getInputBinding(tes3.keybind.activate).code)
        and (tes3.getInputBinding(tes3.keybind.activate).device == 1)
    if keyIsDown then
        event.trigger("Ashfall:ActivateButtonPressed")
    end
end
event.register("mouseButtonUp", triggerActivateMouse)


event.register("loaded", function() isBlocked = false end)