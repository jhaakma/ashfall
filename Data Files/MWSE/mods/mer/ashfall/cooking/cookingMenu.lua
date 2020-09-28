
local common = require("mer.ashfall.common.common")
local recipes = require("mer.ashfall.cooking.recipes")
local utensils = require("mer.ashfall.cooking.utensils")

local CookingMenu = {}
CookingMenu.name = "Cooking Menu"
CookingMenu.utensil = utensils.cookingPot
CookingMenu.elements = {}
CookingMenu.selectedRecipe = ""
CookingMenu.sCook = "Cook"
--UI 
CookingMenu.padding = 8
CookingMenu.menuWidth = 600
CookingMenu.menuHeight = 500
CookingMenu.menuUID = tes3ui.registerID("Ashfall_CookingMenu")
CookingMenu.eventRecipeSelected = "Ashfall_RecipeSelected"
CookingMenu.selectedColor = tes3ui.getPalette("disable_color")--{0/255, 30/255, 70/255}
CookingMenu.selectedAlpha = 0.15

function CookingMenu:new(data)
    local t = data or {}
    t.recipes = recipes[self.utensil.recipeType]
    --Make recipe objects
    for i = 1, #t.recipes do
        t.recipes[i] = t.recipes[i]
    end
    setmetatable(t, self)
    self.__index = self
    return t
end 

function CookingMenu:createThinBorder(parentBlock)
    local thinBorder = parentBlock:createThinBorder()
    thinBorder.widthProportional = 1.0
    thinBorder.heightProportional = 1.0
    thinBorder.autoHeight = true
    thinBorder.paddingAllSides = self.padding
    return thinBorder
end

function CookingMenu:createBlock(parentBlock)
    local block = parentBlock:createBlock()
    block.autoHeight = true
    block.widthProportional = 1.0
    block.heightProportional = 1.0
    return block
end


function CookingMenu:createMenu()
    common.log:info("Creating Cooking menu")
    local menu = tes3ui.createMenu{ id = self.menuUID, fixedFrame = true }
    tes3ui.enterMenuMode(self.menuUID)
    self.elements.menu = menu
end

function CookingMenu:createOuterContainer(parentBlock)
    local outerContainer = parentBlock:createBlock()
    outerContainer.flowDirection = "top_to_bottom"
    outerContainer.width  = self.menuWidth
    outerContainer.height = self.menuHeight
    self.elements.outerContainer = outerContainer
end

function CookingMenu:createTitle(parentBlock)
    local titleBlock = parentBlock:createBlock()
    titleBlock.widthProportional = 1.0
    titleBlock.autoHeight = true
    titleBlock.paddingBottom = self.padding

    local title = titleBlock:createLabel({ text = self.name })
    title.absolutePosAlignX = 0.5
    title.color = tes3ui.getPalette("header_color")

    self.elements.titleBlock = titleBlock
    self.elements.title = title
end

function CookingMenu:createInnerContainer(parentBlock)
    local innerContainer = self:createBlock(parentBlock)
    innerContainer.flowDirection = "left_to_right"
    innerContainer.autoHeight = true
    self.elements.innerContainer = innerContainer
end

--Left block: Recipe List

function CookingMenu:createLeftBlock(parentBlock)

    local outerBlock = self:createBlock(parentBlock)
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.borderAllSides = self.padding

    local header = outerBlock:createLabel({ text = "Known Recipes:" })
    header.borderAllSides = 4
    header.color = tes3ui.getPalette("header_color")

    local scrollPane = outerBlock:createVerticalScrollPane()
    scrollPane.widthProportional = 1.0
    scrollPane.heightProportional = 1.0
    self.elements.leftBlock = scrollPane
end



function CookingMenu:createRecipeSelect(parentBlock, recipe)
    common.log:info("recipeID on create: %s", recipe.id)
    local background = parentBlock:createRect({ id = tes3ui.registerID(recipe.id)})
    background.widthProportional = 1.0
    background.autoHeight = true
    background.alpha = self.selectedAlpha
    background.paddingAllSides = self.padding - 4
    local recipeSelect = background:createTextSelect({ id = "recipe", text = recipe.name })   
    
    
    recipeSelect:register(
        "mouseClick", 
        function()
            self:selectRecipe({ buttonBlock = background, recipe = recipe })
        end
    )
end

function CookingMenu:createRecipeList(parentBlock)
    local recipeList = parentBlock:createBlock()
    recipeList.flowDirection = "top_to_bottom"
    recipeList.widthProportional = 1.0
    recipeList.autoHeight = true
    self.elements.recipeList = recipeList

    common.log:info("%s type = %s", self.utensil.name, self.utensil.recipeType)
    for _, recipe in pairs(self.recipes) do
        self:createRecipeSelect(recipeList, recipe )
    end
