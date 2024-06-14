local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("itemTooltips")
local config = require("mer.ashfall.config").config
local teaConfig   = require("mer.ashfall.config.teaConfig")
local foodConfig = require("mer.ashfall.config.foodConfig")
local hungerController = require("mer.ashfall.needs.hungerController")
local WoodStack = require("mer.ashfall.items.woodStack")
local LiquidContainer = require("mer.ashfall.liquid.LiquidContainer")
local HeatUtil = require("mer.ashfall.heat.HeatUtil")

---@class Ashfall.addItemTooltips
local itemTooltips = {}

---@class Ashfall.addItemTooltips.params
---@field item tes3object
---@field itemData tes3itemData
---@field reference tes3reference
---@field tooltip tes3uiElement

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

---@param e Ashfall.addItemTooltips.params
local function addLadleTooltips(e)
    if not e.itemData then return end
    --Ladle
    if common.staticConfigs.cookingPots[e.item.id:lower()] and e.itemData.data.ladle then
        common.helper.addLabelToTooltip(e.tooltip,
            string.format("+Ladle")
        )
    end
end

---@param e Ashfall.addItemTooltips.params
local function addWaterTooltips(e)
    local data = e.itemData and e.itemData.data or nil

    local waterHeat = data and data.waterHeat
    if waterHeat and waterHeat > 0 then
        common.helper.addLabelToTooltip(e.tooltip,
            string.format("Heat: %d/100", waterHeat)
        )
    end

    local capacity = getUtensilCapacity{ dataHolder = e.itemData, object = e.item }
    if capacity then
        local waterAmount = data and data.waterAmount or 0
        local waterType = data and data.waterType or nil
        common.helper.addLabelToTooltip(e.tooltip,
            string.format("Water: %d/%d %s",
                math.floor(waterAmount),
                capacity,
                ( waterType and waterType == "dirty" and "(Dirty) " or "")
            )
        )
    end

    local unfilteredWater = data and data.unfilteredWater
    if unfilteredWater and capacity then
        common.helper.addLabelToTooltip(e.tooltip,
            string.format("Unfiltered Water: %d/%d",
                math.floor(unfilteredWater), capacity))
    end
end

---@param e Ashfall.addItemTooltips.params
local function addFoodTooltips(e)
    --Food tooltips
    local labelText
    local thisFoodType = foodConfig.getFoodType(e.item)
    if thisFoodType then
        local nutrition = hungerController.getNutrition(e.item, e.itemData)
        if nutrition and nutrition ~= 0 then
            labelText = string.format("Nutrition: %d", nutrition)
            common.helper.addLabelToTooltip(e.tooltip, labelText)
        end

        local cookedLabel = ""
        if foodConfig.getGrillValues(e.item) then

            --Remove cook state from the ingredient name for TR foods
            local cookStrings = {
                "raw ",
                "cooked ",
                "grilled ",
                "roasted "
            }
            local nameLabel = e.tooltip:findChild(tes3ui.registerID("HelpMenu_name"))
            if not nameLabel then return end
            for _, pattern in ipairs(cookStrings) do
                if string.startswith(nameLabel.text:lower(), pattern) then
                    nameLabel.text = nameLabel.text:sub(string.len(pattern) + 1, -1)
                end
            end

            --Add Food type and Cook state label to Tooltip
            local cookedAmount = e.itemData and e.itemData.data.cookedAmount
            if cookedAmount and e.itemData.data.grillState == nil then
                cookedLabel = string.format(" (%d%% Cooked)", cookedAmount)
            elseif e.itemData and e.itemData.data.grillState == "cooked"  then
                cookedLabel = " (Cooked)"
            elseif  e.itemData and e.itemData.data.grillState == "burnt" then
                cookedLabel = " (Burnt)"
            else
                cookedLabel = " (Raw)"
            end
        end

        local foodTypeLabel = string.format("%s%s", thisFoodType, cookedLabel)
        common.helper.addLabelToTooltip(e.tooltip, foodTypeLabel)


        --Meat disease/blight
        if config.enableDiseasedMeat then
            if e.itemData and e.itemData.data.mer_disease then
                local diseaseLabel
                local diseaseType = e.itemData.data.mer_disease.spellType
                if diseaseType == tes3.spellType.disease then
                    diseaseLabel = "Diseased"
                elseif diseaseType == tes3.spellType.blight then
                    diseaseLabel = "Blighted"
                end
                if diseaseLabel then
                    common.helper.addLabelToTooltip(e.tooltip, diseaseLabel, tes3ui.getPalette("negative_color"))
                end
            end
        end

        if common.helper.isModifierKeyPressed() then
            local actionLabel  = e.tooltip:createLabel({ text = "Eat" })
            actionLabel.color = tes3ui.getPalette("active_color")
            centerText(actionLabel)
        end
    end
end

