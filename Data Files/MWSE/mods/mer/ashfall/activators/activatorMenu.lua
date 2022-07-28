local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("campfireMenu")
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")
local AttachConfig = require "mer.ashfall.activators.config.AttachConfig"
--[[
    No longer just for campfires!

    Mapping of which buttons can appear for each part of the campfire selected
]]

local function getDisabledText(disabledText, reference)
    if type(disabledText) == "function" then
        return disabledText(reference)
    else
        return disabledText
    end
end

local function resolveButtonData(buttonData)
    if type(buttonData) == "string" then
        return require(string.format("mer.ashfall.activators.menuFunctions.%s", buttonData))
    else
        return buttonData
    end
end

local function onActivatorActivated(e)
    local reference = e.ref
    if not reference then return end
    local node = e.node

    local attachmentConfig
    if node then
        attachmentConfig = CampfireUtil.getAttachmentConfig(reference, node)
    elseif e.attachmentConfig then
        attachmentConfig = e.attachmentConfig
    end

    if not attachmentConfig then return end

    if attachmentConfig.command then
        --Execute command
        attachmentConfig.command(reference)
        return
    end

    local isModifierKeyPressed = common.helper.isModifierKeyPressed()

    if isModifierKeyPressed and attachmentConfig.shiftCommand then
        local buttonData = resolveButtonData(attachmentConfig.shiftCommand)
        local canShow = true
        if buttonData.showRequirements then
            canShow = buttonData.showRequirements(reference)
        end
        local canEnable = true
        if buttonData.enableRequirements then
            canEnable = buttonData.enableRequirements(reference)
        end
        if (canShow and canEnable) then
            buttonData.callback(reference)
        elseif buttonData.tooltipDisabled and canShow then
            tes3.messageBox(buttonData.tooltipDisabled.text)
        end
        return
    end
    local function addButton(tbl, buttonData)
        local showButton = (
            buttonData.showRequirements == nil or
            buttonData.showRequirements(reference)
        )
        if showButton then
            local text
            if type(buttonData.text) == "function" then
                text = buttonData.text(reference)
            else
                text = buttonData.text
            end
            table.insert(tbl, {
                text = text,
                callback = function()
                    if buttonData.callback then
                        buttonData.callback(reference)
                        event.trigger("Ashfall:UpdateAttachNodes", { reference = reference})
                    end
                    event.trigger("Ashfall:registerReference", { reference = reference})
                end,
                tooltip = buttonData.tooltip,
                tooltipDisabled = getDisabledText(buttonData.tooltipDisabled, reference),
                enableRequirements = function()
                    return (
                        buttonData.enableRequirements == nil or
                        buttonData.enableRequirements(reference)
                    )
                end,
                cancels = buttonData.cancels
            })
        end
    end

    local buttons = {}
    --Add contextual buttons
    local buttonList = attachmentConfig.commands

    local attachmentName = CampfireUtil.getAttachmentName(reference, attachmentConfig)
    local text = attachmentName
        or reference.object.name

    if buttonList then
        for _, buttonData in ipairs(buttonList) do
            buttonData = resolveButtonData(buttonData)
            addButton(buttons, buttonData)
        end
        --if #buttons > 0 then
            tes3ui.showMessageMenu({
                message = text,
                buttons = buttons,
                cancels = true
            })
       -- end
    end
end

event.register("Ashfall:ActivatorActivated",onActivatorActivated)

event.register("activate", function(e)
    if tes3ui.menuMode() then return end
    if common.helper.isModifierKeyPressed() then return end
    local hasWater = e.target.data and e.target.data.waterAmount and e.target.data.waterAmount > 0
    local isUtensil = CampfireUtil.isUtensil(e.target)
    if isUtensil or hasWater then
        logger:debug("Activating water, triggering Menu")
        onActivatorActivated{
            ref = e.target,
            node = nil,
            attachmentConfig = AttachConfig.waterContainer
        }
        return false
    end
end, { filter = tes3.player })