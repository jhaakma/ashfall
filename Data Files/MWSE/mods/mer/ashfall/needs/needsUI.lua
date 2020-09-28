--[[
    Needs displayed in stats menu
]]--
local this = {}
local common = require("mer.ashfall.common.common")
local config = common.config.getConfig()
local conditionConfig = common.staticConfigs.conditionConfig

local function rgbToColor(r, g, b)
    return { (r/255), (g/255), (b/255) }
end

function this.showThirst()
    return (
        config.enableThirst and 
        config.thirstRate > 0
    )
end

function this.showHunger()
    return (
        config.enableHunger and 
        config.hungerRate > 0
    )
end

function this.showTiredness()
    return (
        config.enableTiredness and 
        config.loseSleepRate > 0
    )
end

this.UIData = {
    hunger = {
        blockID = tes3ui.registerID("Ashfall:hungerUIBlock"),
        fillBarID = tes3ui.registerID("Ashfall:hungerFillBar"),
        conditionID = tes3ui.registerID("Ashfall:hungerConditionId"),
        showUIFunction = this.showHunger,
        conditionTypes = conditionConfig.hunger.states,
        defaultCondition = "wellFed",
        need = "hunger",
        color = rgbToColor(230, 92, 0),
        name = "Hunger",
        getTooltip = function()
            return string.format (
                ( "Hunger drains faster when the player is cold. " ..
                "Eat food to reduce your hunger. Cook meat and vegetables on a " .. 
                "grill to increase their satiation value. " ..
                "\n\nYour current hunger level is %d%%. %s" ),
                conditionConfig.hunger:getValue(), 
                conditionConfig.hunger:getCurrentStateMessage())
        end,
    },
    thirst = {
        blockID = tes3ui.registerID("Ashfall:thirstUIBlock"),
        fillBarID = tes3ui.registerID("Ashfall:thirstFillBar"),
        conditionID = tes3ui.registerID("Ashfall:thirstConditionId"),
        showUIFunction = this.showThirst,
        conditionTypes = conditionConfig.thirst.states,
        need = "thirst",
        color = rgbToColor(0, 143, 179),
        name = "Thirst",
        getTooltip = function()
            return string.format(
                ("Thirst drains faster when the player is hot. " ..
                "Drink water to reduce your thirst. Make sure to boil dirty water before consuming. " ..
                "\n\nYour current thirst level is %d%%. %s"),
                conditionConfig.thirst:getValue(), 
                conditionConfig.thirst:getCurrentStateMessage())
        end,
    },
    tiredness = {
        blockID = tes3ui.registerID("Ashfall:sleepUIBlock"),
        fillBarID = tes3ui.registerID("Ashfall:sleepFillBar"),
        conditionID = tes3ui.registerID("Ashfall:sleepConditionId"),
        showUIFunction = this.showTiredness,
        conditionTypes = conditionConfig.tiredness.states,
        need = "tiredness",
        color = rgbToColor(0, 204, 0),
        name = "Tiredness",
        getTooltip = function()
            return string.format(
                ("Tiredness drains over time, and recovers while resting. " ..
                "Sleep in a bed or bedroll to recover tiredness faster. " ..
                "Your current tiredness level is %d%%. %s"), 
                conditionConfig.tiredness:getValue(), 
                conditionConfig.tiredness:getCurrentStateMessage())
        end,
    },
}
local needsBlockId = tes3ui.registerID("Ashfall:needsBlock")

local function updateNeedsBlock(menu, data)
    local need = conditionConfig[data.need]

    local block = menu:findChild(data.blockID)
    
    if not need:isActive() then
        block.visible = false
    else
        if block and block.visible == false then
            block.visible = true
        end
    end
    --Update Hunger
    local fillBar = menu:findChild(data.fillBarID)

    local conditionLabel = menu:findChild(data.conditionID)
    if fillBar and conditionLabel then

        --update condition
        conditionLabel.text =  need:getCurrentStateData().text
            
        --update fillBar
        local needsLevel
        needsLevel = need:getValue()
        fillBar.widget.current = need.max - needsLevel
    end
