local common = require("mer.ashfall.common.common")
local teaConfig = common.staticConfigs.teaConfig
local hungerController = require('mer.ashfall.needs.hungerController')
local thirstController = require('mer.ashfall.needs.thirstController')
local foodConfig = common.staticConfigs.foodConfig

local function setupOuterBlock(e)
    e.flowDirection = 'left_to_right'
    e.paddingTop = 0
    e.paddingBottom = 2
    e.paddingLeft = 6
    e.paddingRight = 6
    e.autoWidth = true
    e.autoHeight = true
    e.childAlignX = 0.5
end

local function createTooltip(tooltip, labelText, color)
    --Get main block inside tooltip
    local partmenuID = tes3ui.registerID('PartHelpMenu_main')
    local mainBlock = tooltip:findChild(partmenuID):findChild(partmenuID):findChild(partmenuID)

    local outerBlock = mainBlock:createBlock()
    setupOuterBlock(outerBlock)

    mainBlock:reorderChildren(1, -1, 1)
    mainBlock:updateLayout()
    if labelText then
        local label = outerBlock:createLabel({text = labelText})
        label.autoHeight = true
        label.autoWidth = true
        if color then label.color = color end
        return label
    end

    return outerBlock

end


--Adds fillbar showing how much water is left in a bottle. 
--Height of fillbar border based on capacity of bottle.
local function updateFoodAndWaterTile(e)
    if not common.data then return end
    if not common.config.getConfig().enableThirst then return end

    --bottles show water amount
    local bottleData = thirstController.getBottleData(e.item.id) 
    if bottleData then
        local liquidLevel = e.itemData and e.itemData.data.waterAmount or 0
        local capacity = bottleData.capacity
        local maxHeight = 32 * ( capacity / common.staticConfigs.capacities.MAX)

        local indicatorBlock = e.element:createThinBorder()
        indicatorBlock.consumeMouseEvents = false
        indicatorBlock.absolutePosAlignX = 0.1
        indicatorBlock.absolutePosAlignY = 1.0
        indicatorBlock.width = 8
        indicatorBlock.height = maxHeight
        indicatorBlock.paddingAllSides = 2

        local levelIndicator = indicatorBlock:createImage({ path = "textures/menu_bar_blue.dds" })

        --Add brown tinge to dirty water
        if e.itemData then
            if e.itemData.data.waterType == "dirty" then
                levelIndicator.color = { 0.8, 0.6, 0.5 }
            elseif teaConfig.teaTypes[e.itemData.data.waterType] then
                levelIndicator.color = teaConfig.tooltipColor
            elseif e.itemData.data.stewLevels then
                levelIndicator.color = { 0.9, 0.7, 0.4 }
            end
        end

        levelIndicator.consumeMouseEvents = false
        levelIndicator.width = 6
        levelIndicator.height = maxHeight * ( liquidLevel / capacity )
        levelIndicator.scaleMode = true
        levelIndicator.absolutePosAlignY = 1.0
    end

    if foodConfig.getGrillValues(e.item.id) then
        local maxHeight = 32

        local indicatorBlock = e.element:createThinBorder()
        indicatorBlock.consumeMouseEvents = false
        indicatorBlock.absolutePosAlignX = 0.1
        indicatorBlock.absolutePosAlignY = 1.0
        indicatorBlock.width = 8
        indicatorBlock.height = maxHeight
        indicatorBlock.paddingAllSides = 2

        --Food shows cooked amount
        local hasCookedValue = (
            e.itemData and 
            e.itemData.data and 
            e.itemData.data.cookedAmount and 
            e.itemData.data.cookedAmount > 0
        )
        if hasCookedValue then
            local cookedAmount =  e.itemData.data.cookedAmount
            local capacity = 100
            
            local indicatorImage = "textures/menu_bar_red.dds"
            if e.itemData.data.grillState == "burnt" then
                indicatorImage = "textures/menu_bar_gray.dds"
            end
            local levelIndicator = indicatorBlock:createImage({ path = indicatorImage })

            levelIndicator.consumeMouseEvents = false
            levelIndicator.width = 6
            levelIndicator.height = maxHeight * ( cookedAmount / capacity )
            levelIndicator.scaleMode = true
            levelIndicator.absolutePosAlignY = 1.0
        end

    end
