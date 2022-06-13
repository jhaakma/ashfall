local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("campfireMenu")
local config = require("mer.ashfall.config").config
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")
local AttachConfig = require "mer.ashfall.camping.campfire.config.AttachConfig"
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

    local attachmentConfig
    if node then
        attachmentConfig = CampfireUtil.getAttachmentConfig(campfire, node)
    elseif e.attachmentConfig then
        attachmentConfig = e.attachmentConfig
    end

    if not attachmentConfig then return end

    if attachmentConfig.command then
        --Execute command
        attachmentConfig.command(campfire)
        return
    end


    local inputController = tes3.worldController.inputController
    local isModifierKeyPressed = common.helper.isModifierKeyPressed()

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
                        event.trigger("Ashfall:UpdateAttachNodes", { campfire = campfire})
                    end
                    event.trigger("Ashfall:registerReference", { reference = campfire})
                end,
                tooltip = buttonData.tooltip,
                tooltipDisabled = getDisabledText(buttonData.tooltipDisabled, campfire),
                enableRequirements = function()
                    return (
                        buttonData.enableRequirements == nil or
                        buttonData.enableRequirements(campfire)
                    )
                end,
                cancels = buttonData.cancels
            })
        end
    end


    local buttons = {}
    --Add contextual buttons
    local buttonList = attachmentConfig.commands

    local attachmentName = CampfireUtil.getAttachmentName(campfire, attachmentConfig)
    local text = attachmentName
        or campfire.object.name

    if buttonList then
        for _, buttonType in ipairs(buttonList) do
            local buttonData = require(string.format("mer.ashfall.camping.menuFunctions.%s", buttonType))
            addButton(buttons, buttonData)
        end

        tes3ui.showMessageMenu({
            message = text,
            buttons = buttons,
            cancels = true
        })
    end
end

event.register(
    "Ashfall:ActivatorActivated",
    onActivateCampfire
)

event.register("activate", function(e)
    if tes3ui.menuMode() then return end
    if common.helper.isModifierKeyPressed() then return end
    local hasWater = e.target.data and e.target.data.waterAmount and e.target.data.waterAmount > 0
    local isUtensil = CampfireUtil.isUtensil(e.target)
    if isUtensil or hasWater then
        logger:debug("Activating water, triggering Menu")
        onActivateCampfire{
            ref = e.target,
            node = nil,
            attachmentConfig = AttachConfig.waterContainer
        }
        return false
    end
end, { filter = tes3.player })