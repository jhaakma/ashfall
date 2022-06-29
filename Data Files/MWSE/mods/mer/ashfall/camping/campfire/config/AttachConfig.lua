local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("attachConfig")
local itemTooltips = require("mer.ashfall.ui.itemTooltips")
local function centerText(element)
    element.autoHeight = true
    element.autoWidth = true
    element.wrapText = true
    element.justifyText = "center"
end

local AttachConfig = {
    waterContainer = {
        commands = {
            --actions
            "drink",
            "brewTea",
            "eatStew",
            "douse",
            "companionEatStew",
            "addIngredient",
            "fillContainer",
            "addWater",
            "emptyPot",
            --attach
            "addLadle",
            "emptyKettle",
            --remove
            "removeUtensil",
            "removeLadle",
            "pickup",
        },
        tooltipExtra = function(campfire, tooltip)
            itemTooltips(campfire.object, campfire.itemData, tooltip)
        end,
    },

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
        commands = {
            "pickupCooker"
        }
    },
    ASHFALL_FIREBASE = {
        commands = {
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
        tooltipExtra = function(campfire, tooltip)
                local fuelLevel = campfire.data.fuelLevel or 0
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
        commands = {
            "pickup"
        }
    },
    DROP_GROUND_UTENSIL = {
        commands = {
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
        tooltipExtra = function(campfire, tooltip)
            local fuelLevel = campfire.data.fuelLevel or 0
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
        commands = {
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
            "emptyPot",
            --remove
            "removeUtensil",
            "removeLadle",
            "pickup",
        },
        shiftCommand = "removeUtensil",
        tooltipExtra = function(campfire, tooltip)
            itemTooltips(campfire.object, campfire.itemData, tooltip)
        end,
    },
    KETTLE = {
        idPath  = "utensilId",
        commands = {
            --actions
            "drink",
            "douse",
            "brewTea",
            "fillContainer",
            "addWater",
            "emptyKettle",
            --attach
            "addLadle",
            --remove
            "removeUtensil",
            "pickup",
        },
        shiftCommand = "removeUtensil",

        tooltipExtra = function(campfire, tooltip)
            itemTooltips(campfire.object, campfire.itemData, tooltip)
        end,
    },
    SWITCH_LADLE = {
        name = "Ladle",
        commands = {
            "removeLadle",
        },
        shiftCommand = "removeLadle"
    },
    ATTACH_GRILL = {
        idPath = "grillId",
        commands = {
            "removeGrill",
        },
        shiftCommand = "removeGrill"
    },
    ATTACH_BELLOWS = {
        idPath = "bellowsId",
        commands = {
            "removeBellows",
        },
        shiftCommand = "removeBellows",
        tooltipExtra = function(campfire, tooltip)
            if campfire.data.bellowsId then
                local bellowsId = campfire.data.bellowsId
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
        commands = {
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
        commands = {
            "addToWoodStack",
            "takeFromWoodStack",
        },
        tooltipExtra = function(ref, tooltip)
            if not ref.data then return end
            logger:debug("DROP_WOODSTACK")
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
return AttachConfig