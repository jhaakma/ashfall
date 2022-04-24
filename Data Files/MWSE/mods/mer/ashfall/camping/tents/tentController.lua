local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config").config
local tentConfig = require("mer.ashfall.camping.tents.tentConfig")
local coverController = require("mer.ashfall.camping.tents.coverController")
local trinketController = require("mer.ashfall.camping.tents.trinkets.trinketController")
local lanternController = require("mer.ashfall.camping.tents.lanternController")
local temperatureController = require("mer.ashfall.temperatureController")
--temperatureController.registerExternalHeatSource{ id = "tentTemp" }
temperatureController.registerBaseTempMultiplier{ id = "tentTempMulti"}
local skipActivate
local currentTent


local function getActiveFromMisc(miscRef)
    return tentConfig.tentMiscToActiveMap[miscRef.object.id:lower()]
end

local function getMiscFromActive(activeRef)
    return tentConfig.tentActivetoMiscMap[activeRef.object.id:lower()]
end

event.trigger("Ashfall:RegisterReferenceController", {
    id = "tent",
    requirements = function(_, ref)
        return getMiscFromActive(ref)
    end
})

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
        local newTent = tes3.createReference {
            object = getActiveFromMisc(miscRef),
            position = {
                miscRef.position.x,
                miscRef.position.y,
                miscRef.position.z - 10,
            },
            orientation = miscRef.orientation:copy(),
            cell = miscRef.cell
        }
        newTent:updateLighting()
        event.trigger("Ashfall:registerReference", { reference = newTent})
        common.helper.yeet(miscRef)
        tes3.playSound{ sound = "Item Misc Up", reference = tes3.player }
    end)
end

local function packTent(activeRef)
    timer.delayOneFrame(function()
        tes3.addItem{
            reference = tes3.player,
            item = getMiscFromActive(activeRef),
            count =  1,
            playSound = false,
        }
        if activeRef.data.trinket then
            trinketController.removeTrinket(activeRef)
        end
        if activeRef.data.tentCover then
            coverController.removeCover(activeRef)
        end
        if activeRef.data.lantern then
            lanternController.removeLantern(activeRef)
        end
        common.helper.yeet(activeRef)
        tes3.playSound{ sound = "Item Misc Up", reference = tes3.player }
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
                coverController.selectCover(activeRef)
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
                tes3.playSound{ sound = "Item Misc Up", reference = tes3.player }
            end
        },
        {
            text = "Attach Lantern",
            showRequirements = function()
                return lanternController.canHaveLantern(activeRef)
                    and not lanternController.tentHasLantern(activeRef)
                    and not trinketController.tentHasTrinket(activeRef)
            end,
            callback = function()
                lanternController.selectLantern(activeRef)
            end
        },
        {
            text = "Remove Lantern",
            showRequirements = function()
                return lanternController.canHaveLantern(activeRef)
                    and lanternController.tentHasLantern(activeRef)
            end,
            callback = function()
                lanternController.removeLantern(activeRef)
                tes3.playSound{ sound = "Item Misc Up", reference = tes3.player }
            end
        },
        {
            text = "Attach Trinket",
            showRequirements = function()
                return trinketController.canHaveTrinket(activeRef)
                    and not lanternController.tentHasLantern(activeRef)
                    and not trinketController.tentHasTrinket(activeRef)
            end,
            callback = function()
                trinketController.selectTrinket(activeRef)
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
                tes3.playSound{ sound = "Item Misc Up", reference = tes3.player }
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
    if not (e.activator == tes3.player) then return end
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
        --Pick up if stack
        if common.helper.isStack(e.target) then
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

local function setTentTempMulti()
    local tempMulti
    if (not common.data.insideTent)  or ( not currentTent ) then
        --not in a tent, no multiplier
        tempMulti = 1.0
    elseif not coverController.canHaveCover(currentTent) then
        --in a legacy tent, set to full multi
        tempMulti = tentConfig.tempMultis.legacy
    elseif coverController.tentHasCover(currentTent) then
        --in modular tent with cover, get cover value
        local coverId = currentTent.data.tentCover:lower()
        tempMulti = tentConfig.tempMultis[coverId]
            or tentConfig.tempMultis.coverDefault
    else
        --in modular tent, no cover, get tent value
        local tentId = currentTent.object.id:lower()
        tempMulti = tentConfig.tempMultis[tentId]
            or tentConfig.tempMultis.uncovered
    end
    common.data.tentTempMulti = tempMulti
end

local function setTentCoverage()

end

local function setTentSwitchNodes()
    if currentTent then
        local onIndex = config.seeThroughTents and 1 or 0
        --switch base tent
        local tentNode = currentTent.sceneNode:getObjectByName("TENT")
        if tentNode then
            local canvasNode = tentNode:getObjectByName("SWITCH_CANVAS")
            if canvasNode then
                canvasNode.switchIndex = common.data.insideTent and onIndex or 0
            end
        end
        --switch cover
        local tentCover = currentTent.sceneNode:getObjectByName("ATTACH_COVER")
        if tentCover then
            local canvasNode = tentCover:getObjectByName("SWITCH_CANVAS")
            if canvasNode then
                canvasNode.switchIndex = common.data.insideTent and onIndex or 0
            end
        end
    end
end


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

local function setTent(e)
    local insideTent = e.insideTent
    if e.tent then currentTent = e.tent end
    if (not currentTent) or (not currentTent:valid()) or (not currentTent.sceneNode) then currentTent = nil end
    common.data.insideTent = insideTent
    common.data.hasTentCover = coverController.tentHasCover(currentTent)
    setTentTempMulti()
    setTentCoverage()
    setTentSwitchNodes()
end

event.register(tes3.event.loaded, function()
    timer.start{
        duration = 0.5,
        type = timer.simulate,
        iterations = -1,
        callback = function()
            local _, safeTent = common.helper.checkRefSheltered()
            setTent{
                insideTent = safeTent ~= nil,
                tent = safeTent
            }
        end
    }
end)


local function cullRain(position)
    local rain = tes3.worldController.weatherController.sceneRainRoot
    for raindrop in table.traverse{rain} do
        if not raindrop.appCulled then
            if position:distance(raindrop.worldTransform.translation) < 400 then
                raindrop.appCulled = true
            end
        end
    end
end

--Must be done each frame to remove the particles as they get added
local function tentSimulate(e)
    if config.disableRainInTents then
        if currentTent and currentTent:valid() then
            local position = currentTent.position:copy()
            cullRain(position)
        end
    end
end
event.register("simulate", tentSimulate)

event.register("objectInvalidated", function(e)
    if currentTent and e.object == currentTent:getObject() then
        currentTent = nil
    end
end)