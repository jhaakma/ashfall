local this = {}
local common = require("mer.ashfall.common.common")
local ratingsCommon = require("mer.ashfall.tempEffects.ratings.ratings")


local function quickFormat(element, padding)
    element.paddingAllSides = padding
    element.autoHeight = true
    element.autoWidth = true
    return element
end





--[[
    Create warmth and coverage ratings inside the Character Box in the inventory menu
]]
local function createRatingsUI()
    local inventoryMenu = tes3ui.findMenu(tes3ui.registerID("MenuInventory"))
    if not inventoryMenu then
        return
    end
    local characterBox = inventoryMenu:findChild(tes3ui.registerID("MenuInventory_character_box"))
    local outerBlock = characterBox:findChild(tes3ui.registerID("Ashfall:armorRatings"))
    if not outerBlock then
        outerBlock = characterBox:createBlock({ id = tes3ui.registerID("Ashfall:armorRatings") })
        outerBlock.flowDirection = "left_to_right"
        outerBlock.paddingTop = 2
        outerBlock.paddingBottom = 2
        outerBlock.paddingLeft = 5
        outerBlock.paddingRight = 5
        outerBlock.autoWidth = true
        outerBlock.autoHeight = true 

        outerBlock:createLabel({ id = tes3ui.registerID("Ashfall:WarmthRating"), text = "" }) 

        local coverageText = "Coverage: "
        outerBlock:createLabel({ id = tes3ui.registerID("Ashfall:CoverageRating"), text = "" }) 
        inventoryMenu:updateLayout()
    end
end
event.register("uiCreated", createRatingsUI, { filter = "MenuInventory" } )

--[[
    Update the warmth/coverage ratings in character box
]]
function this.updateRatingsUI()
    if not common.data then return end

    local inventoryMenu = tes3ui.findMenu(tes3ui.registerID("MenuInventory"))
    if inventoryMenu then
        local warmthLabel = inventoryMenu:findChild(tes3ui.registerID("Ashfall:WarmthRating"))
        local warmthValue = ratingsCommon.getAdjustedWarmth(common.data.warmthRating)
        warmthLabel.text = string.format("Warmth: %d    " , warmthValue)

        local coverageLabel = inventoryMenu:findChild(tes3ui.registerID("Ashfall:CoverageRating"))
        local coverageValue = ratingsCommon.getAdjustedCoverage(  common.data.coverageRating )
        coverageValue = math.clamp( coverageValue, 0, 100 )
        coverageLabel.text = string.format("Coverage: %d%%", coverageValue)

        inventoryMenu:updateLayout()
    end
end

local IDs = {
    ratingsBlock = tes3ui.registerID("Ashfall:ratingsBlock"),
    warmthBlock = tes3ui.registerID("Ashfall:ratings_warmthBlock"),
    warmthHeader = tes3ui.registerID("Ashfall:ratings_warmthHeader"),
    warmthValue = tes3ui.registerID("Ashfall:ratings_warmthValue"),
    coverageBlock = tes3ui.registerID("Ashfall:ratings_coverageBlock"),
    coverageHeader = tes3ui.registerID("Ashfall:ratings_coverageHeader"),
    coverageValue = tes3ui.registerID("Ashfall:ratings_coverageValue")
}

--[[
    Insert ratings into Equipment tooltips
]]
local function insertRatingsTooltips(e)

    if not common.config.getConfig().enableTemperatureEffects then
        return
    end

    local tooltip = e.tooltip
    if not e.tooltip then return end
    if not e.object then return end
    local slot
    local isValidSlot

    if e.object.objectType == tes3.objectType.armor then
        isValidSlot = ratingsCommon.isValidArmorSlot( e.object.slot )
    elseif e.object.objectType == tes3.objectType.clothing then
        isValidSlot = ratingsCommon.isValidClothingSlot( e.object.slot )
    end
    if isValidSlot then
        local partmenuID = tes3ui.registerID("PartHelpMenu_main")
        local innerBlock = tooltip:findChild(partmenuID):findChild(partmenuID):findChild(partmenuID)
       
        local statsIndex
        for i, element in ipairs(innerBlock.children) do
            if string.find(element.text, "Weight:") then
                statsIndex = i - 1
            end
            --But if Armor rating exists, put it after that
            if string.find(element.text, "Armor Rating:") then
                statsIndex = i 
                break
            end
        end
        
        
        local ratingsBlock = innerBlock:createBlock({ id = IDs.ratingsBlock })
        ratingsBlock.flowDirection = "top_to_bottom"
        ratingsBlock.paddingTop = 0
        ratingsBlock.paddingBottom = 0
        ratingsBlock.childAlignX  = 0.5
        ratingsBlock.autoWidth = true
        ratingsBlock.autoHeight = true
        
        local warmthBlock = ratingsBlock:createBlock({ id = IDs.warmthBlock })
        warmthBlock.flowDirection = "left_to_right"
        warmthBlock.autoWidth = true
        warmthBlock.childAlignX  = 0.5
        warmthBlock.autoHeight = true
        
        local warmthHeader = warmthBlock:createLabel({ id = IDs.warmthHeader, text = "Warmth: " })
        quickFormat(warmthHeader)
        --warmthHeader.color = tes3ui.getPalette("header_color")
        
        local warmth = ratingsCommon.getItemWarmth( e.object )
        local warmthText = string.format(" %d", warmth)
        local warmthValue = warmthBlock:createLabel({ id = IDs.warmthValue, text = warmthText })
        warmthValue.autoHeight = true
        warmthValue.autoWidth = true
        
        local coverageBlock = ratingsBlock:createBlock({ id = IDs.coverageBlock })
        coverageBlock.flowDirection = "left_to_right"
        coverageBlock.autoWidth = true
        coverageBlock.childAlignX  = 0.5
        coverageBlock.autoHeight = true
        
        local coverageHeader = coverageBlock:createLabel({ id = IDs.coverageHeader, text = "Coverage: " })
        quickFormat(coverageHeader)
        --coverageHeader.color = tes3ui.getPalette("header_color")
        
        local coverage = ratingsCommon.getAdjustedCoverage( ratingsCommon.getItemCoverage( e.object ) )
        local coverageText = string.format(" %d", coverage )
        local coverageValue = coverageBlock:createLabel({ id = IDs.coverageValue, text = coverageText })
        coverageValue.autoHeight = true
        coverageValue.autoWidth = true            
        
        innerBlock:reorderChildren( statsIndex, ratingsBlock, -1 )
        innerBlock:updateLayout()
    end
end
event.register("uiObjectTooltip", insertRatingsTooltips )


local function checkAshfallEnabled()
    local inventoryMenu = tes3ui.findMenu(tes3ui.registerID("MenuInventory"))
    if inventoryMenu then
        local outerBlock = inventoryMenu:findChild(tes3ui.registerID("Ashfall:armorRatings"))
        outerBlock.visible = common.config.getConfig().enableTemperatureEffects
    end
end

event.register("menuEnter", checkAshfallEnabled )

return this