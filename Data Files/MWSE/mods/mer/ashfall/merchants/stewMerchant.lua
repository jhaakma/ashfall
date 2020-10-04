local common = require("mer.ashfall.common.common")
local foodConfig = common.staticConfigs.foodConfig
local GUID_MenuDialog = tes3ui.registerID("MenuDialog")
local GUID_MenuDialog_TopicList = tes3ui.registerID("MenuDialog_topics_pane")
local GUID_MenuDialog_Divider = tes3ui.registerID("MenuDialog_divider")
local GUID_MenuDialog_StewService = tes3ui.registerID("MenuDialog_service_StewService")

local dispMulti = 3.0
local personalityMulti = 2.0

local function getStewCost(merchantObj)
    local disposition = math.min(merchantObj.disposition, 100)
    local personality = math.min(tes3.mobilePlayer.personality.current, 100)
    local dispEffect = math.remap(disposition, 0, 100, dispMulti, 1.0)
    local personalityEffect = math.remap(personality, 0, 100, personalityMulti, 1.0)
    return math.floor(common.config.getConfig().stewBaseCost * dispEffect * personalityEffect)
end


local function getStewMenuText(merchantObj)
    local cost = getStewCost(merchantObj)
    return string.format("Hot Meal (%d gold)", cost)
end


local function stewSelectMenu()
    local menuDialog = tes3ui.findMenu(GUID_MenuDialog)
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

                tes3ui.leaveMenuMode()
                menuDialog:destroy()
            end,
            tooltip = {
                header = string.format("%s %s", spell.name, stewName),
                text = data.tooltip
            }
        })
    end
    table.insert(buttons, { 
        text = "Cancel",
        callback = function()
            tes3ui.leaveMenuMode()
            menuDialog:destroy()
        end
    })
    common.helper.messageBox{ message = menuMessage, buttons = buttons}
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

local function makeTooltip(e)
    local menuDialog = tes3ui.findMenu(GUID_MenuDialog)
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

local skipUpdateStewServiceButtonCallback = false
local function updateStewServiceButton(e)
    if (skipUpdateStewServiceButtonCallback) then
        skipUpdateStewServiceButtonCallback = false
        return
    end

    local menuDialog = e.source
    if not menuDialog then return end

    local topicsScrollPane = menuDialog:findChild(GUID_MenuDialog_TopicList)
    local stewServiceButton = topicsScrollPane:findChild(GUID_MenuDialog_StewService)
    if not ( topicsScrollPane and stewServiceButton ) then
        return
    end

    local merchant = menuDialog:getPropertyObject("PartHyperText_actor")
    local cost = getStewCost(merchant.object)
    if getDisabled(cost) then
        stewServiceButton.disabled = true
        stewServiceButton.color = tes3ui.getPalette("disabled_color")
    else
        stewServiceButton.disabled = false
        stewServiceButton.color = tes3ui.getPalette("normal_color")
    end

    common.log:debug("Updating Stew Service Button")
    stewServiceButton.text = getStewMenuText(merchant.object)

    -- Reshow the button.
    stewServiceButton.visible = true
    topicsScrollPane.widget:contentsChanged()

    -- The UI here is really borked. The only fix found is to update the top-level element.
    -- We want to block this from causing an infinite loop though, so we block the next call to this callback.
    skipUpdateStewServiceButtonCallback = true
    --menuDialog:updateLayout()
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
        common.log:debug("Actor is a publican, adding Fill Stew Service")
        -- Create our new button.
        local topicsScrollPane = menuDialog:findChild(GUID_MenuDialog_TopicList)
        local divider = topicsScrollPane:findChild(GUID_MenuDialog_Divider)
        local topicsList = divider.parent
        local stewServiceButton = topicsList:createTextSelect({ id = GUID_MenuDialog_StewService, text = "" })
        
        topicsList:reorderChildren(divider, stewServiceButton, 1)
        stewServiceButton:register("mouseClick", onStewServiceClick)
        menuDialog:registerAfter("update", updateStewServiceButton)
        stewServiceButton:register("help", makeTooltip)
    end
end
event.register("uiActivated", onMenuDialogActivated, { filter = "MenuDialog", priority = -100 } )