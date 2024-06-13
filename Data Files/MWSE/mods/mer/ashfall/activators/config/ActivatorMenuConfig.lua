local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("activatorMenuConfig")
local itemTooltips = require("mer.ashfall.ui.itemTooltips")
local function centerText(element)
    element.autoHeight = true
    element.autoWidth = true
    element.wrapText = true
    element.justifyText = "center"
end

---@class Ashfall.Activator.ActivatorMenuConfig
---@field name string|nil **Optional** The name shown in the tooltip when this node is looked at.
---@field menuCommands table<string, function>|nil **Optional** A table of commands to be shown in the menu.
---@field command function|nil **Optional** A function to be called when this node is activated.
---@field shiftCommand function|string|nil **Optional** A function to be called when this node is activated with the shift key pressed.
---@field tooltipExtra function|nil **Optional** A function which populates the tooltip with extra information.

---@type table<string, Ashfall.Activator.ActivatorMenuConfig>
local ActivatorMenuConfig = {}


ActivatorMenuConfig.nodeMapping = {

    ACTIVATE_DOOR = {
        name = "Door",
        command = function(ref)
            logger:debug("Activating Door")
            local isOpen = ref.data and ref.data.ashfallDoorIsOpen
            if isOpen then
                logger:trace("Door is open, closing")
                tes3.playSound{
                    sound = "ashfall_door_close",
                    reference = tes3.player,
                    loop = false,
                }
                tes3.playAnimation {
                    reference = ref,
                    group = tes3.animationGroup.idle9,
                    startFlag = tes3.animationStartFlag.normal,
                    loopCount = 0,
                }
                ref.data.ashfallDoorIsOpen = false
            else
                logger:trace("Door is closed, opening")
                tes3.playSound{
                    sound = "ashfall_door_open",
                    reference = tes3.player,
                    loop = false,
                }
                tes3.playAnimation {
                    reference = ref,
                    group = tes3.animationGroup.idle8,
                    startFlag = tes3.animationStartFlag.normal,
                    loopCount = 0,
                }
                ref.data.ashfallDoorIsOpen = true
            end
        end
    },
    ASHFALL_WATER_CLEAN = {
        name = "Water (Clean)",
        command = function()
            event.trigger("Ashfall:WaterMenu")
        end
    },
    ASHFALL_WATER_DIRTY = {
        name = "Water (Dirty)",
        command = function()
            event.trigger("Ashfall:WaterMenu", { waterType = "dirty" })
        end
    },
    ASHFALL_STOVE = {
        menuCommands = {
            "pickupCooker"
        }
    },
    ASHFALL_FIREBASE = {
        menuCommands = {
            -- --actions
            "lightFire",
            -- --attach
             "addFirewood",
             "addSupports",
             "placeUtensil",
            -- --destroy
            "extinguish",
            "destroy",

        },
        tooltipExtra = function(reference, tooltip)
                local fuelLevel = reference.data.fuelLevel or 0
                if fuelLevel > 0 then
                    local fuelLabel = tooltip:createLabel{
                        text = string.format("Fuel: %.1f hours", fuelLevel )
                    }
                    centerText(fuelLabel)
                end
        end,
    },
    ASHFALL_GRILLER = {
        name = "Grill",
        menuCommands = {
            "pickup"
        }
    },
    DROP_GROUND_UTENSIL = {
        menuCommands = {
            -- --actions
            "lightFire",
            -- --attach
             "addFirewood",
             "addSupports",
             "placeUtensil",
            -- --destroy
            -- "extinguish",
            "destroy",

        },
        tooltipExtra = function(reference, tooltip)
            local fuelLevel = reference.data.fuelLevel or 0
            if fuelLevel > 0 then
                local fuelLabel = tooltip:createLabel{
                    text = string.format("Fuel: %.1f hours", fuelLevel )
                }
                centerText(fuelLabel)
            end
        end,
    },

    COOKING_POT = {
        idPath = "utensilId",
        menuCommands = {
            --actions
            "drink",
            "eatStew",
            "companionEatStew",
            "douse",
            "addIngredient",
            "fillContainer",
            "addWater",
            --attach
            "addLadle",
            "emptyContainer",
            --remove
            "removeUtensil",
            "removeLadle",
            "pickup",
        },
        shiftCommand = "removeUtensil",
        tooltipExtra = function(reference, tooltip)
            itemTooltips.addItemTooltips{
                item = reference.object,
                itemData = reference.itemData,
                reference = reference,
                tooltip = tooltip
            }
        end,
    },
    KETTLE = {
        idPath  = "utensilId",
        menuCommands = {
            --actions
            "drink",
            "douse",
            "brewTea",
            "fillContainer",
            "addWater",
            "emptyContainer",
            --attach
            "addLadle",
            --remove
            "removeUtensil",
            "pickup",
        },
        shiftCommand = "removeUtensil",

        tooltipExtra = function(reference, tooltip)
            itemTooltips.addItemTooltips{
                item = reference.object,
                itemData = reference.itemData,
                reference = reference,
                tooltip = tooltip
            }
        end,
    },
    SWITCH_LADLE = {
        name = "Ladle",
        menuCommands = {
            "removeLadle",
        },
        shiftCommand = "removeLadle"
    },
    ATTACH_GRILL = {
        idPath = "grillId",
        menuCommands = {
            "removeGrill",
        },
        shiftCommand = "removeGrill"
    },
    ATTACH_BELLOWS = {
        idPath = "bellowsId",
        menuCommands = {
            "removeBellows",
        },
        shiftCommand = "removeBellows",
        tooltipExtra = function(reference, tooltip)
            if reference.data.bellowsId then
                local bellowsId = reference.data.bellowsId
                local bellowsData = common.staticConfigs.bellows[bellowsId:lower()]

                local text = string.format("%sx Heat | %sx Fuel burn",
                    bellowsData.heatEffect, bellowsData.burnRateEffect)
                local bellowsLabel = tooltip:createLabel({ text = text })
                centerText(bellowsLabel)
            end
        end,
    },
    DROP_HANG_UTENSIL = {
        name = "Supports",
        idPath = "supportsId",
        menuCommands = {
            --attach
            "hangUtensil",
            --remove
            "removeUtensil",
            "removeSupports",
        },
        shiftCommand = "removeSupports"
    },


    --tea warmer
    TEA_WARMER = {
        tooltipExtra = function(teaWarmer, tooltip)
            local fuelLevel = teaWarmer.data.fuelLevel or 0
            if fuelLevel > 0 then
                local fuelLabel = tooltip:createLabel{
                    text = string.format("Fuel: %.1f hours", fuelLevel )
                }
                centerText(fuelLabel)
            end
        end,
    },

    DROP_WOODSTACK = {
        name = "Wood Stack",
        menuCommands = {
            "addToWoodStack",
            "takeFromWoodStack",
        },
        tooltipExtra = function(ref, tooltip)
            if not ref.data then return end
            local WoodStack = require("mer.ashfall.items.woodStack")
            if ref.data.woodAmount then
                local label = tooltip:createLabel{
                    text = string.format("Firewood: %d/%d", ref.data.woodAmount, WoodStack.getCapacity(ref.object.id ))
                }
                centerText(label)
            end
        end,
        shiftCommand = "takeFromWoodStack",
    },
}
return ActivatorMenuConfig