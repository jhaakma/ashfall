local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")
local teaConfig = common.staticConfigs.teaConfig
local hungerController = require('mer.ashfall.needs.hungerController')
local thirstController = require('mer.ashfall.needs.thirstController')
local foodConfig = common.staticConfigs.foodConfig
local cookingTooltips = require("mer.ashfall.ui.cookingTooltips")

local function updateFoodTile(e)
    if foodConfig.getGrillValues(e.item) then
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

local function updateWaterTile(e)
   --bottles show water amount
   local bottleData = thirstController.getBottleData(e.item.id)
   if bottleData then
       local liquidLevel = e.itemData and e.itemData.data.waterAmount or 0
       local capacity = bottleData.capacity
       local maxHeight = 32 * math.max(0.33, capacity / common.staticConfigs.capacities.MAX)

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
           --Make the icon more red if it's hot
           if e.itemData.data.waterHeat and e.itemData.data.waterHeat > common.staticConfigs.hotWaterHeatValue then
               indicatorBlock.color = {1, 0, 0}
           end
       end

       levelIndicator.consumeMouseEvents = false
       levelIndicator.width = 6
       levelIndicator.height = maxHeight * (liquidLevel / capacity )
       levelIndicator.scaleMode = true
       levelIndicator.absolutePosAlignY = 1.0
   end
end

--Adds fillbar showing how much water is left in a bottle.
--Height of fillbar border based on capacity of bottle.
local function updateFoodAndWaterTile(e)
    if not common.data then return end
    updateFoodTile(e)
    updateWaterTile(e)
end
event.register( "itemTileUpdated", updateFoodAndWaterTile )

local function onMenuInventorySelectMenu(e)
    local scrollpane = e.menu:findChild(tes3ui.registerID("MenuInventorySelect_scrollpane"))
    local itemList = e.menu:findChild(tes3ui.registerID("PartScrollPane_pane"))

    --Disable UI EXP filtering for tea brewing and grilling
    if common.data.inventorySelectTeaBrew or common.data.inventorySelectStew or common.data.inventorySelectTrinket then
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
    --timer.frame.delayOneFrame(function()
        e.menu:updateLayout()
    --end)
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

    --recalculate heat whenever you interact with it
    local bottleData = thirstController.getBottleData(e.object.id)
    if bottleData then
        local hasWaterAndHeat = e.itemData
            and e.itemData.data
            and e.itemData.data.waterAmount
            and e.itemData.data.waterHeat
            and e.itemData.data.waterHeat >= 1
        if hasWaterAndHeat then
            if not e.reference then
                --only update heat on tooltip when in inventory, otherwise it messes with the boilerController update
                CampfireUtil.updateWaterHeat(e.itemData.data, bottleData.capacity)
            end
        end
    end

    --used for item and campfire tooltips
    cookingTooltips(e.object, e.itemData, tooltip)

    local icon = e.tooltip:findChild(tes3ui.registerID("HelpMenu_icon"))
    if icon then
        updateFoodAndWaterTile{
            itemData = e.itemData,
            element = icon,
            item = e.object
        }
    end
    --Bellows
    local bellowsData = common.staticConfigs.bellows[e.object.id:lower()]
    if bellowsData then
        common.helper.addLabelToTooltip(tooltip,
            string.format("%sx Fuel burn", bellowsData.burnRateEffect) )
        common.helper.addLabelToTooltip(tooltip,
            string.format("%sx Heat", bellowsData.heatEffect) )
    end
    --Fuel Consumers
    if e.itemData and e.itemData.data.fuelLevel then
        common.helper.addLabelToTooltip(tooltip,
            string.format("Fuel: %.1f hours", e.itemData.data.fuelLevel) )
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
            teaDescription.maxWidth = 350

            --Tea description
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
end

event.register("uiObjectTooltip", teaBrewingTooltip, { priority = -101})
