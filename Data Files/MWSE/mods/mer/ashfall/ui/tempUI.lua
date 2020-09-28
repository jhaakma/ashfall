local this = {}

local common = require("mer.ashfall.common.common")
local needsUI = require("mer.ashfall.needs.needsUI")

local IDs = {
    
    mainHUDBlock = tes3ui.registerID("Ashfall:HUD_mainHUDBlock"),
    bottomBlock = tes3ui.registerID("Ashfall:HUD_bottomBlock"),
    topHUDBlock = tes3ui.registerID("Ashfall:HUD_topHUDBlock"),
    
    wetnessBlock = tes3ui.registerID("Ashfall:HUD_wetnessBlock"),
    wetnessBar = tes3ui.registerID("Ashfall:HUD_wetnessBar"),
    
    shelteredBlock = tes3ui.registerID("Ashfall:HUD_shelteredBlock"),
    unshelteredIcon = tes3ui.registerID("Ashfall:HUD_unshelteredIcon"),
    shelteredIcon = tes3ui.registerID("Ashfall:HUD_shelteredIcon"),

    conditionLabelBlock = tes3ui.registerID("Ashfall:HUD_conditionLabelBlock"),
    conditionLabel = tes3ui.registerID("Ashfall:HUD_conditionLabel"),
    conditionIcon = tes3ui.registerID("Ashfall:HUD_conditionIcon"),
    
    leftTempPlayerBar = tes3ui.registerID("Ashfall:HUD_leftTempPlayerBar"),
    rightTempPlayerBar = tes3ui.registerID("Ashfall:HUD_rightTempPlayerBar"),
    
    leftTempLimitBar = tes3ui.registerID("Ashfall:HUD_leftTempLimitBar"),
    rightTempLimitBar = tes3ui.registerID("Ashfall:HUD_rightTempLimitBar"),

    needsBlock = tes3ui.registerID("Ashfall:HUD_NeedsBlock"),
    hunger = tes3ui.registerID("Ashfall:HUD_HungerBar"),
    
    thirst = tes3ui.registerID("Ashfall:HUD_ThirstBar"),
    tiredness = tes3ui.registerID("Ashfall:HUD_SleepBar"),

    healthBlocker = tes3ui.registerID("Ashfall:HUD_healthBlocker"),
    magicBlocker = tes3ui.registerID("Ashfall:HUD_magicBlocker"),
    fatigueBlocker = tes3ui.registerID("Ashfall:HUD_fatigueBlocker"),
}

local function findHUDElement(id)
    local multiMenu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    return multiMenu:findChild( id )
end


