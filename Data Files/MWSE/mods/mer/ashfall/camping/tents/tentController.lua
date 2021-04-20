local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local tentConfig = require("mer.ashfall.camping.tents.tentConfig")
local coverController = require("mer.ashfall.camping.tents.coverController")
local trinketController = require("mer.ashfall.camping.tents.trinketController")
local temperatureController = require("mer.ashfall.temperatureController")
--temperatureController.registerExternalHeatSource{ id = "tentTemp" }
temperatureController.registerBaseTempMultiplier{ id = "tentTempMulti"}
local skipActivate



local function getActiveFromMisc(miscRef)
    return tentConfig.tentMiscToActiveMap[miscRef.object.id:lower()]
end

local function getMiscFromActive(activeRef)
    return tentConfig.tentActivetoMiscMap[activeRef.object.id:lower()]
end

local function getTentCoverage(ref)
    --if coverController.tentHasCover()
end

local function canUnpack()
    if  common.helper.getInside() then
        return false
    end
    if tes3.player.cell.restingIsIllegal then
        if not config.canCampInSettlements then
            return false
        end
    end 
    return true
end

local function unpackTent(miscRef)
    timer.delayOneFrame(function()
        tes3.createReference {
            object = getActiveFromMisc(miscRef),
            position = {
                miscRef.position.x,
                miscRef.position.y,
                miscRef.position.z - 10,
            },
            orientation = miscRef.orientation:copy(),
            cell = miscRef.cell
        }
    
        tes3.runLegacyScript{ command = 'Player->Drop "ashfall_resetlight" 1'}

        common.helper.yeet(miscRef)
    end) 
end

local function packTent(activeRef)
    timer.delayOneFrame(function()
        -- tes3.createReference {
        --     object = getMiscFromActive(activeRef),
        --     position = activeRef.position:copy(),
        --     orientation = activeRef.orientation:copy(),
        --     cell = activeRef.cell
        -- }
        -- tes3.runLegacyScript{ command = 'Player->Drop "ashfall_resetlight" 1'}
        mwscript.addItem{
            reference = tes3.player,
            item = getMiscFromActive(activeRef),
            count =  1
        }
        if activeRef.data.trinket then
            mwscript.addItem{
                reference = tes3.player,
                item = activeRef.data.trinket,
                count =  1,
                playSound = false
            }
        end
        if activeRef.data.tentCover then
            mwscript.addItem{
                reference = tes3.player,
                item = activeRef.data.tentCover,
                count =  1,
                playSound = false
            }
        end
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
        common.helper.yeet(activeRef)
    end)
end


local function packedTentMenu(miscRef)
    local message = miscRef.object.name
    local buttons = {
        {
            text = "Unpack",
            requirements = canUnpack,
            tooltipDisabled = { 
                text = "You can't unpack your tent here."
            },
            callback = function()
                unpackTent(miscRef)
            end
        },
        {
            text = "Pick Up",
            callback = function()
                timer.delayOneFrame(function()
                    skipActivate = true
                    tes3.player:activate(miscRef)
                end)
            end
        },
    }
    common.helper.messageBox{
        message = message, 
        buttons = buttons,
        doesCancel = true
    }
end

local function selectCover(tentRef)
    timer.delayOneFrame(function()
        tes3ui.showInventorySelectMenu{
            title = "Select Tent Cover",
            noResultsText = "You don't have any tent covers.",
            filter = function(e)
                return tentConfig.coverToMeshMap[e.item.id:lower()] ~= nil
            end,
            callback = function(e)
                if e.item then
                    common.log:debug("attaching trinket")
                    coverController.attachCover(tentRef, e.item.id)
                end
            end
        }
    end)
end

local function selectTrinket(tentRef)
    timer.delayOneFrame(function()
        tes3ui.showInventorySelectMenu{
            title = "Select Trinket",
            noResultsText = "You don't have any trinkets.",
            filter = function(e)
                return tentConfig.trinketToMeshMap[e.item.id:lower()] ~= nil
            end,
            callback = function(e)
                if e.item then
                    common.log:debug("attaching trinket")
                    trinketController.attachTrinket(tentRef, e.item.id)
                end
            end
        }
    end)
end


