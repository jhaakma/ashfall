

return {
    text = "Close Kiln",
    showRequirements = function(reference)
        if not reference.supportsLuaData then return false end
        if not reference.data.kilnOpen then return false end
        return reference.sceneNode and reference.sceneNode:getObjectByName("SWITCH_KILN")
    end,
    callback = function(reference)
        tes3.playSound{ reference = reference, soundPath = "ashfall/brick_lo.wav" }
        reference.data.kilnOpen = false
        event.trigger("Ashfall:UpdateAttachNodes", { reference = reference})
    end
}