--[[
This class manages the throwing menu for pottery wheels

Layout:
┌────────────────────────────────────────────┐
│  Wheel Throwing                            │
├───────────────┬────────────────────────────┤
│ Shapes        │                            │
│ (scrollable)  │                            │
│ • Cup         │      3D Preview            │
│ • Goblet      │    (Rotating Pot)          │
│ • Bowl        │                            │
│ • ...         │                            │
├───────────────┤                            │
│ Requirements  │                            │
│ Info Panel    │                            │
├───────────────┴────────────────────────────┤

]]
---@class Ashfall.Clay.ShapingMenu : Ashfall.Clay.ShapingMenu.newParams
---@field recipeDict table<string, Ashfall.PotteryRecipe>
---@field results Ashfall.Clay.ShapingMenu.results
---@field elements Ashfall.Clay.ShapingMenu.elements
---@field previewPane CraftingFramework.PreviewPane?
local ShapingMenu = {}

local common = require("mer.ashfall.common.common")
local logger = common.createLogger("ShapingMenu")
local Decals = require("mer.ashfall.clay.Visuals.PotteryDecals")
logger.logLevel = "TRACE"

local PreviewPane = require("CraftingFramework.components.PreviewPane")
---List of UI elements in the menu
---@class Ashfall.Clay.ShapingMenu.elements
---@field menu tes3uiElement
---@field shapeList tes3uiElement
---@field preview tes3uiElement
---@field requirementsStats tes3uiElement
---@field confirmButton tes3uiElement
---@field cancelButton tes3uiElement

---@class Ashfall.Clay.ShapingMenu.results
---@field selectedShapeId string

---@class Ashfall.Clay.ShapingMenu.newParams
---@field title string
---@field clayId string
---@field clayAmount number
---@field recipes Ashfall.PotteryRecipe[]
---@field okayCallback fun(e: Ashfall.Clay.ShapingMenu.results)
---@field hasTemper boolean

---Constructor
---@param e Ashfall.Clay.ShapingMenu.newParams
---@return Ashfall.Clay.ShapingMenu
function ShapingMenu:new(e)
    logger:debug("ShapingMenu:new() called")

    local recipeDict = {}
    for _, recipe in ipairs(e.recipes) do
        recipeDict[recipe.id] = recipe
    end

    table.sort(e.recipes, function(a, b)
        return a.name < b.name
    end)

    local obj = {
        title = e.title,
        recipes = e.recipes,
        recipeDict = recipeDict,
        okayCallback = e.okayCallback,
        results = {},
        elements = {},
        clayId = e.clayId,
        clayAmount = e.clayAmount,
        hasTemper = e.hasTemper,
    }
    setmetatable(obj, self)
    self.__index = self

    return obj
end


function ShapingMenu:show()

        --select first shape by default
    if #self.recipes > 0 then
        self.results.selectedShapeId = self.recipes[1].id
    end
    local menu = self:createMenu()

    -- Title row
    local rowOne = self:createRow(menu)
    rowOne.autoHeight = true
    self:createTitle(rowOne, self.title)

    -- Main content row (shape list + requirements on left, preview on right)
    local rowTwo = self:createRow(menu)

    -- Left column contains shape list and requirements panel
    local leftColumn = self:createColumn(rowTwo)
    leftColumn.minWidth = 250
    leftColumn.heightProportional = 1.0
    self:createShapeList(leftColumn)
    self:createRequirementsStats(leftColumn)

    -- Right column contains preview
    local rightColumn = self:createColumn(rowTwo)
    rightColumn.widthProportional = 1.0
    rightColumn.heightProportional = 1.0
    self:createPreview(rightColumn)

    -- Bottom row for clay type and buttons
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

function ShapingMenu:createCancelButton(row)
    logger:debug("ShapingMenu:createCancelButton() called")
    local cancelButton = row:createButton{ id = "Ashfall:ShapingMenuCancelButton", text = "Cancel" }
    cancelButton:register("mouseClick", function()
        logger:debug("Cancel button clicked, closing menu")
        -- Clean up preview pane before destroying menu
        if self.previewPane then
            self.previewPane:destroy()
            self.previewPane = nil
        end
        local menu = tes3ui.findMenu("Ashfall:ShapingMenu")
        if menu then
            menu:destroy()
            tes3ui.leaveMenuMode()
        end
    end)
    self.elements.cancelButton = cancelButton
    return cancelButton
end



