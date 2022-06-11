---@class CustomMessageBox_Tooltip
---@field header string|function The header at the top of the tooltip. Can also be a function that returns a string.
---@field text string|function The text in the body of the tooltip. Can also be a function that returns a string.

---@class CustomMessageBox_Button
---@field text string|function **Required** The label on the button. Can also be a function that returns a string.
---@field showRequirements function If set, the button will only be visible if this function returns true.
---@field enableRequirements function function that, if provided, determines whether the button will be call the callback when clicked, or be disabled + greyed out.
---@field callback function The function to call when this button is clicked.
---@field tooltipEnabled CustomMessageBox_Tooltip|function table with header and text that will display as a tooltip when an enabled button is hovered over. Can also be a function that returns a CustomMessageBox_Tooltip
---@field tooltipDisabled CustomMessageBox_Tooltip|function table with header and text that will display as a tooltip when a disabled button is hovered over. Can also be a function that returns a CustomMessageBox_Tooltip

---@class CustomMessageBox_Data
---@field message string|function **Required** The message at the top of the messagebox. Can also be a function that returns a string.
---@field buttons CustomMessageBox_Button[] **Required** The list of buttons.
---@field header string|function The optional header displayed above the message. Can also be a function that returns a string.
---@field maxButtons number Number of buttons displayed per page. Default is 30.
---@field doesCancel boolean When set to true, a cancel button is automatically added to the buttom of the list, even when paginated.
---@field cancelCallback function function to call when the user clicks the cancel button.
---@field callbackParams table The table of parameters to pass to the callback functions.

---@class CustomMessageBox_PopulateButtons_Data
---@field buttons CustomMessageBox_Button[]
---@field buttonsBlock tes3uiElement
---@field menu tes3uiElement
---@field startIndex number
---@field endIndex number
---@field callbackParams table

local uiids = {
    messageBox = tes3ui.registerID("CustomMessageBox"),
    message = tes3ui.registerID("MessageBox_Message"),
    button = tes3ui.registerID("CustomMessageBox_Button"),
    cancelButton = tes3ui.registerID("CustomMessageBox_CancelButton"),
    header = tes3ui.registerID("MessageBox_Header")
}

---@param text string|function The message to display. If a function is provided, it will be called to get the message.
---@return string
local function resolveText(text)
    return (type(text) == "function") and text() or text
end

---@param button tes3uiElement
local function enable(button)
    button.disabled = false
    button.widget.state = 1
    button.color = tes3ui.getPalette("normal_color")
end

---@param button tes3uiElement
local function disable(button)
    button.disabled = true
    button.widget.state = 2
    button.color = tes3ui.getPalette("disabled_color")
end

---@param e CustomMessageBox_Tooltip
local function createTooltip(e)
    if type(e) == "function" then
        e = e()
    end
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
    if e.header then
        local headerText = resolveText(e.header)
        local headerLabel = outerBlock:createLabel({ text = headerText })
        headerLabel.autoHeight = true
        headerLabel.width = 285
        headerLabel.color = tes3ui.getPalette("header_color")
        headerLabel.wrapText = true
    end
    if e.text then
        local descriptionText = resolveText(e.text)
        local descriptionLabel = outerBlock:createLabel({ text = descriptionText })
        descriptionLabel.autoHeight = true
        descriptionLabel.width = 285
        descriptionLabel.wrapText = true
    end
    tooltip:updateLayout()
end

local function doAddButton(buttonData, callbackParams)
    if buttonData.showRequirements then
        return buttonData.showRequirements(callbackParams)
    else
        return true
    end
end

---@param buttonData CustomMessageBox_Button
---@param e CustomMessageBox_PopulateButtons_Data
local function addButton(buttonData, e)
    if doAddButton(buttonData, e.callbackParams) then
        local button = e.buttonsBlock:createButton { id = uiids.button, text = resolveText(buttonData.text) }
        local enabled
        if buttonData.enableRequirements then
            enabled = buttonData.enableRequirements(e.callbackParams)
        else
            enabled = true
        end
        if enabled then
            button:register("mouseClick", function()
                if buttonData.callback then
                    buttonData.callback(e.callbackParams)
                end
                tes3ui.leaveMenuMode()
                e.menu:destroy()
            end)
        else
            disable(button)
        end
        --Show tooltips
        if enabled and buttonData.tooltipEnabled then
            button:register("help", function()
                createTooltip(buttonData.tooltipEnabled)
            end)
        elseif (not enabled) and buttonData.tooltipDisabled then
            button:register("help", function()
                createTooltip(buttonData.tooltipDisabled)
            end)
        end
    end