end


local function setupNeedsBlock(element)
    element.borderAllSides = -5
    element.borderLeft = 4
    element.borderRight = 4
    element.borderBottom = 4
    element.paddingTop = 0
    element.paddingLeft = 0
    element.paddingRight = 0
    element.paddingBottom = 0
    element.autoHeight = true
    element.autoWidth = true
    element.widthProportional = 1
    element.flowDirection = "top_to_bottom"
end


local function setupNeedsElementBlock(element)
    element.autoHeight = true
    element.autoWidth = true
    
    element.paddingBottom = 1
    element.widthProportional = 1
    element.flowDirection = "left_to_right"
end

local function setupNeedsBar(element)
    element.widget.showText = false
    element.height = 17
    element.widthProportional = 1.0
end

local function setupConditionLabel(element)
    element.absolutePosAlignX = 0.5
    element.borderAllSides = -2
    element.absolutePosAlignY = 0.0
    element.widthProportional = 1.0
end

local function createNeedsUI(e)
    local startingBlock = e.element:findChild(tes3ui.registerID("MenuInventory_character_box")).parent
    ---Needs Block
    
    local needsBlock = startingBlock:findChild(needsBlockId)
    if needsBlock then
        needsBlock:destroyChildren()
    else
        needsBlock = startingBlock:createThinBorder({id = needsBlockId})
    end  

    setupNeedsBlock(needsBlock)

    for _, needId in ipairs({"hunger", "thirst", "tiredness"}) do
        local data = this.UIData[needId]
        local need = conditionConfig[needId]

        local block = needsBlock:createBlock({id = data.blockID})
        setupNeedsElementBlock(block)

        local fillBar = block:createFillBar({ id = data.fillBarID, current = need.max, max = need.max })
        setupNeedsBar(fillBar)

        fillBar.widget.fillColor = data.color
    
        local conditionLabel = block:createLabel({ id = data.conditionID, text = need.states[need.default].text})
        setupConditionLabel(conditionLabel)

        fillBar:register("help", function()
            common.helper.createTooltip(data.name, data.getTooltip() )
        end)
        conditionLabel:register("help", function()
            common.helper.createTooltip(data.name, data.getTooltip() )
        end)
    end

    event.trigger("Ashfall:updateNeedsUI")
end
event.register("uiCreated", createNeedsUI, { filter = "MenuInventory" } )


local function updateNeedsUI(e)
    if not common.data then return end
    local inventoryMenu = tes3ui.findMenu(tes3ui.registerID("MenuInventory"))
    if inventoryMenu then   
        --Check Ashfall active
        local needsBlock = inventoryMenu:findChild(needsBlockId)
        local needsActive = (
            conditionConfig.hunger:isActive() or
            conditionConfig.thirst:isActive() or
            conditionConfig.tiredness:isActive()
        )
        needsBlock.visible = needsActive
        --Update UIs
        updateNeedsBlock(inventoryMenu, this.UIData.hunger)
        updateNeedsBlock(inventoryMenu, this.UIData.thirst)
        updateNeedsBlock(inventoryMenu, this.UIData.tiredness)

        inventoryMenu:updateLayout()
    end
end
event.register("Ashfall:updateNeedsUI", updateNeedsUI)

function this.addNeedsBlockToMenu(e, needId)
    local need = conditionConfig[needId]
    local data = this.UIData[needId]
    if not not need:isActive() then
        --this need is disabled
        return
    end

    local block = e.element:createBlock()
    setupNeedsElementBlock(block) 
    block.maxWidth = 250
    block.borderTop = 10

    local needsValue = need.max - need:getValue()
    local fillBar = block:createFillBar({current = needsValue, max = need.max})
    setupNeedsBar(fillBar)

    fillBar.widget.fillColor = data.color

    local conditionText = need:getCurrentStateMessage()

    local conditionLabel = block:createLabel({ id = data.conditionID, text = conditionText})
    setupConditionLabel(conditionLabel)
    updateNeedsBlock(e.element, data)
end


return this
