local common = require ("mer.ashfall.common.common")
local foodConfig = require("mer.ashfall.config.foodConfig")
local teaConfig   = require("mer.ashfall.config.teaConfig")
local function centerText(element)
    element.autoHeight = true
    element.autoWidth = true
    element.wrapText = true
    element.justifyText = "center"
end

local AttachConfig = {
    ACTIVATE_DOOR = {
        name = "Door",
        command = function(ref)
            common.log:debug("Activating Door")
            local isOpen = ref.data and ref.data.ashfallDoorIsOpen
            if isOpen then
                common.log:trace("Door is open, closing")
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
                common.log:trace("Door is closed, opening")
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
            "pickup"
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
        shiftCommand = "destroy",
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
        shiftCommand = "destroy",
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
    HANG_UTENSIL = {
        idPath = "utensilId",
        commands = {
            --actions
            "drink",
            "eatStew",
            "companionEatStew",
            "brewTea",
            "addIngredient",
            "fillContainer",
            "addWater",
            "emptyPot",
            "emptyKettle",
            --attach
            "addLadle",
            --remove
            "removeUtensil",
        },
        shiftCommand = "removeUtensil",

        tooltipExtra = function(campfire, tooltip)
            local waterAmount = campfire.data.waterAmount or 0
            if waterAmount then
                --WATER
                local waterHeat = campfire.data.waterHeat or 0
                local waterLabel = tooltip:createLabel{
                    text = string.format(
                        "Water: %d/%d %s| Heat: %d/100",
                        math.ceil(waterAmount),
                        campfire.data.waterCapacity,
                        ( campfire.data.waterType == "dirty" and "(Dirty) " or ""),
                        waterHeat)
                }
                centerText(waterLabel)
                if teaConfig.teaTypes[campfire.data.waterType] then
                    local progress = campfire.data.teaProgress or 0
                    local teaData = teaConfig.teaTypes[campfire.data.waterType]
                    tooltip:createDivider()
                    local teaLabelText = teaData.teaName
                    if campfire.data.waterHeat < common.staticConfigs.hotWaterHeatValue then
                        teaLabelText = teaLabelText .. " (Cold)"
                    elseif progress < 100 then
                        teaLabelText = string.format("%s (%d%% Brewed)", teaLabelText, progress)
                    end

                    local teaLabel = tooltip:createLabel({ text = teaLabelText })
                    teaLabel.color = tes3ui.getPalette("header_color")
                    centerText(teaLabel)
                    if progress >= 100 then
                        local effectBlock = tooltip:createBlock{}
                        effectBlock.childAlignX = 0.5
                        effectBlock.autoHeight = true
                        effectBlock.autoWidth = true
                        effectBlock.flowDirection = "left_to_right"

                        local icon = effectBlock:createImage{ path = "Icons/ashfall/spell/teaBuff.dds" }
                        icon.height = 16
                        icon.width = 16
                        icon.scaleMode = true
                        icon.borderAllSides = 1

                        local effectLabelText = teaData.effectDescription
                        local effectLabel = effectBlock:createLabel{ text = effectLabelText }
                        effectLabel.borderLeft = 4
                    end
                end

                if campfire.data.stewLevels then
                    local stewName = foodConfig.isStewNotSoup(campfire.data.stewLevels) and "Stew" or "Soup"
                    tooltip:createDivider()

                    local progress = ( campfire.data.stewProgress or 0 )
                    local progressText


                    if progress < 100 then
                        progressText = string.format("%s (%d%% Cooked)", stewName, progress )
                    elseif campfire.data.waterHeat < common.staticConfigs.hotWaterHeatValue then
                        progressText = string.format("%s (Cold)", stewName)
                    else
                        progressText = string.format("%s (Cooked)", stewName)
                    end
                    local stewProgressLabel = tooltip:createLabel({ text = progressText })
                    stewProgressLabel.color = tes3ui.getPalette("header_color")
                    centerText(stewProgressLabel)


                    for foodType, ingredLevel in pairs(campfire.data.stewLevels) do
                        local value = math.min(ingredLevel, 100)
                        local stewBuff = foodConfig.getStewBuffForFoodType(foodType)
                        local spell = tes3.getObject(stewBuff.id)
                        local effect = spell.effects[1]

                        local ingredText = string.format("(%d%% %s)", value, foodType )
                        local ingredLabel

                        if progress >= 100 then
                            local block = tooltip:createBlock{}
                            block.autoHeight = true
                            block.autoWidth = true
                            block.childAlignX = 0.5


                            local image = block:createImage{path=("icons\\" .. effect.object.icon)}
                            image.wrapText = false
                            image.borderLeft = 4

                            --"Fortify Health"
                            local statName
                            if effect.attribute ~= -1 then
                                local stat = effect.attribute
                                statName = tes3.findGMST(888 + stat).value
                            elseif effect.skill ~= -1 then
                                local stat = effect.skill
                                statName = tes3.findGMST(896 + stat).value
                            end
                            local effectNameText
                            local effectName = tes3.findGMST(1283 + effect.id).value
                            if statName then
                                effectNameText = effectName:match("%S+") .. " " .. statName
                            else
                                effectNameText = effectName
                            end
                            --points " 25 points "
                            local pointsText = string.format("%d pts", common.helper.calculateStewBuffStrength(value, stewBuff.min, stewBuff.max) )
                            --for X hours
                            local duration = common.helper.calculateStewBuffDuration()
                            local hoursText = string.format("for %d hour%s", duration, (duration >= 2 and "s" or "") )

                            ingredLabel = block:createLabel{text = string.format("%s %s: %s %s %s", spell.name, ingredText, effectNameText, pointsText, hoursText) }
                            ingredLabel.wrapText = false
                            ingredLabel.borderLeft = 4
                        else
                            ingredLabel = tooltip:createLabel{text = ingredText }
                            centerText(ingredLabel)
                        end
                    end
                end
            end
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
}

return AttachConfig