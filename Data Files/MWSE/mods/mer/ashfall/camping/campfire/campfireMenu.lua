local common = require ("mer.ashfall.common.common")

--[[
    Mapping of which buttons can appear for each part of the campfire selected
]]
local buttonMapping = {
    ["Grill"] = {
        "removeGrill",
        "cancel"
    },
    ["Cooking Pot"] = {
        "drink",
        "fillContainer",
        "eatStew",
        "companionEatStew",
        "addIngredient",
        "addWater",
        "emptyPot",
        "removePot",
        "cancel",
    },
    ["Kettle"] = {
        "drink",
        "brewTea",
        "addWater",
        "fillContainer",
        "emptyKettle",
        "removeKettle",
        "cancel",
    },
    ["Supports"] = {
        "addKettle",
        "addPot",
        "removeKettle",
        "removePot",
        "removeSupports",
        "cancel",
    },
    ["Campfire"] = {
        "addFirewood",
        "lightFire",
        "addSupports",
        "removeSupports",
        "addGrill",
        "removeGrill",
        "addKettle",
        "addPot",
        "removeKettle",
        "removePot",
        "wait",
        "extinguish",
        "destroy",
        "cancel"
    }
}

local function onActivateCampfire(e)

    local campfire = e.ref
    local node = e.node

    local addButton = function(tbl, button)
        if button.requirements(campfire) then
            table.insert(tbl, {
                text = button.text, 
                callback = function()
                    button.callback(campfire)
                    event.trigger("Ashfall:registerReference", { reference = campfire})
                end
            })
        end
    end

    local buttons = {}
    --Add contextual buttons
    local buttonList = buttonMapping.Campfire
    local text = "Campfire"
    --If looking at an attachment, show buttons for it instead
    if buttonMapping[node.name] then
        buttonList = buttonMapping[node.name]
        text = node.name
    end

    for _, buttonType in ipairs(buttonList) do
        local button = require(string.format("mer.ashfall.camping.menuFunctions.%s", buttonType))
        addButton(buttons, button)
    end
    common.helper.messageBox({ message = text, buttons = buttons })
end

event.register(
    "Ashfall:ActivatorActivated", 
    onActivateCampfire, 
    { filter = common.staticConfigs.activatorConfig.types.campfire } 
)