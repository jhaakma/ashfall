local common = require ("mer.ashfall.common.common")
local activators = require("mer.ashfall.activators.activatorController")
local activatorConfig = common.staticConfigs.activatorConfig

local CookingMenu = require("mer.ashfall.cooking.cookingMenu")

local function onActivate()
    local inputController = tes3.worldController.inputController
    local pressedActivateKey = inputController:keybindTest(tes3.keybind.activate)
    if pressedActivateKey then
        local cookingActive = (
            common.data and
            common.config.getConfig().enableHunger and
            common.config.getConfig().enableCooking
        )
        if cookingActive then
            local currentActivator = activators.getCurrentActivator()
            local lookingAtUtensil = ( 
                currentActivator and
                currentActivator.type == activatorConfig.cookingUtensil.type
            )
            if lookingAtUtensil then
                common.log:info("Creating %s menu", currentActivator.name)
                local menu = CookingMenu:new({
                    name = currentActivator.name
                })
                menu:create()
                return
            else
                common.log:info("Not looking at a utensil")
            end
        end
    end
end
 
event.register("keyDown-DISABLED", onActivate )

