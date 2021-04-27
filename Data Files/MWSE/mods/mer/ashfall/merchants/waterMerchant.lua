local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local thirstController = require("mer.ashfall.needs.thirstController")
local GUID_MenuDialog = tes3ui.registerID("MenuDialog")
local GUID_MenuDialog_TopicList = tes3ui.registerID("MenuDialog_topics_pane")
local GUID_MenuDialog_Divider = tes3ui.registerID("MenuDialog_divider")
local GUID_MenuDialog_WaterService = tes3ui.registerID("MenuDialog_service_WaterService")

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
    return string.format("Refill (%d gold)", cost)
end


local function onWaterServiceClick()
    common.log:debug("Activating water menu")
    local menuDialog = tes3ui.findMenu(GUID_MenuDialog)
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
    local menuDialog = tes3ui.findMenu(GUID_MenuDialog)
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
        local menuDialog = tes3ui.findMenu(GUID_MenuDialog)
        if not menuDialog then return end
    
        local topicsScrollPane = menuDialog:findChild(GUID_MenuDialog_TopicList)
        local waterServiceButton = topicsScrollPane:findChild(GUID_MenuDialog_WaterService)
        if not ( topicsScrollPane and waterServiceButton ) then
            return
        end
    
        local merchant = menuDialog:getPropertyObject("PartHyperText_actor")
        local cost = getWaterCost(merchant.object)
        if getDisabled(cost) then
            waterServiceButton.disabled = true
            waterServiceButton.color = tes3ui.getPalette("disabled_color")
        else
            waterServiceButton.disabled = false
            waterServiceButton.color = tes3ui.getPalette("normal_color")
        end
    
        common.log:debug("Updating Water Service Button")
        waterServiceButton.text = getWaterText(merchant.object)
    
        -- Reshow the button.
        waterServiceButton.visible = true
        topicsScrollPane.widget:contentsChanged()
    end)
end



local function onMenuDialogActivated()
    if config.enableThirst ~= true then return end
    
    common.log:debug("Dialog menu entered")
    local menuDialog = tes3ui.findMenu(GUID_MenuDialog)
    -- Get the actor that we're talking with.
	local mobileActor = menuDialog:getPropertyObject("PartHyperText_actor")
    local ref = mobileActor.reference
    
    common.log:debug("Actor: %s", ref.object.name)

    if common.isInnkeeper(ref) then
        common.log:debug("Actor is an innkeeper, adding Fill Water Service")
        -- Create our new button.
        local topicsScrollPane = menuDialog:findChild(GUID_MenuDialog_TopicList)
        local divider = topicsScrollPane:findChild(GUID_MenuDialog_Divider)
        local topicsList = divider.parent
        local waterServiceButton = topicsList:createTextSelect({ id = GUID_MenuDialog_WaterService, text = "" })
        
        topicsList:reorderChildren(divider, waterServiceButton, 1)
        waterServiceButton:register("mouseClick", onWaterServiceClick)
        menuDialog:registerAfter("update", updateWaterServiceButton)
        waterServiceButton:register("help", makeTooltip)
    end
end
event.register("uiActivated", onMenuDialogActivated, { filter = "MenuDialog", priority = -100 } )