function ShapingMenu:createConfirmButton(row)
    logger:debug("ShapingMenu:createConfirmButton() called")
    local confirmButton = row:createButton{ id = "Ashfall:ShapingMenuConfirmButton", text = "Confirm" }
    confirmButton:register("mouseClick", function()
        logger:debug("Confirm button clicked")

        --Confirm both shape and clay type are selected
        if not (self:checkRequirements()) then
            logger:warn("Confirm button clicked but shape or clay type not selected, ignoring")
            return
        end

        --Placeholder for confirming the pottery throwing
        --Would involve checking selected shape, clay type, and starting the bushcrafting process
        -- Clean up preview pane before destroying menu
        if self.previewPane then
            self.previewPane:destroy()
            self.previewPane = nil
        end
        local menu = tes3ui.findMenu("Ashfall:ShapingMenu")
        if menu then
            menu:destroy()
            tes3ui.leaveMenuMode()
            if self.okayCallback then
                local results = {
                    selectedShapeId = self.results.selectedShapeId,
                }
                self.okayCallback(results)
            end
        end
    end)
    self.elements.confirmButton = confirmButton
    return confirmButton
end


function ShapingMenu:createRequirementsStats(column)
    logger:debug("ShapingMenu:createRequirementsStats() called")

    local statsPane = column:createBlock{ id = "Ashfall:PotteryRequirementsStatsPane" }
    statsPane.widthProportional = 1.0
    statsPane.autoHeight = true
    statsPane.minHeight = 120
    statsPane.flowDirection = "top_to_bottom"
    statsPane.paddingAllSides = 8

    self:createTitle(statsPane, "Requirements")

    self.elements.requirementsStats = statsPane
    return statsPane
end

function ShapingMenu:createPreview(previewContainer)
    logger:debug("ShapingMenu:createPreview() called")


    local title = self:createTitle(previewContainer, "Preview")
    title.borderAllSides = 8

    local block = previewContainer:createBlock{ id = "Ashfall:PotteryPreviewBlock" }
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
function ShapingMenu:createShapeList(column)
    logger:debug("ShapingMenu:createShapeList() called")

    local shapeListBlock = column:createBlock{ id = "Ashfall:PotteryShapeListBlock" }
    shapeListBlock.widthProportional = 1.0
    shapeListBlock.heightProportional = 1.0
    shapeListBlock.autoHeight = true
    shapeListBlock.autoWidth = true
    shapeListBlock.flowDirection = "top_to_bottom"
    shapeListBlock.paddingLeft = 8
    shapeListBlock.paddingRight = 8

    self:createTitle(shapeListBlock, "Shapes")

    local shapeList = shapeListBlock:createVerticalScrollPane{ id = "Ashfall:PotteryShapeList" }
    shapeList.widthProportional = 1.0
    shapeList.minHeight = 150
    shapeList.maxHeight = 300


    for _, recipe in ipairs(self.recipes) do
        local requiresCorrectAmount = recipe.clayAmount == self.clayAmount
        local shapeButton = shapeList:createTextSelect{
             id = "Ashfall:PotteryShapeButton_" .. recipe.id,
             text = recipe.name
        }

        if not requiresCorrectAmount then
            shapeButton.color = tes3ui.getPalette(tes3.palette.disabledColor)
            shapeButton.widget.state = tes3.uiState.disabled
        end

        shapeButton:register("mouseClick", function()
            logger:debug("Selected shape: %s", recipe.id)
            self.results.selectedShapeId = recipe.id
            self:update()
        end)
    end


    self.elements.shapeList = shapeList
    return shapeList
end


---@param row tes3uiElement
---@param text string
---@return tes3uiElement
function ShapingMenu:createTitle(row, text)
    logger:debug("ShapingMenu:createTitle() called")
    local title = row:createLabel{ text = text }
    title.autoHeight = true
    title.widthProportional = 1.0
    title.justifyText = "left"
    title.wrapText = true
    title.color = tes3ui.getPalette("header_color")
    title.borderTop = 6
    return title
end


function ShapingMenu:createRow(menu)
    logger:debug("ShapingMenu:createRow() called")
    local row = menu:createBlock{ id = "Ashfall:ShapingMenuRow" }
    row.flowDirection = "left_to_right"
    row.widthProportional = 1.0
    row.autoWidth = true
    row.autoHeight = true
    return row
end


function ShapingMenu:createColumn(row)
    logger:debug("ShapingMenu:createColumn() called")
    local column = row:createThinBorder{ id = "Ashfall:ShapingMenuColumn" }
    column.flowDirection = "top_to_bottom"
    column.autoWidth = true
    column.autoHeight = true

    return column
end


function ShapingMenu:createMenu()
    logger:debug("ShapingMenu:createMenu() called")
    local menu = tes3ui.createMenu{ id = "Ashfall:ShapingMenu", fixedFrame = true }
    tes3ui.enterMenuMode(menu.id)

    menu.absolutePosAlignX = 0.5
    menu.absolutePosAlignY = 0.5
    menu:getContentElement().paddingAllSides = 12
    self.elements.menu = menu
    return menu
