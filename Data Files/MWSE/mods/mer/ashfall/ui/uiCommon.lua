local uiCommon = {}

local id_indicator = tes3ui.registerID("Ashfall:activatorTooltip")
local id_contents = tes3ui.registerID("Ashfall:activatorTooltipContents")
local id_label = tes3ui.registerID("Ashfall:activatorTooltipLabel")
local icon_block = tes3ui.registerID("Ashfall:activatorTooltipIconBlock")

function uiCommon.getTooltip()
    local MenuMulti = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    return MenuMulti:findChild(id_indicator)
end

function uiCommon.getTooltipContentsBlock()
    local MenuMulti = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    return MenuMulti:findChild(id_contents)
end

function uiCommon.getTooltipHeader()
    local tooltip = uiCommon.getTooltip()
    return tooltip:findChild(id_label)
end

function uiCommon.getTooltipIconBlock()
    local tooltip = uiCommon.getTooltip()
    return tooltip:findChild(icon_block)
end

function uiCommon.createOrUpdateTooltipMenu(headerText)
    local MenuMulti = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    local tooltipMenu = MenuMulti:findChild(id_indicator)
        or MenuMulti:createBlock{ id = id_indicator }
    tooltipMenu.visible = true
    tooltipMenu:destroyChildren()
    tooltipMenu.absolutePosAlignX = 0.5
    tooltipMenu.absolutePosAlignY = 0.03
    tooltipMenu.autoHeight = true
    tooltipMenu.autoWidth = true
    local labelBackground = tooltipMenu:createRect({color = {0, 0, 0}})
    labelBackground.autoHeight = true
    labelBackground.autoWidth = true
    local labelBorder = labelBackground:createThinBorder({id = id_contents })
    labelBorder.autoHeight = true
    labelBorder.autoWidth = true
    labelBorder.childAlignX = 0.5
    labelBorder.paddingAllSides = 10
    labelBorder.flowDirection = "top_to_bottom"
    local headerBlock = labelBorder:createBlock()
    headerBlock.autoHeight = true
    headerBlock.autoWidth = true
    headerBlock.flowDirection = "left_to_right"
    headerBlock.childAlignY = 0.5
    local iconBlock = headerBlock:createBlock{ id = icon_block }
    iconBlock.autoHeight = true
    iconBlock.autoWidth = true
    local header = headerBlock:createLabel{ id = id_label, text = headerText or "" }
    header.autoHeight = true
    header.autoWidth = true
    header.color = tes3ui.getPalette("header_color")

    return labelBorder
end


function uiCommon.disableTooltipMenu()
    local tooltipMenu = uiCommon.getTooltip()
    if tooltipMenu then
        tooltipMenu.visible = false
    end
end

function uiCommon.addIconToHeader(iconPath)
    local iconBlock = uiCommon.getTooltipIconBlock()
    if iconBlock then
        iconBlock:destroyChildren()
        local icon = iconBlock:createImage({ path=("icons\\" .. iconPath) })
        icon.height = 32
        icon.width = 32
        icon.scaleMode = true
        icon.borderAllSides = 1
    end
end

function uiCommon.updateTooltipHeader(newText)
    local header = uiCommon.getTooltipHeader()
    if header then
        header.text = newText
    end
end

function uiCommon.addCenterLabel(e)
    local tooltipContents = uiCommon.getTooltipContentsBlock()
    if tooltipContents then
        local text = e.text
        local color = e.color
        local element = tooltipContents:createLabel{ text = text }
        element.autoHeight = true
        element.widthProportional = 1.0
        element.wrapText = true
        element.justifyText = "center"
        if color then
            element.color = tes3ui.getPalette(color)
        end
    end
end

return uiCommon