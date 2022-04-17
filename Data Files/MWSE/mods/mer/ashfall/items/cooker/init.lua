local common = require("mer.ashfall.common.common")
local miscToCookerMapping = {
    ashfall_misc_stove_01 = "ashfall_stove_01",
}

local function onGearDropped(e)
    local cookerId = miscToCookerMapping[e.reference.object.id:lower()]
    if cookerId then
        local position = e.reference.position:copy()
        local orientation = e.reference.orientation:copy()
        local ref = tes3.createReference{
            object = cookerId,
            position = position,
            orientation = orientation,
            cell = e.reference.cell,
        }
        ref.data.hasGrill = true
        ref.data.ashfallCookerMiscId = e.reference.object.id:lower()
        ref.data.fuelLevel = 0
        event.trigger("Ashfall:registerReference", { reference = ref})
        if common.helper.isStack(e.reference) then
            tes3.addItem{
                reference = tes3.player,
                item = e.reference.object,
                count = e.reference.attachments.variables.count - 1,
                playSound = false
            }
        end
        common.helper.yeet(e.reference)
        ref:deleteDynamicLightAttachment()
        event.trigger("Ashfall:UpdateAttachNodes", { campfire = ref})
    end
end
event.register("Ashfall:GearDropped", onGearDropped)