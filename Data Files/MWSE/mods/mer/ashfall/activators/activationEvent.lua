local function triggerActivateKey(e)
    if (e.keyCode == tes3.getInputBinding(tes3.keybind.activate).code) and (tes3.getInputBinding(tes3.keybind.activate).device == 0) then
        event.trigger("Ashfall:ActivateButtonPressed")
    end
end
event.register("keyDown", triggerActivateKey )

local function triggerActivateMouse(e)
    if (e.button == tes3.getInputBinding(tes3.keybind.activate).code) and (tes3.getInputBinding(tes3.keybind.activate).device == 1) then
        event.trigger("Ashfall:ActivateButtonPressed")
    end
end
event.register("mouseButtonUp", triggerActivateMouse)