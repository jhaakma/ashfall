--[[
This class manages the decoration selection menu for unfired pottery

Layout:
┌────────────────────────────────────────────┐
│  Apply Decoration                          │
├───────────────┬────────────────────────────┤
│ Decorations   │                            │
│ (scrollable)  │                            │
│ • Engraving   │      3D Preview            │
│ • Glaze       │    (Pottery with effects)  │
│ • Pattern     │                            │
│ • ...         │                            │
├───────────────┤                            │
│ Requirements  │                            │
│ Info Panel    │                            │
├───────────────┴────────────────────────────┤
│                      [Confirm] [Cancel]    │
└────────────────────────────────────────────┘
]]
---@class Ashfall.Clay.DecorationMenu : Ashfall.Clay.DecorationMenu.newParams
---@field decorationDict table<string, Ashfall.Clay.Decoration>
---@field results Ashfall.Clay.DecorationMenu.results
---@field elements Ashfall.Clay.DecorationMenu.elements
---@field previewPane CraftingFramework.PreviewPane?
local DecorationMenu = {}

local common = require("mer.ashfall.common.common")
local logger = common.createLogger("ClayDecorationMenu")
local Decals = require("mer.ashfall.clay.Visuals.PotteryDecals")
logger.logLevel = "TRACE"

local PreviewPane = require("CraftingFramework.components.PreviewPane")

---List of UI elements in the menu
---@class Ashfall.Clay.DecorationMenu.elements
---@field menu tes3uiElement
---@field decorationList tes3uiElement
---@field preview tes3uiElement
---@field requirementsStats tes3uiElement
---@field confirmButton tes3uiElement
---@field cancelButton tes3uiElement

---@class Ashfall.Clay.DecorationMenu.results
---@field selectedDecorationId string?

---@class Ashfall.Clay.DecorationMenu.newParams
---@field title string
---@field potteryItemId string The ID of the pottery item to decorate
---@field decorations Ashfall.Clay.Decoration[] Available decorations
---@field okayCallback fun(e: Ashfall.Clay.DecorationMenu.results)
---@field hasTemper boolean Whether the pottery has temper effect

---Constructor
---@param e Ashfall.Clay.DecorationMenu.newParams
---@return Ashfall.Clay.DecorationMenu
function DecorationMenu:new(e)
    logger:debug("DecorationMenu:new() called")

    local decorationDict = {}
    for _, decoration in ipairs(e.decorations) do
        decorationDict[decoration.id] = decoration
    end

    table.sort(e.decorations, function(a, b)
        return a.name < b.name
    end)

    local obj = {
        title = e.title,
        decorations = e.decorations,
        decorationDict = decorationDict,
        okayCallback = e.okayCallback,
        results = {},
        elements = {},
        potteryItemId = e.potteryItemId,
        hasTemper = e.hasTemper,
    }
    setmetatable(obj, self)
    self.__index = self

    return obj
end

function DecorationMenu:show()
    -- Default to None selected
    self.results.selectedDecorationId = nil

    local menu = self:createMenu()

    -- Title row
    local rowOne = self:createRow(menu)
    rowOne.autoHeight = true
    self:createTitle(rowOne, self.title)

    -- Main content row (decoration list + requirements on left, preview on right)
    local rowTwo = self:createRow(menu)

    -- Left column contains decoration list and requirements panel
    local leftColumn = self:createColumn(rowTwo)
    leftColumn.minWidth = 250
    leftColumn.heightProportional = 1.0
    self:createDecorationList(leftColumn)
    self:createRequirementsStats(leftColumn)

    -- Right column contains preview
    local rightColumn = self:createColumn(rowTwo)
    rightColumn.widthProportional = 1.0
    rightColumn.heightProportional = 1.0
    self:createPreview(rightColumn)

    -- Bottom row for buttons
    local rowThree = self:createRow(menu)
    rowThree.widthProportional = 1.0

    -- Buttons on the right side of bottom row
    local buttonContainer = rowThree:createBlock()
    buttonContainer.widthProportional = 1.0
    buttonContainer.autoHeight = true
    buttonContainer.flowDirection = "left_to_right"
    buttonContainer.childAlignX = 1.0
    self:createConfirmButton(buttonContainer)
    self:createCancelButton(buttonContainer)

    self:update()
