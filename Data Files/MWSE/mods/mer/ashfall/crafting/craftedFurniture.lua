local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local miscToStaticMapping = {
    ashfall_table_sml = "ashfall_table_sml_s",
    ashfall_table_sml_2 = "ashfall_table_sml_2_s",
}
local staticToMiscMapping = {}
for misc, staticId in pairs(miscToStaticMapping) do
    staticToMiscMapping[staticId] = misc
end

local function onGearDropped(e)
    local staticId = miscToStaticMapping[e.reference.object.id:lower()]
    if staticId then
        local position = e.reference.position:copy()
        local orientation = e.reference.orientation:copy()
        local ref = tes3.createReference{
            object = staticId,
            position = position,
            orientation = orientation,
            cell = e.reference.cell,
        }
        if common.helper.isStack(e.reference) then
            tes3.addItem{
                reference = tes3.player,
                item = e.reference.object,
                count = e.reference.attachments.variables.count - 1,
                playSound = false
            }
        end
        common.helper.yeet(e.reference)
    end
end
event.register("Ashfall:GearDropped", onGearDropped)


local function pickup(staticRef)
    local miscId = staticToMiscMapping[staticRef.baseObject.id:lower()]
    tes3.addItem{ reference = tes3.player, item = miscId, }
    common.helper.yeet(staticRef)
end

local skipActivate
local function onActivate(e)
    if e.activator ~= tes3.player then return end
    local miscId = staticToMiscMapping[e.target.baseObject.id:lower()]
    if not miscId then return end
    if skipActivate then
        skipActivate = nil
        return
    end
    if tes3ui.menuMode() then
        pickup()
        return false
    end

    if tes3.worldController.inputController:isKeyDown(config.modifierHotKey.keyCode) then
        skipActivate = true
        tes3.player:activate(e.target)
        return
    end
    common.helper.messageBox{
        message = e.target.object.name,
        buttons = {
            {
                text = "Pick Up",
                callback = function()
                    pickup(e.target)
                end
            },

        },
        doesCancel = true
    }
    return false
end
event.register("activate", onActivate)