end

event.register( "itemTileUpdated", updateFoodAndWaterTile )

local function onMenuInventorySelectMenu(e)
    local scrollpane = e.menu:findChild(tes3ui.registerID("MenuInventorySelect_scrollpane"))
    local itemList = e.menu:findChild(tes3ui.registerID("PartScrollPane_pane"))
    
    --Disable UI EXP filtering for tea brewing and grilling
    if common.data.inventorySelectTeaBrew or common.data.inventorySelectStew then
        local uiEXPFilterID = tes3ui.registerID("UIEXP:FiltersearchBlock")
        local filterBlock = e.menu:findChild(uiEXPFilterID)
        if filterBlock then filterBlock.parent.parent.visible = false end
    end

    for _, block in pairs(itemList.children) do

        local obj = block:getPropertyObject("MenuInventorySelect_object")
        local itemData = block:getPropertyObject("MenuInventorySelect_extra", "tes3itemData")

        local tileID = tes3ui.registerID("MenuInventorySelect_icon_brick")
        local iconBlock = block:findChild(tileID)
        local textID = tes3ui.registerID("MenuInventorySelect_item_brick")
        local textBlock = block:findChild(textID)


        updateFoodAndWaterTile{ item = obj, itemData = itemData, element = iconBlock}

        -- if common.data.inventorySelectTeaBrew then
        --     local teaData = teaConfig.teaTypes[obj.id:lower()]
        --     local itemText = block:findChild(tes3ui.registerID("MenuInventorySelect_item_brick"))
        --     itemText.text = teaData.teaName
        -- end

    end
    timer.frame.delayOneFrame(function()
        e.menu:updateLayout()
    end)
end
event.register("menuEnter", onMenuInventorySelectMenu, { filter = "MenuInventorySelect"})