end

---@param e CustomMessageBox_PopulateButtons_Data
local function populateButtons(e)
    e.buttonsBlock:destroyChildren()
    for i = e.startIndex, math.min(e.endIndex, #e.buttons) do
        local buttonData = e.buttons[i]
        addButton(buttonData, e)
    end
    e.menu:updateLayout()
end

---@param params CustomMessageBox_Data
local function messageBox(params)
    --create menu
    local menu = tes3ui.createMenu { id = uiids.messageBox, fixedFrame = true }
    menu:getContentElement().maxWidth = 400
    menu:getContentElement().childAlignX = 0.5
    tes3ui.enterMenuMode(uiids.messageBox)
    --header
    if params.header then
        local label = menu:createLabel {
            id = uiids.header,
            text = resolveText(params.header)
        }
        label.color = tes3ui.getPalette("header_color")
    end
    --message
    if params.message then
        local label = menu:createLabel {
            id = uiids.message,
            text = resolveText(params.message)
        }
        label.wrapText = true
    end
    --create button block
    local buttonsBlock = menu:createBlock()
    do
        buttonsBlock.flowDirection = "top_to_bottom"
        buttonsBlock.autoHeight = true
        buttonsBlock.autoWidth = true
        buttonsBlock.childAlignX = 0.5
    end

    --populate initial buttons
    local buttons = params.buttons
    local maxButtonsPerColumn = params.maxButtons or 30
    local startIndex, endIndex = 1, maxButtonsPerColumn
    local callbackParams = params.callbackParams

    populateButtons {
        buttons = buttons,
        menu = menu,
        buttonsBlock = buttonsBlock,
        startIndex = startIndex,
        endIndex = endIndex,
        callbackParams = callbackParams
    }

    --add next/previous buttons
    if #buttons > maxButtonsPerColumn then
        local arrowButtonsBlock = menu:createBlock()
        arrowButtonsBlock.flowDirection = "left_to_right"
        arrowButtonsBlock.borderTop = 4
        arrowButtonsBlock.autoHeight = true
        arrowButtonsBlock.autoWidth = true

        local prevButton = arrowButtonsBlock:createButton { text = "<-Prev" }
        disable(prevButton)
        local nextButton = arrowButtonsBlock:createButton { text = "Next->" }

        prevButton:register("mouseClick", function()
            --move start index back, check if disable prev button
            startIndex = startIndex - maxButtonsPerColumn
            if startIndex <= 1 then
                disable(prevButton)
            end

            --move endIndex back, check if enable next button
            endIndex = endIndex - maxButtonsPerColumn
            if endIndex <= #buttons then
                enable(nextButton)
            end

            populateButtons {
                buttons = buttons,
                menu = menu,
                buttonsBlock = buttonsBlock,
                startIndex = startIndex,
                endIndex = endIndex,
                callbackParams = callbackParams
            }
        end)

        nextButton:register("mouseClick", function()
            --move start index forward, check if enable prev  button
            startIndex = startIndex + maxButtonsPerColumn
            if startIndex >= 1 then
                enable(prevButton)
            end

            --move endIndex forward, check if disable next button
            endIndex = endIndex + maxButtonsPerColumn
            if endIndex >= #buttons then
                disable(nextButton)
            end

            populateButtons {
                buttons = buttons,
                menu = menu,
                buttonsBlock = buttonsBlock,
                startIndex = startIndex,
                endIndex = endIndex,
                callbackParams = callbackParams
            }
        end)
    end

    -- add cancel button
    if params.doesCancel then
        local buttonId = uiids.cancelButton
        local cancelButton = menu:createButton { id = buttonId, text = tes3.findGMST(tes3.gmst.sCancel).value }
        cancelButton:register("mouseClick", function()
            if params.cancelCallback then
                params.cancelCallback(callbackParams)
            end
            tes3ui.leaveMenuMode()
            menu:destroy()
        end)
    end
    menu:updateLayout()
end

return messageBox