end

function DecorationMenu:createCancelButton(row)
    logger:debug("DecorationMenu:createCancelButton() called")
    local cancelButton = row:createButton{ id = "Ashfall:DecorationMenuCancelButton", text = "Cancel" }
    cancelButton:register("mouseClick", function()
        logger:debug("Cancel button clicked, closing menu")
        -- Clean up preview pane before destroying menu
        if self.previewPane then
            self.previewPane:destroy()
            self.previewPane = nil
        end
        local menu = tes3ui.findMenu("Ashfall:DecorationMenu")
        if menu then
            menu:destroy()
            tes3ui.leaveMenuMode()
        end
    end)
    self.elements.cancelButton = cancelButton
    return cancelButton
end

function DecorationMenu:createConfirmButton(row)
    logger:debug("DecorationMenu:createConfirmButton() called")
    local confirmButton = row:createButton{ id = "Ashfall:DecorationMenuConfirmButton", text = "Confirm" }
    confirmButton:register("mouseClick", function()
        logger:debug("Confirm button clicked")

        -- Confirm decoration is selected and requirements met
        if not self:checkRequirements() then
            logger:warn("Confirm button clicked but requirements not met, ignoring")
            return
        end

        -- Clean up preview pane before destroying menu
        if self.previewPane then
            self.previewPane:destroy()
            self.previewPane = nil
        end
        local menu = tes3ui.findMenu("Ashfall:DecorationMenu")
        if menu then
            menu:destroy()
            tes3ui.leaveMenuMode()
            if self.okayCallback then
                local results = {
                    selectedDecorationId = self.results.selectedDecorationId,
                }
                self.okayCallback(results)
            end
        end
    end)
    self.elements.confirmButton = confirmButton
    return confirmButton
end

function DecorationMenu:createRequirementsStats(column)
    logger:debug("DecorationMenu:createRequirementsStats() called")

    local statsPane = column:createBlock{ id = "Ashfall:DecorationRequirementsStatsPane" }
    statsPane.widthProportional = 1.0
    statsPane.autoHeight = true
    statsPane.minHeight = 120
    statsPane.flowDirection = "top_to_bottom"
    statsPane.paddingAllSides = 8

    self:createTitle(statsPane, "Requirements")

    self.elements.requirementsStats = statsPane
    return statsPane
end

function DecorationMenu:createPreview(previewContainer)
    logger:debug("DecorationMenu:createPreview() called")

    local title = self:createTitle(previewContainer, "Preview")
    title.borderAllSides = 8

    local block = previewContainer:createBlock{ id = "Ashfall:DecorationPreviewBlock" }
    block.widthProportional = 1.0
    block.autoHeight = true
    block.autoWidth = true
    block.paddingAllSides = 20

    -- Create PreviewPane instance (keeping it square)
    self.previewPane = PreviewPane:new({
        width = 350,
        height = 350,
        parentElement = block,
    })
    self.previewPane:create()

    self.elements.preview = previewContainer
    return previewContainer
end

---@param column tes3uiElement
function DecorationMenu:createDecorationList(column)
    logger:debug("DecorationMenu:createDecorationList() called")

    local decorationListBlock = column:createBlock{ id = "Ashfall:DecorationListBlock" }
    decorationListBlock.widthProportional = 1.0
    decorationListBlock.heightProportional = 1.0
    decorationListBlock.autoHeight = true
    decorationListBlock.autoWidth = true
    decorationListBlock.flowDirection = "top_to_bottom"
    decorationListBlock.paddingLeft = 8
    decorationListBlock.paddingRight = 8

    self:createTitle(decorationListBlock, "Decorations")

    -- Add "None" option
    local decorationList = decorationListBlock:createVerticalScrollPane{ id = "Ashfall:DecorationList" }
    decorationList.widthProportional = 1.0
    decorationList.minHeight = 150
    decorationList.maxHeight = 300

    local noneButton = decorationList:createTextSelect{
        id = "Ashfall:DecorationButton_none",
        text = "None"
    }
    noneButton:register("mouseClick", function()
        logger:debug("Selected decoration: none")
        self.results.selectedDecorationId = nil
        self:update()
    end)

    for _, decoration in ipairs(self.decorations) do
        local decorationButton = decorationList:createTextSelect{
            id = "Ashfall:DecorationButton_" .. decoration.id,
            text = decoration.name
        }

        -- Check if requirements are met and grey out if not
        local requirementsMet = self:checkDecorationRequirements(decoration)
        if not requirementsMet then
            decorationButton.widget.state = tes3.uiState.disabled
        end

        decorationButton:register("mouseClick", function()
            logger:debug("Selected decoration: %s", decoration.id)
            self.results.selectedDecorationId = decoration.id
            self:update()
        end)
    end

    self.elements.decorationList = decorationList
    return decorationList
