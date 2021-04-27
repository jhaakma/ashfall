local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
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
    return math.floor(config.stewBaseCost * dispEffect * personalityEffect)
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

                if menuDialog then
                    tes3ui.leaveMenuMode()
                    menuDialog:destroy()
                end
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

local function updateStewServiceButton(e)
    timer.frame.delayOneFrame(function()

        local menuDialog = tes3ui.findMenu(GUID_MenuDialog)
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
        common.log:debug("Actor is an innkeeper, adding Fill Stew Service")
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