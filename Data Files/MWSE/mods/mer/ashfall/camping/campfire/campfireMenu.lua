local common = require ("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")

--[[
    No longer just for campfires!

    Mapping of which buttons can appear for each part of the campfire selected
]]

local function getDisabledText(disabledText, campfire)
    if type(disabledText) == "function" then
        return disabledText(campfire)
    else
        return disabledText
    end
end

local function onActivateCampfire(e)

    local campfire = e.ref
    local node = e.node
    local attachmentConfig = CampfireUtil.getAttachmentConfig(node)
    if not attachmentConfig then return end

    if attachmentConfig.command then
        --Execute command
        attachmentConfig.command(campfire)
        return
    end


    local inputController = tes3.worldController.inputController
    local isModifierKeyPressed = inputController:isKeyDown(config.modifierHotKey.keyCode)

    if isModifierKeyPressed and attachmentConfig.shiftCommand then
        local buttonData = require(string.format("mer.ashfall.camping.menuFunctions.%s", attachmentConfig.shiftCommand))
        local canShow = true
        if buttonData.showRequirements then
            canShow = buttonData.showRequirements(campfire)
        end
        local canEnable = true
        if buttonData.enableRequirements then
            canEnable = buttonData.enableRequirements(campfire)
        end
        if (canShow and canEnable) then
            buttonData.callback(campfire)
        elseif buttonData.tooltipDisabled and canShow then
            tes3.messageBox(buttonData.tooltipDisabled.text)
        end
        return
    end
    local function addButton(tbl, buttonData)
        local showButton = (
            buttonData.showRequirements == nil or
            buttonData.showRequirements(campfire)
        )
        if showButton then
            local text
            if type(buttonData.text) == "function" then
                text = buttonData.text(campfire)
            else
                text = buttonData.text
            end
            table.insert(tbl, {
                text = text,
                callback = function()
                    if buttonData.callback then
                        buttonData.callback(campfire)
                    end
                    event.trigger("Ashfall:registerReference", { reference = campfire})
                end,
                tooltip = buttonData.tooltip,
                tooltipDisabled = getDisabledText(buttonData.tooltipDisabled, campfire),
                requirements = function()
                    return (
                        buttonData.enableRequirements == nil or
                        buttonData.enableRequirements(campfire)
                    )
                end,
                doesCancel = buttonData.doesCancel
            })
        end
    end


    local buttons = {}
    --Add contextual buttons
    local buttonList = attachmentConfig.commands

    local text = CampfireUtil.getAttachmentName(campfire, attachmentConfig) or e.activator.name

    if buttonList then
        for _, buttonType in ipairs(buttonList) do
            local buttonData = require(string.format("mer.ashfall.camping.menuFunctions.%s", buttonType))
            addButton(buttons, buttonData)
        end

        common.helper.messageBox({
            message = text,
            buttons = buttons,
            doesCancel = true
        })
    end
end

event.register(
    "Ashfall:ActivatorActivated",
    onActivateCampfire
)