end

---@param row tes3uiElement
---@param text string
---@return tes3uiElement
function DecorationMenu:createTitle(row, text)
    logger:debug("DecorationMenu:createTitle() called")
    local title = row:createLabel{ text = text }
    title.autoHeight = true
    title.widthProportional = 1.0
    title.justifyText = "left"
    title.wrapText = true
    title.color = tes3ui.getPalette("header_color")
    title.borderTop = 6
    return title
end

function DecorationMenu:createRow(menu)
    logger:debug("DecorationMenu:createRow() called")
    local row = menu:createBlock{ id = "Ashfall:DecorationMenuRow" }
    row.flowDirection = "left_to_right"
    row.widthProportional = 1.0
    row.autoWidth = true
    row.autoHeight = true
    return row
end

function DecorationMenu:createColumn(row)
    logger:debug("DecorationMenu:createColumn() called")
    local column = row:createThinBorder{ id = "Ashfall:DecorationMenuColumn" }
    column.flowDirection = "top_to_bottom"
    column.autoWidth = true
    column.autoHeight = true
    return column
end

function DecorationMenu:createMenu()
    logger:debug("DecorationMenu:createMenu() called")
    local menu = tes3ui.createMenu{ id = "Ashfall:DecorationMenu", fixedFrame = true }
    tes3ui.enterMenuMode(menu.id)

    menu.absolutePosAlignX = 0.5
    menu.absolutePosAlignY = 0.5
    menu:getContentElement().paddingAllSides = 12
    self.elements.menu = menu
    return menu
end

-------------------
-- Update functions
-------------------

function DecorationMenu:update()
    logger:debug("DecorationMenu:update() called")

    self:updateConfirmButton()
    self:updateRequirementsStats()
    self:updatePreview()
    self.elements.menu:updateLayout()
end

function DecorationMenu:updatePreview()
    if not self.previewPane then
        logger:warn("PreviewPane not found, cannot update")
        return
    end

    -- Get the pottery item object
    local item = tes3.getObject(self.potteryItemId)
    if not item then
        logger:warn("Pottery item not found: %s", self.potteryItemId)
        self.previewPane:updatePreview(nil)
        return
    end

    ---@type CraftingFramework.PreviewPane.PreviewData
    local previewData = {
        item = item,
        rotationAxis = 'z', -- Pottery items typically rotate around Z axis
    }

    logger:debug("Updating preview with pottery item: %s", item.id)
    self.previewPane:updatePreview(previewData)

    -- Apply effects to the preview
    local nifBlock = self.previewPane:getNifElement()
    if nifBlock and nifBlock.sceneNode then
        local sceneNode = nifBlock.sceneNode

        -- Apply temper effect if present
        if self.hasTemper then
            local temperDecals = Decals.get("temper") --[[@as Ashfall.Clay.PotteryDecals]]
            if temperDecals then
                temperDecals:applyDecal(sceneNode)
            end
        end

        -- Apply fired version of decoration to preview
        if self.results.selectedDecorationId then
            local decoration = self:getDecoration(self.results.selectedDecorationId)
            if decoration then
                logger:debug("Applying fired decoration: %s", decoration.id)
                decoration:applyFired(sceneNode)
            end
        end
    end
end

