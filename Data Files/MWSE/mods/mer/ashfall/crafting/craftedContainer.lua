local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local miscToContainerMapping = {
    ashfall_sack_01 = "ashfall_sack_c",
    ashfall_chest_01_m = "ashfall_chest_01_c"
}
local containerToMiscMapping = {}
for misc, container in pairs(miscToContainerMapping) do 
    containerToMiscMapping[container] = misc 
end

local function buildName(object, customName)
    return string.format("%s: %s", object.name, customName)
end

local function getName(containerRef, name)
    local name = name or containerRef.data.customName
    if name and name ~= "" then
        return buildName(containerRef.object, name)
    else
        return containerRef.object.name
    end
end

local function onGearDropped(e)
    local containerId = miscToContainerMapping[e.reference.object.id:lower()]
    if containerId then
        local position = e.reference.position:copy()
        local orientation = e.reference.orientation:copy()
        tes3.createReference{
            object = containerId,
            position = position,
            orientation = orientation,
            cell = e.reference.cell,
        }
        if common.helper.isStack(e.reference) then
            tes3.addItem{
                reference = tes3.player, 
                item = e.reference.object, 
                count = e.reference.attachments.variables.count - 1,
                playSound = false
            }
        end
        common.helper.yeet(e.reference)
    end
end
event.register("Ashfall:GearDropped", onGearDropped)


local function pickup(containerRef)
    local itemList = {}
    for stack in tes3.iterate(containerRef.object.inventory.iterator) do
        table.insert(itemList, stack)
    end
    for _, stack in ipairs(itemList) do
        tes3.transferItem{ from = containerRef, to = tes3.player, item = stack.object, count = stack.count, updateGUI  = false, playSound = false }
    end
    tes3ui.forcePlayerInventoryUpdate()
    local miscId = containerToMiscMapping[containerRef.baseObject.id:lower()]
    tes3.addItem{ reference = tes3.player, item = miscId, }
    common.helper.yeet(containerRef)
    if #itemList > 0 then
        tes3.messageBox("Contents of %s added to inventory.", getName(containerRef))
    end
end

local menuID = tes3ui.registerID("ChooseContainerNameMenu")

local function nameChosen(containerRef)
    tes3ui.leaveMenuMode(menuID)
    tes3ui.findMenu(menuID):destroy()
    tes3.messageBox("Renamed to %s", containerRef.data.customName)
end


local function rename(containerRef)
    local menu = tes3ui.createMenu{ id = menuID, fixedFrame = true }
    menu.minWidth = 400
    menu.alignX = 0.5
    menu.alignY = 0
    menu.autoHeight = true
   -- menu.widthProportional = 1
    --menu.heightProportional = 1
    local textField = mwse.mcm.createTextField(
        menu,
        {
            label = string.format("Label %s:", containerRef.object.name),
            variable = mwse.mcm.createTableVariable{
                id = 'customName', 
                table = containerRef.data
            },
            callback = function() 
                containerRef.modified = true
                nameChosen(containerRef) 
            end
        }
    )
    tes3ui.acquireTextInput(textField.elements.inputField)
    tes3ui.enterMenuMode(menuID)
end

local skipActivate
local function onActivate(e)
    if e.activator ~= tes3.player then return end
    local miscId = containerToMiscMapping[e.target.baseObject.id:lower()]
    if not miscId then return end 
    if skipActivate then
        skipActivate = nil
        return
    end
    if tes3ui.menuMode() then
        pickup()
        return false
    end

    if tes3.worldController.inputController:isKeyDown(config.modifierHotKey.keyCode) then
        skipActivate = true
        tes3.player:activate(e.target)
        return
    end
    common.helper.messageBox{
        message = getName(e.target),
        buttons = {
            {
                text = "Open",
                callback = function()
                    timer.delayOneFrame(function()
                        skipActivate = true
                        tes3.player:activate(e.target)
                    end)
                end
            },
            {
                text = "Label",
                callback = function()
                    rename(e.target)
                end
            },
            {
                text = "Pick Up",
                callback = function()
                    pickup(e.target)
                end
            },

        },
        doesCancel = true
    }
    return false
end
event.register("activate", onActivate)


local function customNameTooltip(e)
    local name = e.itemData and e.itemData.data.customName
    if name then
        local label = e.tooltip:findChild(tes3ui.registerID('HelpMenu_name'))
        if label then
            label.text = buildName(e.object, name)
        end
    end
end

event.register("uiObjectTooltip", customNameTooltip)