function this.updateHUD()
    if not common.data then return end
    local mainHUDBlock = findHUDElement(IDs.mainHUDBlock)

    --Hide HUD if Ashfall is disabled
    if common.config.getConfig().enableTemperatureEffects then
        mainHUDBlock.visible = true

        local bottomBlock = findHUDElement(IDs.bottomBlock)
        if bottomBlock then
            
            
            local wetness = common.data.wetness or 0
            wetness = math.clamp(wetness, 0, 100) or 0
            local wetnessBar = findHUDElement(IDs.wetnessBar)
            wetnessBar.widget.current = wetness

            
            local shelteredIcon = findHUDElement(IDs.shelteredIcon)
            shelteredIcon.visible = common.data.isSheltered
            local unshelteredIcon = findHUDElement(IDs.unshelteredIcon)
            unshelteredIcon.visible = not common.data.isSheltered


            local condition = common.staticConfigs.conditionConfig.temp.states[( common.data.currentStates.temp  or "comfortable" )].text
            local conditionLabel = findHUDElement(IDs.conditionLabel)
            conditionLabel.text = condition


            
            
            --Update Temp Player bars
            local tempPlayer = common.staticConfigs.conditionConfig.temp:getValue()
            local leftTempPlayerBar = findHUDElement(IDs.leftTempPlayerBar)
            local rightTempPlayerBar = findHUDElement(IDs.rightTempPlayerBar)
            --Cold
            if tempPlayer < 0 then

                leftTempPlayerBar.widget.fillColor = {0.3, 0.5, (0.75 + tempPlayer/400)} --Bluish
                leftTempPlayerBar.widget.current = tempPlayer
                --hack
                local bar = leftTempPlayerBar:findChild(tes3ui.registerID("PartFillbar_colorbar_ptr"))
                bar.width = (tempPlayer / 100) * leftTempPlayerBar.width        
                rightTempPlayerBar.widget.current = 0
            --Hot:
            else
                rightTempPlayerBar.widget.fillColor = {(0.75 + tempPlayer/400), 0.3, 0.2}
                rightTempPlayerBar.widget.current = tempPlayer
                local bar = leftTempPlayerBar:findChild(tes3ui.registerID("PartFillbar_colorbar_ptr"))
                bar.width = 0
            end

            --Update Temp Limit bars
            local tempLimit = math.clamp((common.data.tempLimit), -100, 100) or 0
            local leftTempLimitBar = findHUDElement(IDs.leftTempLimitBar)
            local rightTempLimitBar = findHUDElement(IDs.rightTempLimitBar)
            if tempLimit < 0 then
                leftTempLimitBar.widget.fillColor = {0.3, 0.5, (0.75 + tempLimit/400)} --Bluish
                leftTempLimitBar.widget.current = tempLimit
                --hack
                local bar = leftTempLimitBar:findChild(tes3ui.registerID("PartFillbar_colorbar_ptr"))
                bar.width = (tempLimit / 100) * leftTempLimitBar.width        
                rightTempLimitBar.widget.current = 0
            --Hot:
            else
                rightTempLimitBar.widget.fillColor = {(0.75 + tempLimit/400), 0.3, 0.2}
                rightTempLimitBar.widget.current = tempLimit
                local bar = leftTempLimitBar:findChild(tes3ui.registerID("PartFillbar_colorbar_ptr"))
                bar.width = 0
            end



            bottomBlock:updateLayout()
        end
    else
        mainHUDBlock.visible = false
    end

    local needsBlock = findHUDElement(IDs.needsBlock)
    if needsBlock then
        
        --Hide or show based on mcmSettings
        local hasNeeds = (
            common.config.getConfig().enableHunger or
            common.config.getConfig().enableThirst or
            common.config.getConfig().enableTiredness
        )
        if hasNeeds then
            needsBlock.visible = true

            --HUNGER
            local hungerBar = findHUDElement(IDs.hunger)
            local hunger = common.coditions.hunger:getValue()
            if needsUI.showHunger() then
                local newHunger = ( ( 1 - hunger:getValue() / 100 ) * hungerBar.parent.height)
                hungerBar.height = newHunger
                hungerBar.parent.visible = true
            else
                hungerBar.parent.visible = false
            end

            --THIRST
            local thirstBar = findHUDElement(IDs.thirst)
            local thirst = common.staticConfigs.conditionConfig.thirst
            if needsUI.showThirst()  then
                local newThirst = ( (1 - thirst:getValue() / 100 ) * thirstBar.parent.height)
                thirstBar.height = newThirst
                thirstBar.parent.visible = true
            else
                thirstBar.parent.visible = false
            end

            --SLEEP
            local sleepBar = findHUDElement(IDs.tiredness)
            local tiredness = common.staticConfigs.conditionConfig.tiredness
            if needsUI.showTiredness() then
                local newSleep = ( (1-  tiredness:getValue() / 100 ) * sleepBar.parent.height)
                sleepBar.height = newSleep
                sleepBar.parent.visible = true
            else
                sleepBar.parent.visible = false
            end

            needsBlock:updateLayout()
        else
            needsBlock.visible = false
        end
        
       

    end

end


local function quickFormat(element, padding)
    element.paddingAllSides = padding
    element.autoHeight = true
    element.autoWidth = true
    return element
end


