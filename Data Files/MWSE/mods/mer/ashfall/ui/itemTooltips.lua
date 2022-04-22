local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("itemTooltips")
local config = require("mer.ashfall.config").config
local teaConfig   = require("mer.ashfall.config.teaConfig")
local foodConfig = require("mer.ashfall.config.foodConfig")
local hungerController = require("mer.ashfall.needs.hungerController")
local activatorController = require("mer.ashfall.activators.activatorController")

--Todo- refactor and get rid of these duplicate functions
--They are in CampfireUtil, but that file requires this one already
local function getUtensilData(dataHolder)
    local utensilId = dataHolder.data.utensilId
    local utensilData = common.staticConfigs.utensils[utensilId]

    if dataHolder.object and not utensilData then
        utensilData = common.staticConfigs.utensils[dataHolder.object.id:lower()]
    end
    return utensilData
end

local function getUtensilCapacity(e)
    local dataHolder = e.dataHolder
    local object = e.object

    local bottleData = object and common.staticConfigs.bottleList[object.id:lower()]
    local utensilData = dataHolder and getUtensilData(dataHolder)
    local capacity = (bottleData and bottleData.capacity)
        or ( utensilData and utensilData.capacity )

    return capacity
end

local function centerText(element)
    element.autoHeight = true
    element.widthProportional = 1.0
    element.wrapText = true
    element.justifyText = "center"
end

local function addLadleTooltips(item, itemData, tooltip)
    if not itemData then return end
    --Ladle
    if common.staticConfigs.cookingPots[item.id:lower()] and itemData.data.ladle then
        common.helper.addLabelToTooltip(tooltip,
            string.format("+Ladle")
        )
    end
end

local function addWaterTooltips(item, itemData, tooltip)
    local data = itemData and itemData.data or nil

    local waterHeat = data and data.waterHeat
    if waterHeat and waterHeat > 0 then
        common.helper.addLabelToTooltip(tooltip,
            string.format("Heat: %d/100", waterHeat)
        )
    end

    local capacity = getUtensilCapacity{ dataHolder = itemData, object = item }
    if capacity then
        local waterAmount = data and data.waterAmount or 0
        local waterType = data and data.waterType or nil
        common.helper.addLabelToTooltip(tooltip,
            string.format("Water: %d/%d %s",
                math.ceil(waterAmount),
                capacity,
                ( waterType and waterType == "dirty" and "(Dirty) " or "")
            )
        )
    end

    local unfilteredWater = data and data.unfilteredWater
    if unfilteredWater and capacity then
        common.helper.addLabelToTooltip(tooltip,
            string.format("Unfiltered Water: %d/%d",
                math.ceil(unfilteredWater), capacity))
    end
end

local function addFoodTooltips(item, itemData, tooltip)
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

        if common.helper.isModifierKeyPressed() then
            local actionLabel  = tooltip:createLabel({ text = "Eat" })
            actionLabel.color = tes3ui.getPalette("active_color")
            centerText(actionLabel)
        end
    end
end

---@param item tes3object
---@param itemData tes3itemData
---@param tooltip tes3uiElement
local function addTeaTooltips(item, itemData, tooltip)
    if itemData and teaConfig.teaTypes[itemData.data.waterType] then
        local progress = itemData.data.teaProgress or 0
        local teaData = teaConfig.teaTypes[itemData.data.waterType]

        if progress >= 100 then
            local effectBlock = common.helper.addLabelToTooltip(tooltip)
            local icon = effectBlock:createImage{ path = "Icons/ashfall/spell/teaBuff.dds" }
            icon.height = 16
            icon.width = 16
            icon.scaleMode = true
            icon.borderAllSides = 1

            --for X hours
            local hoursText = ""
            if teaData.duration then
                local amount = itemData.data.waterAmount
                local duration = common.helper.calculateTeaBuffDuration(teaData.duration, itemData.data.waterHeat)
                hoursText = string.format(" for %d hour%s", duration, (duration >= 2 and "s" or "") )
            end
            local effectLabelText = teaData.effectDescription .. hoursText
            local effectLabel = effectBlock:createLabel{ text = effectLabelText }
            effectLabel.borderLeft = 4
        end


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
        local teaLabel = common.helper.addLabelToTooltip(tooltip, teaLabelText, tes3ui.getPalette("header_color"))

    end
end

local function addStewTooltips(item, itemData, tooltip)
    if itemData and itemData.data.stewLevels then
        local outerBlock = tooltip:createBlock{}
                outerBlock.autoHeight = true
                outerBlock.autoWidth = true
                outerBlock.childAlignX = 0.5
                outerBlock.flowDirection = "top_to_bottom"

        logger:trace("Stew Tooltips")
        local stewName = foodConfig.isStewNotSoup(itemData.data.stewLevels) and "Stew" or "Soup"

        local progress = ( itemData.data.stewProgress or 0 )
        local progressText

        logger:trace("progress: %d", progress)
        if progress < 100 then
            progressText = string.format("%s (%d%% Cooked)", stewName, progress )
        elseif itemData.data.waterHeat < common.staticConfigs.hotWaterHeatValue then
            progressText = string.format("%s (Cold)", stewName)
        else
            progressText = string.format("%s (Cooked)", stewName)
        end
        local stewProgressLabel = outerBlock:createLabel({ text = progressText })
        stewProgressLabel.color = tes3ui.getPalette("header_color")
        centerText(stewProgressLabel)


        for foodType, ingredLevel in pairs(itemData.data.stewLevels) do
            local block = outerBlock:createBlock{}
                block.autoHeight = true
                block.autoWidth = true
                block.childAlignX = 0.5
            local value = math.min(ingredLevel, 100)
            local stewBuff = foodConfig.getStewBuffForFoodType(foodType)
            local spell = tes3.getObject(stewBuff.id)
            local effect = spell.effects[1]

            local ingredText = string.format("(%d%% %s)", value, foodType )
            local ingredLabel

            if progress >= 100 then



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
end

local function additemTooltips(item, itemData, tooltip)
    addLadleTooltips(item, itemData, tooltip)
    addTeaTooltips(item, itemData, tooltip)
    addWaterTooltips(item, itemData, tooltip)
    addFoodTooltips(item, itemData, tooltip)
    addStewTooltips(item, itemData, tooltip)

    tooltip:updateLayout()
end

return additemTooltips