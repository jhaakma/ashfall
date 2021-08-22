local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config")
local animCtrl = require("mer.ashfall.effects.animationController")
local skipActivate

local cushions = {
    ashfall_cushion_01 = { height = 20 },
    ashfall_cushion_02 = { height = 20 },
    ashfall_cushion_03 = { height = 20 },
    ashfall_cushion_04 = { height = 20 },
    ashfall_cushion_05 = { height = 20 },
    ashfall_cushion_06 = { height = 20 },
    ashfall_cushion_07 = { height = 20 },
    ashfall_cushion_sq_01 = { height = 10 },
    ashfall_cushion_sq_02 = { height = 10 },
    ashfall_cushion_sq_03 = { height = 10 },
    ashfall_cushion_sq_04 = { height = 10 },
    ashfall_cushion_sq_05 = { height = 10 },
    ashfall_cushion_sq_06 = { height = 10 },
    ashfall_cushion_sq_07 = { height = 10 },

}

local function canRest()
    return tes3.canRest()
end

local function cushionMenu(e)
    local ref = e.ref
    local activator = e.activator
    local message = ref.object.name or activator.name
    local buttons = {
        {
            text = "Sit Down",
            requirements = canRest,
            callback = function()
                -- if (not cushions[ref.object.id:lower()]) and (activator and not activator.ids[ref.object.id:lower()]) then
                --     common.log:error("Cushion menu called on cushion that isn't in config somehow.")
                --     return
                -- end

                local location = {
                    position = tes3vector3.new(
                        ref.position.x,
                        ref.position.y,
                        ref.position.z + common.helper.getObjectHeight(ref.object) - 7
                    ),
                    orientation = {
                        0,--ref.orientation.x,
                        0,--ref.orientation.y,
                        tes3.player.orientation.z + math.pi,
                    },
                    cell = ref.cell
                }
                local collisionRef
                if activator then collisionRef = ref end
                animCtrl.showFastTimeMenu{
                    message = "Sit Down",
                    anim = "sitting",
                    location = location,
                    recovering = true,
                    speeds = { 2, 5, 10 },
                    collisionRef = collisionRef
                }
            end,
            tooltipDisabled = {
                text = "You can't wait here; enemies are nearby."
            },
        },
        {
            text = "Pick up",
            showRequirements = function()
                return not activator
            end,
            callback = function()
                timer.delayOneFrame(function()
                    skipActivate = true
                    tes3.player:activate(ref)
                end)
            end
        },
    }
    common.helper.messageBox{
        message = message,
        buttons = buttons,
        doesCancel = true
    }
end


local function activateCushion(e)
    if not (e.activator == tes3.player) then return end
    --Check if it's a misc tent ref
    if cushions[e.target.object.id:lower()] then
        --Skip if picking up
        if skipActivate then
            skipActivate = false
            return
        end
        --Pick up if activating while in inventory
        if tes3ui.menuMode() then
            return
        end
        --Pick up if underwater
        if common.helper.getRefUnderwater(e.target) then
            return
        end

        cushionMenu({ ref = e.target })
        return false
    end
end
event.register("activate", activateCushion)


event.register(
    "Ashfall:ActivatorActivated",
    cushionMenu,
    { filter = common.staticConfigs.activatorConfig.types.cushion }
)