local function createTempHUD(parent)
    local tempBarWidth = 80
    local tempBarHeight = 10
    local limitBarHeight = 12

        ---\
            --fill background of bottomBlock with blackj
            local colorBlock = parent:createRect({color = tes3ui.getPalette("black_color")})
            colorBlock.flowDirection = "top_to_bottom"
            colorBlock = quickFormat(colorBlock, 0)
        
            ---\
                ---MID BLOCK
                local tempIndicatorBlock = colorBlock:createBlock()
                tempIndicatorBlock.flowDirection = "left_to_right"
                tempIndicatorBlock = quickFormat(tempIndicatorBlock, 0)
                ---\    
                    local leftTempIndicatorBlock = tempIndicatorBlock:createBlock()
                    leftTempIndicatorBlock.flowDirection = "top_to_bottom"
                    leftTempIndicatorBlock = quickFormat(leftTempIndicatorBlock, 0)
                    ---\
                        --Left Player Bar
                        local leftTempPlayerBar = leftTempIndicatorBlock:createFillBar({id = IDs.leftTempPlayerBar, current = 50, max = 100})
                        leftTempPlayerBar:register( "help", function() 
                            local playerTemp = common.staticConfigs.conditionConfig.temp
                            local headerText = string.format("Player Temperature: %.2f", playerTemp:getValue() )
                            local labelText = "Your current temperature. This directly determines hot and cold condition effects."
                            common.helper.createTooltip(headerText, labelText)
                        end )
                        leftTempPlayerBar.widget.showText = false
                        leftTempPlayerBar.height = tempBarHeight
                        leftTempPlayerBar.width = tempBarWidth
                        leftTempPlayerBar.borderBottom = 0
                        --Reverse direction of left bar
                        leftTempPlayerBar.paddingAllSides = 2
                        local bar = leftTempPlayerBar:findChild(tes3ui.registerID("PartFillbar_colorbar_ptr"))
                        bar.layoutOriginFractionX = 1.0    
                        
                    ---\    
                        --Left tempLimit bar
                        local leftTempLimitBar = leftTempIndicatorBlock:createFillBar({id = IDs.leftTempLimitBar, current = 50, max = 100})
                        leftTempLimitBar:register( "help", function()
                            local headerText = string.format("Temperature Limit: %.2f", common.data.tempLimit)
                            local labelText = "Represents the temperature you will reach if the current conditions remain."
                            common.helper.createTooltip(headerText, labelText)
                        end)
                        leftTempLimitBar.widget.showText = false
                        leftTempLimitBar.height = limitBarHeight
                        leftTempLimitBar.width = tempBarWidth
                        --Reverse direction of left bar
                        leftTempLimitBar.paddingAllSides = 2
                        bar = leftTempLimitBar:findChild(tes3ui.registerID("PartFillbar_colorbar_ptr"))
                        bar.layoutOriginFractionX = 1.0                
                        
                    
                ---\        
                    local righttempIndicatorBlock = tempIndicatorBlock:createBlock()
                    righttempIndicatorBlock.flowDirection = "top_to_bottom"
                    righttempIndicatorBlock = quickFormat(righttempIndicatorBlock, 0)        
                    ---\
                        --Right Color Bar
                        local rightTempPlayerBar = righttempIndicatorBlock:createFillBar({id = IDs.rightTempPlayerBar, max = 100})
                        rightTempPlayerBar:register( "help", function()
                            local playerTemp = common.staticConfigs.conditionConfig.temp
                            local headerText = string.format("Player Temperature: %.2f", playerTemp:getValue()  )
                            local labelText = "Your current temperature. This directly determines hot and cold condition effects."
                            common.helper.createTooltip(headerText, labelText)  
                        end)
                        rightTempPlayerBar.widget.showText = false
                        rightTempPlayerBar.height = tempBarHeight
                        rightTempPlayerBar.width = tempBarWidth
                        rightTempPlayerBar.borderBottom = 0
                        
                    --\    
                        --Right tempLimit bar
                        local rightTempLimitBar = righttempIndicatorBlock:createFillBar({id = IDs.rightTempLimitBar , current = 50, max = 100})
                        rightTempLimitBar:register( "help", function()
                            local headerText = string.format("Temperature Limit: %.2f", common.data.tempLimit)
                            local labelText = "Represents the temperature you will reach if the current conditions remain."
                            common.helper.createTooltip(headerText, labelText)
                        end)
                        rightTempLimitBar.widget.showText = false
                        rightTempLimitBar.height = limitBarHeight
                        rightTempLimitBar.width = tempBarWidth
end

-- local function createVerticalNeedsBar(parent, need)

--     local function darkenColor(color)
--         local multi = 0.8
--         return { 
--             color[1] * multi, 
--             color[2] * multi, 
--             color[3] * multi,
--         }
--     end

--     local data = needsUI.UIData[need]
--     local block = parent:createBlock()
--     block.flowDirection = "top_to_bottom"
--     block.heightProportional = 1.0
--     block.autoWidth = true

--     local fillbar = block:createThinBorder()
--     fillbar.autoWidth = true
--     fillbar.heightProportional = 1.0
--     fillbar.paddingAllSides = 2

--     local filler = fillbar:createRect({ id = IDs[need] })
--     filler.color = darkenColor(data.color)
--     filler.width = 5
--     filler.absolutePosAlignY = 1.0
--     filler.height = 0
-- end

----Depricated, Needs now visible by health/magicka/fatigue blocker bars
-- local function createNeedsHUD(parent)

--     local needsBlock = parent:createRect({ id = IDs.needsBlock})
--     needsBlock.heightProportional = 1.0
--     needsBlock.autoWidth = true
--     needsBlock.borderAllSides = 2

--     createVerticalNeedsBar(needsBlock, "hunger")

--     createVerticalNeedsBar(needsBlock, "thirst")

--     createVerticalNeedsBar(needsBlock, "tiredness")


-- end

