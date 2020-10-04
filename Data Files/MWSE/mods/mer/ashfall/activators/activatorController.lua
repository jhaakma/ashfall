local this = {}

--[[
    This script determines what static activator is being looked at, and 
    creates the tooltip for it. 
    Other scripts can see what the player is looking at by checking
    this.getCurrentActivator()
]]-- 

local activatorConfig = require("mer.ashfall.config.staticConfigs").activatorConfig
local config = require("mer.ashfall.config.config")
this.list = activatorConfig.list
this.current = nil
this.currentRef = nil
this.parentNode = nil

function this.getCurrentActivator()
    return this.list[this.current]
end

function this.getCurrentType()
    local currentActivator = this.getCurrentActivator()
    if currentActivator then
        return currentActivator.type
    end
end

function this.getRefActivator(reference)
    for activatorType, activator in pairs(this.list) do
        if activator:isActivator(reference.object.id) then
            return activator
        end 
    end
end




--[[
    Create a tooltip when looking at an activator
]]--
local id_indicator = tes3ui.registerID("Ashfall:activatorTooltip")
local id_label = tes3ui.registerID("Ashfall:activatorTooltipLabel")
function this.getActivatorTooltip()
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    if menu then
        return menu:findChild(id_indicator)
    end
end

local function centerText(element)
    element.autoHeight = true
    element.autoWidth = true
    element.wrapText = true
    element.justifyText = "center" 
end

local function doActivate()
    return (
        this.current and 
        not tes3.menuMode() and 
        config.getConfig()[this.getCurrentActivator().mcmSetting] ~= false
    )
end

local function createActivatorIndicator()
    
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    if menu then
        local mainBlock = menu:findChild(id_indicator)
        
        if doActivate() then
            if mainBlock then
                mainBlock:destroy()
            end

            mainBlock = menu:createBlock({id = id_indicator })
            
            mainBlock.absolutePosAlignX = 0.5
            mainBlock.absolutePosAlignY = 0.03
            mainBlock.autoHeight = true
            mainBlock.autoWidth = true

            
            local labelBackground = mainBlock:createRect({color = {0, 0, 0}})
            --labelBackground.borderTop = 4
            labelBackground.autoHeight = true
            labelBackground.autoWidth = true

            local labelBorder = labelBackground:createThinBorder({})
            labelBorder.autoHeight = true
            labelBorder.autoWidth = true
            labelBorder.paddingAllSides = 10
            labelBorder.flowDirection = "top_to_bottom"

            local text = this.list[this.current].name
            local label = labelBorder:createLabel{ id=id_label, text = text}
            label.color = tes3ui.getPalette("header_color")
            centerText(label)

            

            local eventData = {
                label = label,
                parentNode = this.parentNode,
                element = labelBorder,
                reference = this.currentRef
            }
            event.trigger("Ashfall:Activator_tooltip", eventData, {filter = this.current })


        else
            if mainBlock then
                mainBlock.visible = false
            end
        end
    end
end


--[[
    Every frame, check whether the player is looking at 
    a static activator
]]--
function this.callRayTest()
    this.current = nil
    this.currentRef = nil

    local result = tes3.rayTest{
        position = tes3.getPlayerEyePosition(),
        direction = tes3.getPlayerEyeVector(),
        ignore = { tes3.player }
    }

    if result then
        
        if (result and result.reference ) then 
            local distance = tes3.player.position:distance(result.intersection)

            --Look for activators from list
            if distance < 200 then
                local targetRef = result.reference
                for activatorId, activator in pairs(this.list) do
                    if activator:isActivator(targetRef.object.id) then
                        this.current = activatorId
                        this.currentRef = targetRef
                        this.parentNode = result.object.parent
                    end
                end
                createActivatorIndicator()
                return
            end
        end

        --Special case for looking at water
        local cell =  tes3.player.cell
        local waterLevel = cell.waterLevel or 0
        local intersection = result.intersection
        local adjustedIntersection = tes3vector3.new( intersection.x, intersection.y, waterLevel )
        local adjustedDistance = tes3.getCameraPosition():distance(adjustedIntersection)
        if adjustedDistance < 300 and cell.hasWater then
            local blockedBySomething =
                result.reference and
                result.reference.object.objectType ~= tes3.objectType.static
            local cameraIsAboveWater = tes3.getCameraPosition().z > waterLevel
            local isLookingAtWater = intersection.z < waterLevel
            if cameraIsAboveWater and isLookingAtWater and not blockedBySomething then
                this.current = "water"
            end 
        end
    end
    createActivatorIndicator()
end

--[[
    triggerActivate:
    When player presses the activate key, if they are looking
    at an activator static then fire an event
]]--
local function triggerActivate()
    local inputController = tes3.worldController.inputController
    local keyTest = inputController:keybindTest(tes3.keybind.activate)
    if (keyTest and doActivate() ) then
        local eventData = {
            activator = this.list[this.current],
            ref = this.currentRef,
            node = this.parentNode
        }
        event.trigger("Ashfall:ActivatorActivated", eventData, { filter = eventData.activator.type }) 
    end
end
event.register("keyDown", triggerActivate )


return this