local common = require("mer.ashfall.common.common")
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
    return math.floor(common.config.getConfig().waterBaseCost * dispEffect * personalityEffect)
end

local function getWaterText(merchantObj)
    local cost = getWaterCost(merchantObj)
    return string.format("Refill (%d gold)", cost)
end

local skipUpdate

local function onWaterServiceClick()
    common.log:debug("Activating water menu")
    skipUpdate = true
    local menuDialog = tes3ui.findMenu(GUID_MenuDialog)
    local merchant = menuDialog:getPropertyObject("PartHyperText_actor")
    local cost = getWaterCost(merchant.object)

    tes3ui.leaveMenuMode()
    menuDialog:destroy()
    thirstController.fillContainer{ cost = cost }
end

local function getDisabled(cost)
    --first check player can afford
    if tes3.getPlayerGold() < cost then return true end

    --then check bottles are available
    for stack in tes3.iterate(tes3.player.object.inventory.iterator) do
        local bottleData = thirstController.getBottleData(stack.object.id)
        if bottleData then
            common.log:debug("Found a bottle")
            if stack.variables then
                common.log:debug("Has data")
                if #stack.variables < stack.count then 
                    common.log:debug("Some bottles have no data")
                    return false
                end

                for _, itemData in pairs(stack.variables) do
                    common.log:debug("itemData: %s", itemData)
                    common.log:debug("waterAmount: %s", itemData and itemData.data.waterAmount )
                    if itemData.data.waterAmount then
                        if itemData.data.waterAmount < bottleData.capacity then
                            --at least one bottle can be filled
                            common.log:debug("below capacity")
                            return false
                        end
                    else
                        --no itemdata means empty bottle
                        common.log:debug("no waterAmount")
                        return false
                    end
                end
            else
                --no itemdata means empty bottle
                common.log:debug("no variables")          
                return false
            end
        end
    end
    common.log:debug("No bottles found")
    return true
end

local function makeTooltip(e)
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

local skipUpdateWaterServiceButtonCallback = false
local function updateWaterServiceButton(e)
    if (skipUpdateWaterServiceButtonCallback) then
        skipUpdateWaterServiceButtonCallback = false
        return
    end

    local menuDialog = e.source
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

    -- The UI here is really borked. The only fix found is to update the top-level element.
    -- We want to block this from causing an infinite loop though, so we block the next call to this callback.
    skipUpdateWaterServiceButtonCallback = true
    menuDialog:updateLayout()
end



local function onMenuDialogActivated(e)
    local config = common.config.getConfig()
    if config.enableThirst ~= true then return end
    
    common.log:debug("Dialog menu entered")
    local menuDialog = tes3ui.findMenu(GUID_MenuDialog)
    -- Get the actor that we're talking with.
	local mobileActor = menuDialog:getPropertyObject("PartHyperText_actor")
    local actor = mobileActor.reference.object.baseObject
    
    common.log:debug("Actor: %s", actor.name)
    local isPublican = ( 
        actor.class and actor.class.id == "Publican" or
        config.foodWaterMerchants[actor.id:lower()]
    )
    if isPublican then
        common.log:debug("Actor is a publican, adding Fill Water Service")
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