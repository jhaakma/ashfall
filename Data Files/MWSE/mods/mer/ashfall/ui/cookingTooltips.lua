local common = require ("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local teaConfig   = require("mer.ashfall.config.teaConfig")
local foodConfig = require("mer.ashfall.config.foodConfig")
local hungerController = require("mer.ashfall.needs.hungerController")
local activatorController = require("mer.ashfall.activators.activatorController")

local function getUtensilData(dataHolder)
    local utensilId = dataHolder.data.utensilId
    local utensilData = common.staticConfigs.utensils[utensilId]

    if dataHolder.object and not utensilData then
        utensilData = common.staticConfigs.utensils[dataHolder.object.id:lower()]
    end
    return utensilData
end

local function centerText(element)
    element.autoHeight = true
    element.widthProportional = 1.0
    element.wrapText = true
    element.justifyText = "center"
end

local function addCookingTooltips(item, itemData, tooltip)
    if not itemData then return end
    local waterAmount = itemData.data.waterAmount

    --Ladle
    if common.staticConfigs.cookingPots[item.id:lower()] and itemData.data.ladle then
        common.helper.addLabelToTooltip(tooltip,
            string.format("+Ladle")
        )
    end

    if waterAmount then
        --WATER
        local waterHeat = itemData.data.waterHeat or 0
        local bottleData = common.staticConfigs.bottleList[item.id and string.lower(item.id)]
        local utensilData = getUtensilData(itemData)
        local capacity = (bottleData and bottleData.capacity) or ( utensilData and utensilData.capacity )

        common.helper.addLabelToTooltip(tooltip,
            string.format("Heat: %d/100", waterHeat)
        )
        common.helper.addLabelToTooltip(tooltip,
            string.format("Water: %d/%d %s",
                math.ceil(waterAmount),
                capacity,
                ( itemData.data.waterType == "dirty" and "(Dirty) " or "")
            )
        )
    end

    local showPatina = false
        if showPatina then
        --Patina
        if itemData and itemData.data and itemData.data.patinaAmount then
            common.helper.addLabelToTooltip(tooltip, string.format("Patina: %d/100", itemData.data.patinaAmount))
        end
    end

    --Food tooltips
    local labelText
    local thisFoodType = foodConfig.getFoodType(item)
    if thisFoodType then
        if config.enableHunger  then
            --hunger value
            local nutrition = hungerController.getNutrition(item, itemData)
            if nutrition and nutrition ~= 0 then
                labelText = string.format("Nutrition: %d", nutrition)
                common.helper.addLabelToTooltip(tooltip, labelText)
            end

            local cookedLabel = ""
            if foodConfig.getGrillValues(item) then

                --Remove cook state from the ingredient name for TR foods
                local cookStrings = {
                    "raw ",
                    "cooked ",
                    "grilled ",
                    "roasted "
                }
                local nameLabel = tooltip:findChild(tes3ui.registerID("HelpMenu_name"))
                for _, pattern in ipairs(cookStrings) do
                    if string.startswith(nameLabel.text:lower(), pattern) then
                        nameLabel.text = nameLabel.text:sub(string.len(pattern) + 1, -1)
                    end
                end

                --Add Food type and Cook state label to Tooltip
                local cookedAmount = itemData and itemData.data.cookedAmount
                if cookedAmount and itemData.data.grillState == nil then
                    cookedLabel = string.format(" (%d%% Cooked)", cookedAmount)
                elseif itemData and itemData.data.grillState == "cooked"  then
                    cookedLabel = " (Cooked)"
                elseif  itemData and itemData.data.grillState == "burnt" then
                    cookedLabel = " (Burnt)"
                else
                    cookedLabel = " (Raw)"
                end
            end

            local foodTypeLabel = string.format("%s%s", thisFoodType, cookedLabel)
            common.helper.addLabelToTooltip(tooltip, foodTypeLabel)

        end

        --Meat disease/blight
        if config.enableDiseasedMeat then
            if itemData and itemData.data.mer_disease then
                local diseaseLabel
                local diseaseType = itemData.data.mer_disease.spellType
                if diseaseType == tes3.spellType.disease then
                    diseaseLabel = "Diseased"
                elseif diseaseType == tes3.spellType.blight then
                    diseaseLabel = "Blighted"
                end
                if diseaseLabel then
                    common.helper.addLabelToTooltip(tooltip, diseaseLabel, tes3ui.getPalette("negative_color"))
                end
            end
        end
    end

    if teaConfig.teaTypes[itemData.data.waterType] then
        local progress = itemData.data.teaProgress or 0
        local teaData = teaConfig.teaTypes[itemData.data.waterType]

        local teaLabelText = teaData.teaName
        local waterHeat = itemData.data.waterHeat or 0
        local isCold = waterHeat < common.staticConfigs.hotWaterHeatValue

        if progress == 0 then
            teaLabelText = string.format("%s (Unbrewed)", teaLabelText)
        elseif progress < 100 then
            teaLabelText = string.format("%s (%d%% Brewed)", teaLabelText, progress)
        elseif isCold then
            teaLabelText = teaLabelText .. " (Cold)"
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


            --for X hours
            local amount = itemData.data.waterAmount
            local duration = common.helper.calculateTeaBuffDuration(teaData.duration, itemData.data.waterHeat)
            local hoursText = string.format("for %d hour%s", duration, (duration >= 2 and "s" or "") )

            local effectLabelText = teaData.effectDescription .. " " .. hoursText
            local effectLabel = effectBlock:createLabel{ text = effectLabelText }
            effectLabel.borderLeft = 4
        end
    end

    if itemData.data.stewLevels then
        local stewName = foodConfig.isStewNotSoup(itemData.data.stewLevels) and "Stew" or "Soup"

        local progress = ( itemData.data.stewProgress or 0 )
        local progressText


        if progress < 100 then
            progressText = string.format("%s (%d%% Cooked)", stewName, progress )
        elseif itemData.data.waterHeat < common.staticConfigs.hotWaterHeatValue then
            progressText = string.format("%s (Cold)", stewName)
        else
            progressText = string.format("%s (Cooked)", stewName)
        end
        local stewProgressLabel = tooltip:createLabel({ text = progressText })
        stewProgressLabel.color = tes3ui.getPalette("header_color")
        centerText(stewProgressLabel)


        for foodType, ingredLevel in pairs(itemData.data.stewLevels) do
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
                local duration = common.helper.calculateStewBuffDuration(itemData.data.waterHeat)
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


    -- if activatorController.currentRef and  activatorController.parentNode then
    --     local eventData = {
    --         parentNode = activatorController.parentNode,
    --         element = tooltip,
    --         reference = activatorController.currentRef
    --     }
    --     event.trigger("Ashfall:Activator_tooltip", eventData, {filter = activatorController.current })
    -- end
end

return addCookingTooltips