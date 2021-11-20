local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local merchantMenu = require("mer.ashfall.merchants.merchantMenu")
local foodConfig = common.staticConfigs.foodConfig

local dispMulti = 3.0
local personalityMulti = 2.0

local function getStewCost(merchantObj)
    local disposition = math.min(merchantObj.disposition, 100)
    local personality = math.min(tes3.mobilePlayer.personality.current, 100)
    local dispEffect = math.remap(disposition, 0, 100, dispMulti, 1.0)
    local personalityEffect = math.remap(personality, 0, 100, personalityMulti, 1.0)
    return math.floor(config.stewBaseCost * dispEffect * personalityEffect)
end


local function getStewMenuText(merchantObj)
    local cost = getStewCost(merchantObj)
    return string.format("Hot Meal (%d gold)", cost)
end


local function stewSelectMenu()
    local menuDialog = merchantMenu.getDialogMenu()
    local merchant = menuDialog:getPropertyObject("PartHyperText_actor")

    local menuMessage = "Select a Meal"
    local buttons = {}
    for stewType, data in pairs(foodConfig.getStewBuffList()) do
        local spell = tes3.getObject(data.id)
        local stewName = data.notSoup and "Stew" or "Soup"
        table.insert(buttons, {
            text = string.format("%s %s", spell.name, stewName),
            callback = function()
                event.trigger("Ashfall:eatStew", {
                    data = {
                        stewLevels = {
                            [stewType] = 100
                        },
                        waterAmount = 100,
                        waterHeat = 100
                    }
                })
                local cost = getStewCost(merchant.object)
                mwscript.removeItem({ reference = tes3.player, item = "Gold_001", count = cost})
                --tes3.playSound{ reference = tes3.player, sound = "Item Gold Down"}

                -- if menuDialog then
                --     tes3ui.leaveMenuMode()
                --     menuDialog:destroy()
                -- end
            end,
            tooltip = {
                header = string.format("%s %s", spell.name, stewName),
                text = data.tooltip
            }
        })
    end

    common.helper.messageBox{ message = menuMessage, buttons = buttons, doesCancel = true}
end

local function onStewServiceClick()
    common.log:debug("Activating stew menu")
    stewSelectMenu()
end


local function isFull()
    local hunger = common.staticConfigs.conditionConfig.hunger:getValue()
    local thirst = common.staticConfigs.conditionConfig.thirst:getValue()
    if hunger < 1 and thirst < 1 then
        return true
    end
    return false
end

local function getDisabled(cost)
    --check player can afford
    if tes3.getPlayerGold() < cost then return true end
    if isFull() then return true end

    return false
end

local function makeTooltip()
    local menuDialog = merchantMenu.getDialogMenu()
    if not menuDialog then return end
    local merchant = menuDialog:getPropertyObject("PartHyperText_actor")
    local cost = getStewCost(merchant.object)

    local tooltip = tes3ui.createTooltipMenu()
    local labelText = "Purchase a stew or soup."

    if getDisabled(cost) then
        if isFull() then
            labelText = "You are full."
        else
            labelText = "You do not have enough gold."
        end
    end
    local tooltipText = tooltip:createLabel{ text = labelText }
    tooltipText.wrapText = true
end

local function updateStewServiceButton(e)
    timer.frame.delayOneFrame(function()
        local menuDialog = merchantMenu.getDialogMenu()
        if not menuDialog then return end

        local stewServiceButton = menuDialog:findChild(merchantMenu.guids.MenuDialog_StewService)

        local merchant = menuDialog:getPropertyObject("PartHyperText_actor")
        local cost = getStewCost(merchant.object)
        if getDisabled(cost) then
            stewServiceButton.disabled = true
            stewServiceButton.widget.state = 2
        else
            stewServiceButton.disabled = false
        end
        stewServiceButton.text = getStewMenuText(merchant.object)
    end)
end

local function createStewButton(menuDialog)
    local parent = merchantMenu.getButtonBlock()
    local merchant = merchantMenu.getMerchantObject()
    local button = parent:createTextSelect{
        id = merchantMenu.guids.MenuDialog_StewService,
        text = getStewMenuText(merchant)
    }
    button.widthProportional = 1.0
    button:register("mouseClick", onStewServiceClick)
    button:register("help", makeTooltip)
    menuDialog:registerAfter("update", updateStewServiceButton)
end


local function onMenuDialogActivated()
    if config.enableThirst ~= true then return end

    common.log:debug("Dialog menu entered")
    local menuDialog = merchantMenu.getDialogMenu()
    -- Get the actor that we're talking with.
	local mobileActor = menuDialog:getPropertyObject("PartHyperText_actor")
    local ref = mobileActor.reference

    common.log:debug("Actor: %s", ref.object.name)

    if common.isInnkeeper(ref) then
        common.log:debug("Actor is an innkeeper, adding Fill Stew Service")
        -- Create our new button.
        createStewButton(menuDialog)
    end
end
event.register("uiActivated", onMenuDialogActivated, { filter = "MenuDialog", priority = -100 } )