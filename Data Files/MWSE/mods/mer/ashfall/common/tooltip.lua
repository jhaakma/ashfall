return function(e)
    local thisHeader, thisLabel = e.header, e.text
    local tooltip = tes3ui.createTooltipMenu()

    local outerBlock = tooltip:createBlock()
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.paddingTop = 6
    outerBlock.paddingBottom = 12
    outerBlock.paddingLeft = 6
    outerBlock.paddingRight = 6
    outerBlock.maxWidth = 300
    outerBlock.autoWidth = true
    outerBlock.autoHeight = true

    if thisHeader then
        local headerText = thisHeader
        local headerLabel = outerBlock:createLabel({text = headerText })
        headerLabel.autoHeight = true
        headerLabel.width = 285
        headerLabel.color = tes3ui.getPalette("header_color")
        headerLabel.wrapText = true
    end
    if thisLabel then
        local descriptionText = thisLabel
        local descriptionLabel = outerBlock:createLabel({text = descriptionText })
        descriptionLabel.autoHeight = true
        descriptionLabel.width = 285
        descriptionLabel.wrapText = true
    end

    tooltip:updateLayout()
end