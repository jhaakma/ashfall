local HeatUtil = require("mer.ashfall.heat.HeatUtil")
local Campfire = require("mer.ashfall.camping.campfire.Campfire")
return {
    text = "Open Kiln",
    showRequirements = function(reference)
        if not reference.supportsLuaData then return false end
        if reference.data.kilnOpen then return false end
        return reference.sceneNode and reference.sceneNode:getObjectByName("SWITCH_KILN")
    end,
    enableRequirements = function(reference)
        local heat = HeatUtil.getHeat(reference)
        return heat < Campfire.STAGES.firing.minTemp
    end,
    tooltipDisabled = function()
        return {
            header = "Hint:",
            text = "The kiln cannot be opened while it is firing.",
        }
    end,
    callback = function(reference)
        tes3.playSound{ reference = reference, soundPath = "ashfall/brick_hi.wav" }
        reference.data.kilnOpen = true
        event.trigger("Ashfall:UpdateAttachNodes", { reference = reference})
    end
}