end


--Right block: Results pane



function CookingMenu:createListContainer(parentBlock, labelText)
    local label = parentBlock:createLabel{ text = labelText }
    label.borderBottom = 4

    local pane = parentBlock:createThinBorder()
    pane.autoHeight = true
    pane.widthProportional = 1.0
    pane.autoHeight = true
    pane.flowDirection = "top_to_bottom"
    pane.paddingLeft = self.padding
    pane.paddingRight = self.padding
    pane.paddingTop = self.padding / 2
    pane.paddingBottom = self.padding / 2
    pane.borderBottom = self.padding
    return pane
end


function CookingMenu:createIngredientsList(parentBlock, recipe)

    local function createIngredientItem(parent, ingredient)
        local ingredBlock = parent:createBlock()
        ingredBlock.widthProportional = 1.0
        ingredBlock.autoHeight = true
        ingredBlock.flowDirection = "left_to_right"
        ingredBlock.borderBottom = 2

        local ingredientLabel = ingredBlock:createLabel({ text = ingredient.name})
        ingredientLabel.widthProportional = 1.0

        local playerCount = recipe:getPlayerIngredientCount(ingredient)
        local countLabelText = string.format("(%s/%s)", playerCount, ingredient.count)
        local countLabel = ingredBlock:createLabel({ text = countLabelText})

        --Set disable color if player doesn't have the ingreds
        if not recipe:checkIngredient(ingredient) then
            ingredientLabel.color = tes3ui.getPalette("disabled_color")
            countLabel.color = tes3ui.getPalette("disabled_color")
        end
    end

    local ingredientsList = self:createListContainer(parentBlock, "Ingredients:")
    for _, ingredient in ipairs(recipe.ingredients) do
        createIngredientItem(ingredientsList, ingredient)
    end

end




function CookingMenu:createEffectsList(parentBlock, recipe)

    local function makeEffectBlock(parent)
        local block = parent:createBlock()
        block.widthProportional = parent.widthProportional
        block.autoWidth = parent.autoWidth
        block.autoHeight = parent.autoHeight
        block.paddingBottom = self.padding / 2
        block.paddingTop = self.padding / 2
        block.flowDirection = "left_to_right"
        return block
    end

    local function createEffectItem(parent, effect)
        local block = makeEffectBlock(parent)

        local imagePath = string.format("icons\\%s", effect.object.icon)
        local icon = block:createImage{ path = imagePath, id = tes3ui.registerID("effectIcon") }
        icon.borderAllSides = 4

        local labelBlock = block:createBlock()
        labelBlock.flowDirection = "top_to_bottom"
        labelBlock.widthProportional = 1.0
        labelBlock.autoHeight = true

        local labelText = string.format("%s", effect)
        local label = labelBlock:createLabel({ text = labelText })
        label.wrapText = true
        label.widthProportional = 1.0
        label.borderLeft = self.padding

        labelBlock:getTopLevelParent():updateLayout()
    end

    local effectsPane = self:createListContainer(parentBlock, "Effects:")
    effectsPane.heightProportional = 1.0
    effectsPane.borderBottom = 0
    if recipe.meal.spellId then
        local durationText = string.format("Duration: %s hours", recipe.meal.duration)
        local durationBlock = makeEffectBlock(effectsPane)
        local label = durationBlock:createLabel({ text = durationText })
        label.borderLeft = 4

        local spell = tes3.getObject(recipe.meal.spellId)
        if spell then
            for _, effect in ipairs(spell.effects) do
                if effect.id > 0 then
                    createEffectItem(effectsPane, effect)
                end
            end
        else
            common.log:info("Spell not found")
        end
    end

end

function CookingMenu:createDuration(parentBlock, recipe)
    local durationPane = self:createListContainer(parentBlock, "Cooking Time:")
    durationPane.paddingTop = 2
    durationPane.paddingBottom = 4

    local text = string.format("%s minutes", recipe.duration)
    durationPane:createLabel({ text = text })
end


