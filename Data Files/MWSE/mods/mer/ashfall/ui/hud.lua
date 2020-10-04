local this = {}

local common = require("mer.ashfall.common.common")
local statsEffect = require("mer.ashfall.needs.statsEffect")
local tempUI = require("mer.ashfall.ui.tempUI")

local blockerIdPattern ="Ashfall_%s_BlockBar"
local needsData = {
    hunger = {
        needId = "hunger",
        stat = "health",
        parentFillbarId = "MenuStat_health_fillbar",
        color = { 0.26, 0.25, 0.25 }
    },
    thirst = {
        needId = "thirst",
        stat = "magicka",
        parentFillbarId = "MenuStat_magic_fillbar",
        color = { 0.25, 0.25, 0.26 }
    },
    tiredness = {
        needId = "tiredness",
        stat = "fatigue",
        parentFillbarId = "MenuStat_fatigue_fillbar",
        color = { 0.25, 0.26, 0.25 }
    }
}

local function findElementInMultiMenu(id, menu)
    if menu then
        local element = menu:findChild(tes3ui.registerID(id))
        if element then
            return element
        else
            common.log:error("%s not found in menu", id)
        end
    end
end

function this.updateHUD()
    
    tempUI.updateHUD()
    local function updateNeed(needData, menu)
        local id = needData.needId
        local blockerBar = findElementInMultiMenu(string.format(blockerIdPattern, id), menu)
        if blockerBar then
            local ratio = statsEffect.getMaxStat(needData.stat) / tes3.mobilePlayer[needData.stat].base
            local parentWidth = blockerBar.parent.width
            local newWidth =  parentWidth - parentWidth * ratio
            if newWidth > 0 then
                newWidth = math.remap( newWidth, 0, parentWidth, 2, parentWidth - 2)
            end
            blockerBar.width = newWidth
        end
    end

    --HUD
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    if menu then
        for _, needData in pairs(needsData) do
            updateNeed(needData, menu)
        end
        menu:updateLayout()
    end
    --Stats menu
    menu = tes3ui.findMenu(tes3ui.registerID("MenuStat"))
    if menu then
        for _, needData in pairs(needsData) do
            updateNeed(needData, menu)
        end
        menu:updateLayout()
    end
end

local function addBlockerBar(parent, needData)
    local blockBar = parent:createThinBorder{ id  = tes3ui.registerID(string.format(blockerIdPattern, needData.needId)) }
    blockBar.absolutePosAlignX = 1.0
    blockBar.absolutePosAlignY = 0.0
    blockBar.height = blockBar.parent.height
    blockBar.paddingAllSides = 2
    blockBar.borderBottom = 6
    blockBar.borderRight = 1
    local filler = blockBar:createRect{}
    filler.color = needData.color
    filler.widthProportional = 1.0
    filler.heightProportional = 1.0
end

local function forceUpdate()
    --An annoying hacky way to force update the UIs so the text actually goes behind the blocker bars
    tes3.setStatistic({
        reference = tes3.mobilePlayer,
        current = tes3.mobilePlayer.health.current + 1,
        name = "health"
    })
    tes3.setStatistic({
        reference = tes3.mobilePlayer,
        current = tes3.mobilePlayer.magicka.current + 1,
        name = "magicka"
    })
    tes3.setStatistic({
        reference = tes3.mobilePlayer,
        current = tes3.mobilePlayer.fatigue.current + 1,
        name = "fatigue"
    })

    tes3.setStatistic({
        reference = tes3.mobilePlayer,
        current = tes3.mobilePlayer.health.current -1,
        name = "health"
    })
    tes3.setStatistic({
        reference = tes3.mobilePlayer,
        current = tes3.mobilePlayer.magicka.current -1,
        name = "magicka"
    })
    tes3.setStatistic({
        reference = tes3.mobilePlayer,
        current = tes3.mobilePlayer.fatigue.current -1,
        name = "fatigue"
    })
end


local function updateStatsText()
    if not common.data then return end
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuStat"))
    if menu then
        for _, needData in pairs(needsData) do
            local parentFillbar = findElementInMultiMenu(needData.parentFillbarId, menu)
            local label = parentFillbar:findChild(tes3ui.registerID("PartFillbar_text_ptr"))
            local stat = tes3.mobilePlayer[needData.stat]
            local newLabel =  string.format("%.0f/%d",  stat.current, statsEffect.getMaxStat(needData.stat) )

            label.text = newLabel
            parentFillbar:updateLayout()
        end
    end
end
event.register("uiRefreshed", updateStatsText)

local function createNeedsBlockers(e)

    local menu = e.element
    if menu then
        for _, needData in pairs(needsData) do
            local parentFillbar = findElementInMultiMenu(needData.parentFillbarId, menu)
            if e.newlyCreated then
                addBlockerBar(parentFillbar, needData)
                local text = parentFillbar:findChild(tes3ui.registerID("PartFillbar_text_ptr"))
                if text.visible == true then
                    parentFillbar:reorderChildren(parentFillbar:findChild(tes3ui.registerID("PartFillbar_text_ptr")), -1, 1)
                    parentFillbar:findChild(tes3ui.registerID("PartFillbar_text_ptr")):updateLayout()
                end
            end
        end

        forceUpdate()
    end
end


local function createMenuMultiNeedsUI(e)
    createNeedsBlockers(e)
    tempUI.createHUD(e)
end
event.register("uiActivated", createMenuMultiNeedsUI, { filter = "MenuMulti" })

local function createMenuStatNeedsUI(e)
    createNeedsBlockers(e)
end
event.register("uiActivated", createMenuStatNeedsUI, { filter = "MenuStat" })

local function updateTooltips()
    local helpMenu = tes3ui.findHelpLayerMenu(tes3ui.registerID("HelpMenu"))
    if helpMenu and helpMenu.visible == true then
        local text = helpMenu:findChild( tes3ui.registerID("text"))
        if text then
            local iconPath = string.lower(text.parent.parent.children[1].contentPath)
            for _, needData in pairs(needsData) do
                if string.find(iconPath, needData.stat) then
                    

                    local stat = tes3.mobilePlayer[needData.stat]
                    local maxStat = statsEffect.getMaxStat(needData.stat)
                    if maxStat < stat.base then
                        local valText = text.parent.children[2]
                        valText.text = string.format("%d/%d",stat.current, maxStat)

                        --Do once
                        local debuffText = text.parent:findChild( tes3ui.registerID("Ashfall_stat_debuff_text") )
                        if not debuffText then
                            --Show the base value
                            local baseValue = text.parent:createLabel({ id = tes3ui.registerID("Ashfall_stat_baseVal_text")})
                            baseValue.text = string.format("Base value: %d", stat.base)

                            --Show how much has been removed from the base value and why. E.g "Thirsty: -7"
                            debuffText = text.parent:createLabel({ id = tes3ui.registerID("Ashfall_stat_debuff_text")})
                            local newValueText
                            local stateText = common.staticConfigs.conditionConfig[needData.needId]:getCurrentStateData().text
                            local negValText = (stat.base - maxStat)
                            newValueText =  string.format("%s: -%d", 
                                stateText,
                                negValText
                            )
                            debuffText.text = newValueText
                            debuffText.color = tes3ui.getPalette("negative_color")
                        end
                    end
                    
                end
            end
        end
    end
end
event.register("enterFrame", updateTooltips)

return this