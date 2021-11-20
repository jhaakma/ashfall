local common = require("mer.ashfall.common.common")
local merchantMenu = require('mer.ashfall.merchants.merchantMenu')
local config = require("mer.ashfall.config.config").config
local thirstController = require("mer.ashfall.needs.thirstController")


local dispMulti = 3.0
local personalityMulti = 2.0

local function getWaterCost(merchantObj)
    local disposition = math.min(merchantObj.disposition, 100)
    local personality = math.min(tes3.mobilePlayer.personality.current, 100)
    local dispEffect = math.remap(disposition, 0, 100, dispMulti, 1.0)
    local personalityEffect = math.remap(personality, 0, 100, personalityMulti, 1.0)
    return math.floor(config.waterBaseCost * dispEffect * personalityEffect)
end

local function getWaterText(merchantObj)
    local cost = getWaterCost(merchantObj)
    return string.format("Water Refill (%d gold)", cost)
end


local function onWaterServiceClick()
    common.log:debug("Activating water menu")
    local menuDialog = merchantMenu.getDialogMenu()
    local merchant = menuDialog:getPropertyObject("PartHyperText_actor")
    local cost = getWaterCost(merchant.object)

    if menuDialog then
        tes3ui.leaveMenuMode()
        menuDialog:destroy()
    end
    thirstController.fillContainer{ cost = cost }
end

local function getDisabled(cost)
    return tes3.getPlayerGold() < cost or not thirstController.playerHasEmpties()
end

local function makeTooltip()
    local menuDialog = merchantMenu.getDialogMenu()
    if not menuDialog then return end
    local merchant = menuDialog:getPropertyObject("PartHyperText_actor")
    local cost = getWaterCost(merchant.object)

    local tooltip = tes3ui.createTooltipMenu()
    local labelText = "Refill containers with water."

    if getDisabled(cost) then
        if tes3.getPlayerGold() < cost then
            labelText = "You do not have enough gold."
        else
            labelText = "You do not have any containers that need filling."
        end
    end
    local tooltipText = tooltip:createLabel{ text = labelText }
    tooltipText.wrapText = true
end

local function updateWaterServiceButton(e)
    timer.frame.delayOneFrame(function()
        local menuDialog = merchantMenu.getDialogMenu()
        if not menuDialog then return end
        local waterServiceButton = menuDialog:findChild(merchantMenu.guids.MenuDialog_WaterService)
        local merchant = merchantMenu.getMerchantObject()
        local cost = getWaterCost(merchant)
        if getDisabled(cost) then
            waterServiceButton.disabled = true
            waterServiceButton.widget.state = 2
        else
            waterServiceButton.disabled = false
        end
        waterServiceButton.text = getWaterText(merchant)
    end)
end


local function createWaterButton(menuDialog)
    local parent = merchantMenu.getButtonBlock()
    local merchant = merchantMenu.getMerchantObject()
    local button = parent:createTextSelect{
        id = merchantMenu.guids.MenuDialog_WaterService,
        text = getWaterText(merchant)
    }
    button.widthProportional = 1.0
    button:register("mouseClick", onWaterServiceClick)
    button:register("help", makeTooltip)
    menuDialog:registerAfter("update", updateWaterServiceButton)
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
        common.log:debug("Actor is an innkeeper, adding Fill Water Service")
        -- Create our new button.
        createWaterButton(menuDialog)
    end
end
event.register("uiActivated", onMenuDialogActivated, { filter = "MenuDialog", priority = -99 } )