function DecorationMenu:checkRequirements()
    -- If no decoration selected (None option), that's valid
    if not self.results.selectedDecorationId then
        return true
    end

    local decoration = self:getDecoration(self.results.selectedDecorationId)
    if not decoration then
        logger:warn("Decoration not found: %s", self.results.selectedDecorationId)
        return false
    end

    return self:checkDecorationRequirements(decoration)
end

---Check if a specific decoration's requirements are met
---@param decoration Ashfall.Clay.Decoration
---@return boolean
function DecorationMenu:checkDecorationRequirements(decoration)
    -- Check pottery skill requirement
    local potterySkill = common.skills.pottery.current
    if potterySkill < decoration.skillRequirement then
        return false
    end

    -- Check ingredient requirements
    if decoration:playerHasIngredients() == false then
        return false
    end

    return true
end

function DecorationMenu:getDecoration(id)
    return self.decorationDict[id]
end

function DecorationMenu:updateRequirementsStats()
    logger:debug("DecorationMenu:updateRequirementsStats() called")
    local stats = self.elements.requirementsStats
    if not stats then
        logger:warn("Requirements stats element not found, cannot update")
        return
    end

    stats:destroyChildren()

    -- If no decoration selected (None option)
    if not self.results.selectedDecorationId then
        local noneLabel = stats:createLabel{ text = "No decoration selected.\nNo requirements." }
        noneLabel.widthProportional = 1.0
        noneLabel.wrapText = true
        return
    end

    -- Decoration selected
    local decoration = self:getDecoration(self.results.selectedDecorationId)
    if decoration then
        ---@cast decoration Ashfall.Clay.Decoration

        local headerLabel = stats:createLabel{ text = "Requirements:" }
        headerLabel.color = tes3ui.getPalette(tes3.palette.headerColor)

        -- Show description
        local descLabel = stats:createLabel{ text = decoration.description }
        descLabel.widthProportional = 1.0
        descLabel.wrapText = true
        descLabel.borderBottom = 6

        -- Show skill requirement
        local difficulty = decoration.skillRequirement or 0
        local currentSkill = common.skills.pottery.current
        local skillLabel = stats:createLabel{
            text = string.format("Pottery Skill: %s/%s", currentSkill, difficulty)
        }

        if currentSkill < difficulty then
            skillLabel.color = tes3ui.getPalette(tes3.palette.disabledColor)
        end

        -- Show ingredient requirements
        if decoration.ingredients and table.size(decoration.ingredients) > 0 then
            local ingredientsHeaderLabel = stats:createLabel{ text = "\nIngredients:" }
            ingredientsHeaderLabel.color = tes3ui.getPalette(tes3.palette.headerColor)

            for ingredientId, count in pairs(decoration.ingredients) do
                local itemObject = tes3.getObject(ingredientId)
                if not itemObject then
                    logger:warn("Ingredient object not found: %s", ingredientId)
                else
                    local itemCount = tes3.getItemCount({ reference = tes3.player, item = itemObject })

                    local itemName = itemObject and itemObject.name or ingredientId

                    local ingredientLabel = stats:createLabel{
                        text = string.format("  %s: %d/%d", itemName, itemCount, count)
                    }

                    -- Color code based on availability
                    if itemCount < count then
                        ingredientLabel.color = tes3ui.getPalette(tes3.palette.disabledColor)
                    else
                        ingredientLabel.color = tes3ui.getPalette(tes3.palette.normalColor)
                    end
                end
            end
        end
    else
        local promptLabel = stats:createLabel{ text = "Select a decoration\nto see requirements." }
        promptLabel.widthProportional = 1.0
        promptLabel.wrapText = true
    end
end

function DecorationMenu:updateConfirmButton()
    logger:debug("DecorationMenu:updateConfirmButton() called")
    local confirmButton = self.elements.confirmButton
    if not confirmButton then
        logger:warn("Confirm button not found, cannot update")
        return
    end

    local requirementsMet = self:checkRequirements()
    confirmButton.disabled = not requirementsMet
    confirmButton.widget.state = requirementsMet and tes3.uiState.normal or tes3.uiState.disabled
end

return DecorationMenu