function CookingMenu:updateButtonStates()

    local states = {
        normal = 1, 
        disabled = 2, 
        active = 4
    }
    --Update the states of all the buttons based on ingredients available
    for _, recipe in ipairs(self.recipes) do
        local buttonBlock = self.elements.recipeList:findChild(tes3ui.registerID(recipe.id))
        buttonBlock.color = tes3ui.getPalette("black_color")

        local button = buttonBlock.children[1]
        local state = recipe:checkIngredients() and states.normal or states.disabled
        button.widget.state = state
        --Trigger leave to make sure the text color updates immediately
        button:triggerEvent("mouseLeave")
    end

    --Highlight the selected recipe button
    local activeButtonBlock = self.elements.recipeList:findChild(tes3ui.registerID(self.selectedRecipe.id))
    activeButtonBlock.color = self.selectedColor
    activeButtonBlock.children[1]:triggerEvent("mouseLeave")
    
    --Disable the cook button if you don't have enough ingredients
    self.elements.cookButton.widget.state = self.selectedRecipe:checkIngredients() and states.normal or states.disabled
end

function CookingMenu:selectRecipe(e)
    local recipe = e.recipe
    self.selectedRecipe = recipe

    self:updateButtonStates( )
    
    local parentBlock = self.elements.rightBlock
    parentBlock:destroyChildren()
    
    self:createDuration(parentBlock, recipe)
    self:createIngredientsList(parentBlock, recipe)
    self:createEffectsList(parentBlock, recipe)

    parentBlock:getTopLevelParent():updateLayout()
end



function CookingMenu:createRightBlock(parentBlock)

    local outerBlock = self:createBlock(parentBlock)
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.borderAllSides = self.padding
    
    local header = outerBlock:createLabel({ text = "Results:" })
    header.borderAllSides = 4
    header.color = tes3ui.getPalette("header_color")

    local container = self:createThinBorder(outerBlock)
    container.flowDirection = "top_to_bottom"
    container.paddingAllSides = self.padding

    self.elements.rightBlock = container
        
end



--Bottom block: Cook/close buttons

function CookingMenu:createBottomBar(parentBlock)
    local block = parentBlock:createBlock()
    block.autoHeight = true
    block.widthProportional = 1.0
    block.childAlignX = 1.0
    block.paddingRight = self.padding - 4

    --Cook button, only enabled when you have ingredients
    local cookButton = block:createButton({ text = self.sCook })
    cookButton:register(
        "mouseClick", 
        function()
            self:cookMeal()
        end 
    )
    self.elements.cookButton = cookButton

    --Close button
    local sClose = tes3.findGMST(tes3.gmst.sClose).value
    local closeButton = block:createButton({ text = sClose })
    closeButton:register(
        "mouseClick",
        function()
            self:close()
        end
    )

end

function CookingMenu:create()
    self:createMenu()
    --Outer components
    self:createOuterContainer( self.elements.menu )
    self:createTitle( self.elements.outerContainer )
    self:createInnerContainer( self.elements.outerContainer )
    --Left side: recipes
    self:createLeftBlock( self.elements.innerContainer )
    self:createRecipeList( self.elements.leftBlock )
    --Right side: results
    self:createRightBlock( self.elements.innerContainer )

    --Bottom: buttons
    self:createBottomBar(self.elements.outerContainer)

    --Select the top recipe
    self:selectRecipe({ 
        buttonBlock = self.elements.recipeList.children[1], 
        recipe = self.recipes[1]
    })

    self.elements.menu:getTopLevelParent():updateLayout()
end

function CookingMenu:close()
    tes3ui.findMenu(self.menuUID):destroy()
    tes3ui.leaveMenuMode()
end

function CookingMenu:cookMeal()
    local function finishCooking()
        --tes3.runLegacyScript({params})
        local meal = tes3.getObject(self.selectedRecipe.meal.id)
        tes3.messageBox("You have cooked %s", meal.name)
        mwscript.addItem({ reference = tes3.player, item = meal, count = 1})
        tes3.playItemPickupSound({ item = meal})
        --Remove ingredient
        for _, ingredTable in ipairs(self.selectedRecipe.ingredients) do
            local itemsLeft = ingredTable.count
            for _, id in ipairs(ingredTable.ids) do
                local count =  mwscript.getItemCount({ reference = tes3.player, item = id })
                local numToRemove = math.min(count, itemsLeft)
                mwscript.removeItem({ reference = tes3.player, item = id, count = numToRemove})
                itemsLeft = itemsLeft - numToRemove
                common.log.info("Removed %s %s", numToRemove, id)
            end    
        end
    end

    if self.selectedRecipe:checkIngredients() then
        self:close()
        tes3.playSound({ sound = "ashfall_boil" })
        local hours = self.selectedRecipe.duration / 60
        common.helper.fadeTimeOut( hours, 2.5, finishCooking  )
    end
end

return CookingMenu