local function activeTentMenu(activeRef)
    local message = activeRef.object.name
    local buttons = {
        {
            text = "Attach Cover",
            showRequirements = function() 
                return coverController.canHaveCover(activeRef)
                    and not coverController.tentHasCover(activeRef)
            end,
            callback = function()
                selectCover(activeRef)
            end
        },
        {
            text = "Remove Cover",
            showRequirements = function() 
                return coverController.canHaveCover(activeRef)
                    and coverController.tentHasCover(activeRef)
            end,
            callback = function()
                coverController.removeCover(activeRef)
            end
        },
        {
            text = "Attach Trinket",
            showRequirements = function() 
                return trinketController.canHaveTrinket(activeRef)
                    and not trinketController.tentHasTrinket(activeRef)
            end,
            callback = function()
                selectTrinket(activeRef)
            end
        },
        {
            text = "Remove Trinket",
            showRequirements = function() 
                return trinketController.canHaveTrinket(activeRef)
                    and trinketController.tentHasTrinket(activeRef)
            end,
            callback = function()
                trinketController.removeTrinket(activeRef)
            end
        },
        {
            text = "Pack Up",
            callback = function() packTent(activeRef) end
        },
    }
    common.helper.messageBox{
        message = message, 
        buttons = buttons,
        doesCancel = true
    }
end



local function activateTent(e)
    --Check if it's a misc tent ref
    if getActiveFromMisc(e.target) then
        --Skip if picking up
        if skipActivate then
            skipActivate = false
            return
        end
        --Pick up if underwater
        if common.helper.getRefUnderwater(e.target) then
            return
        end
        --Pick up if activating while in inventory
        if tes3ui.menuMode() then
            return
        end
        --checks cleared activate packed tent
        packedTentMenu(e.target)
        return false
    --Check if it's an activator tent ref
    elseif getMiscFromActive(e.target) then
        activeTentMenu(e.target)
        return false
    end
end
event.register("activate", activateTent)


local currentTent --not on data because it's not json serialisable
local function setTentTempMulti()
    local tempMulti
    if (not common.data.insideTent)  or ( not currentTent ) then
        --not in a tent, no multiplier
        tempMulti = 1.0
    elseif not coverController.canHaveCover(currentTent) then
        --in a legacy tent, set to full multi
        tempMulti = tentConfig.tempMultis.legacy
    elseif coverController.tentHasCover(currentTent) then
        --in modular tent with cover, get from cover
        local coverId = currentTent.data.tentCover:lower()
        tempMulti = tentConfig.tempMultis[coverId]
    else
        --in modular tent, no cover, set to uncovered
        tempMulti = tentConfig.tempMultis.uncovered
    end
    common.data.tentTempMulti = tempMulti
end

local function setTentCoverage()

end

local function setTentSwitchNodes()
    if currentTent then
        --switch base tent
        local tentNode = currentTent.sceneNode:getObjectByName("TENT")
        if tentNode then
            local canvasNode = tentNode:getObjectByName("SWITCH_CANVAS")
            if canvasNode then
                canvasNode.switchIndex = common.data.insideTent and 1 or 0
            end
        end
        --switch cover
        local tentCover = currentTent.sceneNode:getObjectByName("ATTACH_COVER")
        if tentCover then
            local canvasNode = tentCover:getObjectByName("SWITCH_CANVAS")
            if canvasNode then
                canvasNode.switchIndex = common.data.insideTent and 1 or 0
            end
        end
    end
end

local function setTent(e)
    local insideTent = e.insideTent
    if e.tent then currentTent = e.tent end
    if (not currentTent) or (not currentTent.sceneNode) then currentTent = nil end
    common.data.insideTent = insideTent
    common.data.hasTentCover = coverController.tentHasCover(currentTent)
    setTentTempMulti()
    setTentCoverage()
    setTentSwitchNodes()
end
event.register("Ashfall:SetTent", setTent)


local function toggleTentCollision(e)
    common.log:debug("toggleTentCollision")
    if currentTent and currentTent.sceneNode then
        local collisionNode = currentTent.sceneNode:getObjectByName("Collision")
        if collisionNode then
            common.log:debug("setting tent collision to %s", e.collision)
            if e.collision == true then
                collisionNode.scale = 1.0
            else
                collisionNode.scale = 0.0
            end
            currentTent:updateSceneGraph()
        end
    end
end
event.register("Ashfall:ToggleTentCollision", toggleTentCollision)


--If in tent, enemies outside won't prevent rest
local function checkTentEnemyPreventRest(e)
    if common.helper.getInTent() then
        local doAllowRest = (
            e.mobile.inCombat ~= true and
            e.reference.position:distance(tes3.player.position) > 1000
        )
        if doAllowRest then
            return false
        end
    end
end
event.register("preventRest", checkTentEnemyPreventRest)


--When sleeping in a tent, you can't be woken up by creatures
local function calcRestInterrupt(e)
    if common.helper.getInTent()  then
        e.count = 0
    end
end
event.register("calcRestInterrupt", calcRestInterrupt)