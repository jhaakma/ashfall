local common = require ("mer.ashfall.common.common")
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")

--[[
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
    local text = CampfireUtil.getAttachmentName(campfire, attachmentConfig)
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

event.register(
    "Ashfall:ActivatorActivated",
    onActivateCampfire,
    { filter = common.staticConfigs.activatorConfig.types.campfire }
)