local function createWetnessIndicator(parentBlock)
    local wetnessBlock = parentBlock:createBlock({id = IDs.wetnessBlock})
    
    --Register Tooltip
    wetnessBlock:register("help", function()
        local headerText = common.staticConfigs.conditionConfig.wetness.states[common.data.currentStates.wetness].text
        local labelText = "The wetter you are, the longer it takes to warm up, the quicker you cool down, and the more susceptible you are to shock damage."
        common.helper.createTooltip(headerText, labelText)
    end)
    wetnessBlock = quickFormat(wetnessBlock, 0)
    ---\
        local wetnessBackground = wetnessBlock:createRect({color = {0.0, 0.05, 0.1} })
        wetnessBackground.height = 20
        wetnessBackground.width = 36
        wetnessBackground.layoutOriginFractionX = 0.0
    
    ---\
        local wetnessBar = wetnessBlock:createFillBar({id = IDs.wetnessBar, current = 50, max = 100})
        wetnessBar.widget.fillColor = {0.5, 1.0, 1.0}
        wetnessBar.widget.showText = false
        wetnessBar.height = 20
        wetnessBar.width = 36
        wetnessBar.borderBottom = 1
        wetnessBar.layoutOriginFractionX = 0.0

    ---\
        local wetnessIcon = wetnessBlock:createImage({path="Icons/ashfall/hud/wetness.dds"})
        wetnessIcon.height = 16
        wetnessIcon.width = 32
        wetnessIcon.borderAllSides = 2
        wetnessBar.layoutOriginFractionX = 0.0

    return wetnessBlock
end

local function createShelteredIndicator(parentBlock)
    local shelteredBlock = parentBlock:createThinBorder({id = IDs.shelteredBlock})
    shelteredBlock = quickFormat(shelteredBlock, 0)
    --Register Tooltip
    shelteredBlock:register("help", function()
        local headerText = common.data.isSheltered and "Sheltered" or "Not Sheltered"
        local labelText = "Find shelter to avoid getting wet from the rain."
        common.helper.createTooltip(headerText, labelText)
    end)
    
    local unshelteredIcon = shelteredBlock:createImage({path="Icons/ashfall/hud/unsheltered.dds", id = IDs.unshelteredIcon})
    unshelteredIcon.height = 16
    unshelteredIcon.width = 16
    unshelteredIcon.borderAllSides = 2

    local shelteredIcon = shelteredBlock:createImage({path="Icons/ashfall/hud/sheltered.dds", id = IDs.shelteredIcon})
    shelteredIcon.height = 16
    shelteredIcon.width = 16
    shelteredIcon.borderAllSides = 2
    return shelteredBlock
end

local function createConditionStateIndicator(parentBlock)
    local conditionLabelBlock = parentBlock:createBlock{id = IDs.conditionLabelBlock}
    conditionLabelBlock = quickFormat(conditionLabelBlock, 0)
    conditionLabelBlock.widthProportional = 1.0
    conditionLabelBlock.borderAllSides = 1

    local conditionLabel = conditionLabelBlock:createLabel({id = IDs.conditionLabel, text = "Comfortable" })
    conditionLabel.layoutOriginFractionX = 0.0
    --register tooltip
    conditionLabelBlock:register("help", function()
        local headerText = common.staticConfigs.conditionConfig.temp.states[common.data.currentStates.temp].text
        local labelText = "Your current temperature condition."
        common.helper.createTooltip(headerText, labelText)
    end)
end



function this.createHUD(e)
    if not e.newlyCreated then return end
    local multiMenu = e.element

    -- Find the UI element that holds the sneak icon indicator.
    local mainBlock = multiMenu:findChild(tes3ui.registerID("MenuMulti_weapon_layout")).parent.parent.parent
    local mainHUDBlock = mainBlock:createBlock({id = IDs.mainHUDBlock}) 
    --createNeedsHUD(mainBlock)
    mainHUDBlock = quickFormat(mainHUDBlock, 2)
    --mainHUDBlock.layoutOriginFractionX = 0
    mainHUDBlock.flowDirection = "top_to_bottom"


    local topBlock = mainHUDBlock:createBlock({id = IDs.topHUDBlock})  
    topBlock.flowDirection = "left_to_right"
    topBlock = quickFormat(topBlock, 0)
    topBlock.widthProportional = 1



    createWetnessIndicator(topBlock)
    createShelteredIndicator(topBlock)
    createConditionStateIndicator(topBlock)
                
    local bottomBlock = mainHUDBlock:createThinBorder({id = IDs.bottomBlock})
    bottomBlock.flowDirection = "top_to_bottom"
    bottomBlock = quickFormat(bottomBlock, 0)

    createTempHUD(bottomBlock)

    mainBlock:reorderChildren(1, -2, 2)

end



return this