local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config").config
local logger = common.createLogger("ClayTemper")
local RawClay = require("mer.ashfall.clay.RawClay")
local PotteryRecipe = require("mer.ashfall.clay.PotteryRecipe")
local CraftingFramework = require("CraftingFramework")
local CarryableContainer = CraftingFramework.CarryableContainer
local UnfiredPottery = require("mer.ashfall.clay.UnfiredPottery")
local Temper = require("mer.ashfall.clay.Temper")
local MortarAndPestle = require("mer.ashfall.clay.MortarAndPestle")
local ShapingMenu = require("mer.ashfall.clay.ShapingMenu")

---@class Ashfall.Clay.TemperData
---@field id string The object ID of the ingredient used as temper
---@field name string The name of the temper
---@field description string The description of the temper


---Class for managing the clayworking menu
---triggered by equipping raw clay
---@class Ashfall.Clay.ClayWorking
local ClayWorking    = {
    ---@type table<string, boolean>
    animationActivatorIds = {},
    TEMPER_HOURS_PASSED = 0.1,
    TEMPER_SECONDS_TAKEN = 3,

    SHAPING_HOURS_PASSED = 0.1,
    SHAPING_SECONDS_TAKEN = 3,
}



function ClayWorking.getCraftMenuAnimationActivatorIds()
    return ClayWorking.animationActivatorIds
end


function ClayWorking.registerActivatorId(id)
    ClayWorking.animationActivatorIds[id:lower()] = true
    logger:debug("Registered clay working activator id: %s", id)
end

---Add temper to clay
---@param reference tes3reference
function ClayWorking.addTemper(reference)
    CarryableContainer.removeItem{
        reference = tes3.player,
        item = Temper.temperId,
        count = 1,
        playSound = false,
    }
    tes3.playSound{
        reference = reference,
        sound = "corpDRAG"
    }

    timer.start{
        type = timer.real,
        duration = ClayWorking.TEMPER_SECONDS_TAKEN * 0.5,
        callback = function()
            local tempered = Temper:new{ reference = reference }
            if tempered then
                tempered:addTemper()
                tes3.playSound{
                    reference = reference,
                    sound = "corpDRAG"
                }
            end
        end
    }
    common.helper.fadeTimeOut(ClayWorking.TEMPER_HOURS_PASSED,
        ClayWorking.TEMPER_SECONDS_TAKEN, function() end)
end

--Open the clay working menu
function ClayWorking.openCraftMenu(reference)
    local isTempered = Temper.isTempered{ reference = reference }

    ShapingMenu:new{
        title = "Clay Working",
        clayId = RawClay.rawClayId,
        recipes = PotteryRecipe.getAllRecipesByMethod("hand"),
        clayAmount = 1,
        okayCallback = function(results)
            tes3.playSound{
                reference = reference,
                sound = "corpDRAG"
            }
            timer.start{
                type = timer.real,
                duration = ClayWorking.SHAPING_SECONDS_TAKEN * 0.5,
                callback = function()
                    local itemId = results.selectedShapeId
                    UnfiredPottery.createPotteryRef{
                        objectId = itemId,
                        cell = reference.cell,
                        position = reference.position,
                        tempered = isTempered,
                    }
                    reference:delete()
                end
            }
            common.helper.fadeTimeOut(ClayWorking.SHAPING_HOURS_PASSED,
                ClayWorking.SHAPING_SECONDS_TAKEN, function()
                end)
        end,
        hasTemper = isTempered,
    }:show()
end

function ClayWorking.isClay(reference)
    if not reference then return false end
    return reference.object.id:lower() == RawClay.rawClayId:lower()
end

---On activate: Show message box with:
--- - Temper clay
--- - Work Clay
--- - Pick Up
--- - Cancel
---@param e activateEventData
function ClayWorking.onActivate(e)
    if tes3ui.menuMode() then return end
    if common.helper.isModifierKeyPressed() then return end

    local clayRef = e.target
    if not ClayWorking.isClay(clayRef) then
        return
    end
    if not clayRef.supportsLuaData then
        return
    end

    tes3ui.showMessageMenu{
        message = "Clay Working",
        buttons = {
            {
                text = "Temper Clay",
                callback = function()
                    ClayWorking.addTemper(clayRef)
                end,
                showRequirements = function()
                    return not Temper.isTempered{ reference = clayRef }
                end,
                enableRequirements = function()
                    local hasTemper = Temper.getPlayerTemperCount() > 0
                    local hasMortarAndPestle = MortarAndPestle.playerHasMortarAndPestle()
                    return hasTemper
                        and hasMortarAndPestle
                end,
                tooltip = function()
                    return {
                        header = "Requirements:",
                        text = "- 1x Broken Pottery\n- Mortar and Pestle",
                    }
                end,
                tooltipDisabled = function()
                    return {
                        header = "Requirements:",
                        text = "- 1x Broken Pottery\n- Mortar and Pestle",
                    }
                end,
            },
            {
                text = "Work Clay",
                callback = function()
                    timer.delayOneFrame(function()
                        ClayWorking.openCraftMenu(clayRef)
                    end)
                end,
            },
            {
                text = "Pick Up",
                callback = function()
                    timer.delayOneFrame(function()
                        common.helper.pickUp(clayRef, true)
                    end)
                end
            }
        },
        cancels = true
    }
    return false
end


function ClayWorking.initialise()
    event.register("activate", ClayWorking.onActivate)
end

return ClayWorking