end

-------------------
--Update functions
-------------------


function ShapingMenu:update()
    logger:debug("ShapingMenu:update() called")

    self:updateConfirmButton()
    self:updateRequirementsStats()
    self:updatePreview()
    self.elements.menu:updateLayout()
end


function ShapingMenu:updatePreview()
    if not self.previewPane then
        logger:warn("PreviewPane not found, cannot update")
        return
    end

    if not self.results.selectedShapeId then
        logger:debug("No shape selected, hiding preview")
        self.previewPane:updatePreview(nil)
        return
    end

    -- Find the selected recipe
    local recipe = self:getRecipe(self.results.selectedShapeId)

    if not recipe then
        logger:warn("Recipe not found for shape: %s", self.results.selectedShapeId)
        self.previewPane:updatePreview(nil)
        return
    end

    -- Get the item object for the recipe result
    local item = tes3.getObject(recipe.id)
    if not item then
        logger:warn("Item not found for recipe: %s", recipe.id)
        self.previewPane:updatePreview(nil)
        return
    end

    ---@type CraftingFramework.PreviewPane.PreviewData
    local previewData = {
        item = item,
        rotationAxis = 'z', -- Pottery items typically rotate around Z axis
    }

    logger:debug("Updating preview with item: %s", item.id)
    self.previewPane:updatePreview(previewData)

    local nifBlock = self.previewPane:getNifElement()
    if self.hasTemper then
        local decals = Decals.get("temper") --[[@as Ashfall.Clay.PotteryDecals]]
        decals:applyDecal(nifBlock.sceneNode)
    end
end

function ShapingMenu:checkRequirements()
    --Check if both shape and clay type are selected
    if not self.results.selectedShapeId then
        return false
    end

    local recipe = self:getRecipe(self.results.selectedShapeId)
    if not recipe then
        logger:warn("Recipe not found for selected shape: %s", self.results.selectedShapeId)
        return false
    end

    --Check clay amount matches recipe requirement
    if recipe.clayAmount ~= self.clayAmount then
        return false
    end

    --Check pottery skill requirement
    local potterySkill = common.skills.pottery.current
    if potterySkill < recipe.difficulty then
        return false
    end

    return true
end

function ShapingMenu:getRecipe(id)
    return self.recipeDict[id]
end

function ShapingMenu:updateRequirementsStats()
    logger:debug("ShapingMenu:updateRequirementsStats() called")
    local stats = self.elements.requirementsStats
    if not stats then
        logger:warn("Requirements stats element not found, cannot update")
        return
    end

    stats:destroyChildren()

    --Shape selected
    if self.results.selectedShapeId then
        local recipe = self:getRecipe(self.results.selectedShapeId)
        if recipe then
            ---@cast recipe Ashfall.PotteryRecipe

            local clayObject = tes3.getObject(self.clayId)
            if not clayObject then
                logger:warn("Clay object not found: %s", self.clayId)
                return
            end

            local shapeLabel = stats:createLabel{ text = "Requirements:" }
            shapeLabel.color = tes3ui.getPalette(tes3.palette.headerColor)

            local clayName = self.hasTemper and "Tempered Clay" or "Raw Clay"
            local clayText = string.format("%s x%s", clayName, recipe.clayAmount)
            local clayLabel = stats:createLabel{ text = clayText }

            local hasClay = (recipe.clayAmount == self.clayAmount)
            if not hasClay then
                clayLabel.color = tes3ui.getPalette(tes3.palette.disabledColor)
            end

            local difficulty = recipe.difficulty or 0
            local currentSkill = common.skills.pottery.current
            local skillLabel = stats:createLabel{ text = string.format("Pottery Skill: %s/%s", currentSkill, difficulty) }

            if currentSkill < recipe.difficulty then
                skillLabel.color = tes3ui.getPalette(tes3.palette.disabledColor)
            end

        else
            local promptLabel = stats:createLabel{ text = "Select a shape and clay type\nto see requirements." }
            promptLabel.widthProportional = 1.0
            promptLabel.wrapText = true
        end
    else
        local promptLabel = stats:createLabel{ text = "Select a shape to see requirements." }
        promptLabel.widthProportional = 1.0
        promptLabel.wrapText = true
    end

end


function ShapingMenu:updateConfirmButton()
    logger:debug("ShapingMenu:updateConfirmButton() called")
    local confirmButton = self.elements.confirmButton
    if not confirmButton then
        logger:warn("Confirm button not found, cannot update")
        return
    end

    local requirementsMet = self:checkRequirements()
    confirmButton.disabled = not requirementsMet
    confirmButton.widget.state = requirementsMet and tes3.uiState.normal or tes3.uiState.disabled
end


return ShapingMenu