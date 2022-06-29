local common = require("mer.ashfall.common.common")
local animCtrl = require("mer.ashfall.animation.animationController")
local cushionConfig = require("mer.ashfall.items.cushion.config")
local skipActivate

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
            enableRequirements = canRest,
            callback = function()
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
    tes3ui.showMessageMenu{
        message = message,
        buttons = buttons,
        cancels = true
    }
end


local function activateCushion(e)
    if not (e.activator == tes3.player) then return end
    --Check if it's a misc tent ref
    if cushionConfig[e.target.object.id:lower()] then
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