---@param e Ashfall.addItemTooltips.params
local function addTeaTooltips(e)
    if e.itemData and teaConfig.teaTypes[e.itemData.data.waterType] then
        local progress = e.itemData.data.teaProgress or 0
        local teaData = teaConfig.teaTypes[e.itemData.data.waterType]

        if progress >= 100 then
            local effectBlock = common.helper.addLabelToTooltip(e.tooltip)
            local icon = effectBlock:createImage{ path = "Icons/ashfall/spell/teaBuff.dds" }
            icon.height = 16
            icon.width = 16
            icon.scaleMode = true
            icon.borderAllSides = 1

            --for X hours
            local hoursText = ""
            if teaData.duration then
                local amount = e.itemData.data.waterAmount
                local duration = common.helper.calculateTeaBuffDuration(teaData.duration, e.itemData.data.waterHeat)
                hoursText = string.format(" for %d hour%s", duration, (duration >= 2 and "s" or "") )
            end
            local effectLabelText = teaData.effectDescription .. hoursText
            local effectLabel = effectBlock:createLabel{ text = effectLabelText }
            effectLabel.borderLeft = 4
        end


        local teaLabelText = teaData.teaName
        local waterHeat = e.itemData.data.waterHeat or 0
        local isCold = waterHeat < common.staticConfigs.hotWaterHeatValue
        if progress == 0 then
            teaLabelText = string.format("%s (Unbrewed)", teaLabelText)
        elseif progress < 100 then
            teaLabelText = string.format("%s (%d%% Brewed)", teaLabelText, progress)
        elseif isCold then
            teaLabelText = teaLabelText .. " (Cold)"
        end
        common.helper.addLabelToTooltip(e.tooltip, teaLabelText, tes3ui.getPalette("header_color"))
    end
end

---@param e Ashfall.addItemTooltips.params
---@param liquidContainer Ashfall.LiquidContainer?
local function addStewTooltips(e, liquidContainer)
    logger:trace("addStewTooltips")
    if not (liquidContainer and liquidContainer.stewLevels) then return end
    logger:trace("Have Stew")

    local outerBlock = e.tooltip:createBlock{}
            outerBlock.autoHeight = true
            outerBlock.autoWidth = true
            outerBlock.childAlignX = 0.5
            outerBlock.flowDirection = "top_to_bottom"

    logger:trace("Stew Tooltips")
    local stewName = foodConfig.isStewNotSoup(liquidContainer.stewLevels) and "Stew" or "Soup"

    local progressText

    logger:trace("progress: %d", liquidContainer.stewProgress)
    if liquidContainer.stewProgress < 100 then
        progressText = string.format("%s (%d%% Cooked)", stewName, liquidContainer.stewProgress )
    elseif liquidContainer.waterHeat < common.staticConfigs.hotWaterHeatValue then
        progressText = string.format("%s (Cold)", stewName)
    else
        progressText = string.format("%s (Cooked)", stewName)
    end
    local stewProgressLabel = outerBlock:createLabel({ text = progressText })
    stewProgressLabel.color = tes3ui.getPalette("header_color")
    centerText(stewProgressLabel)

    for foodType, ingredLevel in pairs(liquidContainer.stewLevels) do
        logger:trace("Food Type: %s, Level: %d", foodType, ingredLevel)
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
        if liquidContainer.stewProgress >= 100 then
            logger:trace("Have Stew Buff")
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
            local duration = common.helper.calculateStewBuffDuration(liquidContainer.waterHeat)
            local hoursText = string.format("for %d hour%s", duration, (duration >= 2 and "s" or "") )

            ingredLabel = block:createLabel{text = string.format("%s %s: %s %s %s", spell.name, ingredText, effectNameText, pointsText, hoursText) }
            ingredLabel.wrapText = false
            ingredLabel.borderLeft = 4
        else
            ingredLabel = e.tooltip:createLabel{text = ingredText }
            centerText(ingredLabel)
        end
    end
end

local function addWoodStackTooltips(item, itemData, tooltip)
    if not itemData then return end
    if itemData.data.woodAmount then
        common.helper.addLabelToTooltip(tooltip,
            string.format("Firewood: %d/%d", itemData.data.woodAmount, WoodStack.getCapacity(item.id ))
        )
    end
end


---@param e Ashfall.addItemTooltips.params
function itemTooltips.addItemTooltips(e)
    local liquidContainer
    if e.reference then
        liquidContainer = LiquidContainer.createFromReference(e.reference)
        if not e.item then
            e.item = e.reference.object
        end
        if not e.itemData then
            e.itemData = e.reference.itemData
        end
    else
        liquidContainer = LiquidContainer.createFromInventory(e.item, e.itemData)
    end

    local menu = tes3ui.findMenu("MenuInventory")
    if liquidContainer and tes3ui.menuMode() and menu and menu.visible then
        HeatUtil.updateWaterHeat(liquidContainer)
    end
    addLadleTooltips(e)
    addTeaTooltips(e)
    addWaterTooltips(e)
    addFoodTooltips(e)
    addStewTooltips(e, liquidContainer)
    addWoodStackTooltips(e)
    e.tooltip:updateLayout()
end



return itemTooltips