local function createNeedsTooltip(e)
    local tooltip = e.tooltip
    if not e.tooltip then
        return
    end
    if not e.object then
        return
    end

    --Food tooltips
    local labelText
    if e.object.objectType == tes3.objectType.ingredient then
        if common.config.getConfig().enableHunger  then
            --hunger value
            local nutrition = hungerController.getNutrition(e.object, e.itemData)
            if nutrition and nutrition ~= 0 then
                labelText = string.format("Nutrition: %d", nutrition)
                createTooltip(tooltip, labelText)
            end

            --cook state
            local thisFoodType = foodConfig.getFoodType(e.object.id)

            --Remove cook state from the ingredient name for TR foods
            local cookStrings = {
                "raw ",
                "cooked ",
                "grilled ",
                "roasted "
            }
            local nameLabel = e.tooltip:findChild(tes3ui.registerID("HelpMenu_name"))
            for _, pattern in ipairs(cookStrings) do
                if string.startswith(nameLabel.text:lower(), pattern) then
                    nameLabel.text = nameLabel.text:sub(string.len(pattern) + 1, -1)
                end
            end

            --Add Food type and Cook state label to Tooltip
            local cookedLabel = ""
            if foodConfig.getGrillValues(e.object.id) then
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
            createTooltip(tooltip, foodTypeLabel)

        end

        --Meat disease/blight
        if common.config.getConfig().enableDiseasedMeat then
            if e.itemData and e.itemData.data.mer_disease then
                local diseaseLabel
                local diseaseType = e.itemData.data.mer_disease.spellType
                if diseaseType == tes3.spellType.disease then
                    diseaseLabel = "Diseased"
                elseif diseaseType == tes3.spellType.blight then
                    diseaseLabel = "Blighted"
                end
                if diseaseLabel then
                    createTooltip(tooltip, diseaseLabel, tes3ui.getPalette("negative_color"))
                end
            end
        end
    end

    --Water tooltips
    if common.config.getConfig().enableThirst then
        local bottleData = thirstController.getBottleData(e.object.id)
        if bottleData then
            local liquidLevel = e.itemData and e.itemData.data.waterAmount or 0


            --Dirty Water
            if e.itemData and e.itemData.data.waterType == "dirty" then
                labelText = string.format('Water: %d/%d (Dirty)', math.ceil(liquidLevel), bottleData.capacity)
            --Tea
            elseif e.itemData and teaConfig.teaTypes[e.itemData.data.waterType] then
                local teaName = teaConfig.teaTypes[e.itemData.data.waterType].teaName
                labelText = string.format('%s: %d/%d', teaName, math.ceil(liquidLevel), bottleData.capacity)

                --Tea description
                local effectBlock = createTooltip(tooltip)
                effectBlock.borderAllSides = 6
                effectBlock.childAlignX = 0.5
                effectBlock.autoHeight = true
                effectBlock.widthProportional = 1.0
                effectBlock.flowDirection = "left_to_right"

                local icon = effectBlock:createImage{ path = "Icons/ashfall/spell/teaBuff.dds" }
                icon.height = 16
                icon.width = 16
                icon.scaleMode = true

                local effectText = teaConfig.teaTypes[e.itemData.data.waterType].effectDescription
                local effectLabel = effectBlock:createLabel{ text = effectText }
                effectLabel.borderLeft = 5
            
            --Stew
            elseif e.itemData and e.itemData.data.stewLevels then
                labelText = string.format('Stew: %d/%d', math.ceil(liquidLevel), bottleData.capacity)
                for foodType, ingredLevel in pairs(e.itemData.data.stewLevels) do
                    local value = math.min(ingredLevel, 100)
                    local stewBuff = foodConfig.getStewBuffForFoodType(foodType)
                    local spell = tes3.getObject(stewBuff.id)
                    local effect = spell.effects[1]

                    

                    local outerBlock = createTooltip(tooltip)
                    local block = outerBlock:createBlock{}
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
                    local duration = common.helper.calculateStewBuffDuration() * (math.ceil(liquidLevel)/100)
                    local hoursText = string.format("for %d hour%s", duration, (duration >= 2 and "s" or "") )

                    local ingredLabel = block:createLabel{text = string.format("%s %s %s", effectNameText, pointsText, hoursText) }
                    ingredLabel.wrapText = false
                    ingredLabel.borderLeft = 4

                end
            --Regular Water
            else
                labelText = string.format('Water: %d/%d', math.ceil(liquidLevel), bottleData.capacity)
            end

            createTooltip(tooltip, labelText)


            local icon = e.tooltip:findChild(tes3ui.registerID("HelpMenu_icon"))
            if icon then
                updateFoodAndWaterTile{
                    itemData = e.itemData,
                    element = icon, 
                    item = e.object
                }
            end
        end
    end
end

event.register('uiObjectTooltip', createNeedsTooltip)


local function teaBrewingTooltip(e)
    local tooltip = e.tooltip:getContentElement()

    --Tea brewing tooltips
    if common.data.inventorySelectTeaBrew then
        local teaData = teaConfig.teaTypes[e.object.id:lower()]
        if teaData then

            --Remove everything already there
            for i = 2, #tooltip.children do
                tooltip.children[i].visible = false
            end
            tooltip.children[1].text = teaData.teaName or tooltip.children[1].text

            local textBlock = tooltip:createBlock{ id = tes3ui.registerID("Ashfall:TeaDescription")}
            textBlock.flowDirection = "top_to_bottom"
            --textBlock.maxWidth = 310
            textBlock.paddingAllSides = 6
            textBlock.autoHeight = true
            textBlock.autoWidth = true


            local teaDescription = textBlock:createLabel{ text = teaData.teaDescription }
            teaDescription.wrapText = true
            teaDescription.maxWidth = 300

            --Tea description
            local effectBlock = textBlock:createBlock()
            effectBlock.borderAllSides = 6
            effectBlock.childAlignX = 0.5
            effectBlock.autoHeight = true
            effectBlock.widthProportional = 1.0
            effectBlock.flowDirection = "left_to_right"

            local icon = effectBlock:createImage{ path = "Icons/ashfall/spell/teaBuff.dds" }
            icon.height = 16
            icon.width = 16
            icon.scaleMode = true

            local effectText = teaData.effectDescription
            local effectLabel = effectBlock:createLabel{ text = effectText }
            effectLabel.borderLeft = 5
        end
    end
end

event.register("uiObjectTooltip", teaBrewingTooltip, { priority = -101})
