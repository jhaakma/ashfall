local common = require("mer.ashfall.common.common")
local logger = common.createLogger("BrickMould")
local RawClay = require("mer.ashfall.clay.RawClay")
local BrickShed = require("mer.ashfall.items.brickShed")
local CraftingFramework = require("CraftingFramework")
local Async = require("CraftingFramework.util.Async")

---@class Ashfall.Clay.BrickMould
local BrickMould = {
    CRAFT_SECONDS_PLACEMENT = 0.15,
    CRAFT_SECONDS_MOVE = 0.25,
}


--Check if an object is a brick mould
---@param item tes3item|nil
function BrickMould.isMould(item)
    if not item then return false end
    local id = item.id:lower()
    if id == "ashfall_brick_mold_fired" then
        return true
    end
    return false
end

function BrickMould.craftBrick(mouldRef)
    --remove clay from player inventory
    common.helper.removeItem{
        reference = tes3.player,
        item = RawClay.rawClayId,
        count = 1,
        playSound = false,
    }
    --create unfired brick reference at ATTACH_CLAY position
    local attachClayNode = mouldRef.sceneNode:getObjectByName("ATTACH_CLAY")
    tes3.createReference{
        object = "ashfall_brick_raw_01",
        position = attachClayNode.worldTransform.translation,
        orientation = mouldRef.orientation,
        cell = mouldRef.cell,
    }

    tes3.playSound{
        reference = tes3.player,
        sound = "corpDRAG"
    }
end

---Check if there's aready a clay brick at the ATTACH_CLAY position of the mould
---@param mouldRef tes3reference The reference of the brick mould to check
---@return tes3reference|nil The reference of the brick if found, nil if not
function BrickMould.findBrickAtAttachPosition(mouldRef)
    local attachClayNode = mouldRef.sceneNode:getObjectByName("ATTACH_CLAY")
    if not attachClayNode then
        logger:error("No ATTACH_CLAY node found on mould reference: %s", mouldRef)
        return nil
    end

    local attachPosition = attachClayNode.worldTransform.translation
    for ref in mouldRef.cell:iterateReferences(tes3.objectType.miscItem, false) do
        if ref.object and ref.object.id:lower() == "ashfall_brick_raw_01" then
            local distance = attachPosition:distance(ref.position)
            if distance < 1 then -- If the brick is within 1 units of the attach position, consider it the same brick
                return ref
            end
        end
    end
end

---Display a simple "Press Activate to cancel" menu
function BrickMould.showBrickCraftingUI()

    local MenuMulti = tes3ui.findMenu("MenuMulti")
    if not MenuMulti then
        logger:error("MenuMulti not found when trying to show brick crafting UI")
        return
    end

    local menu = MenuMulti:createThinBorder{
        id = "Ashfall_BrickCraftingMenu",
    }
    menu.autoHeight = true
    menu.autoWidth = true
    menu.absolutePosAlignX = 0.5
    menu.absolutePosAlignY = 0.03
    menu:createLabel{
        text = "Crafting Bricks... Press any key to cancel.",
    }
end

function BrickMould.hideBrickCraftingUI()
    logger:debug("Hiding brick crafting UI")
    local MenuMulti = tes3ui.findMenu("MenuMulti")
    if not MenuMulti then
        logger:error("MenuMulti not found when trying to hide brick crafting UI")
        return
    end
    local menu = MenuMulti:findChild("Ashfall_BrickCraftingMenu")
    if menu then
        menu:destroy()
    end
end



function BrickMould.startCrafting(mouldRef)
    local brickShed = BrickShed.getNearby(1000)
    if not brickShed then
        logger:error("No nearby brick shed found when starting brick mould crafting")
        tes3.messageBox("You need to be near a Brick Shed to craft bricks.")
        return
    end

    common.helper.disableControls()
    tes3.mobilePlayer.mouseLookDisabled = false
    BrickMould.showBrickCraftingUI()


    local function finishCrafting()
        logger:debug("Brick crafting cancelled")
        BrickMould.hideBrickCraftingUI()
        common.helper.enableControls()
    end


    local safeRef = tes3.makeSafeObjectHandle(mouldRef)

    local function craft()
        local async = Async:new()
        async.finish = function()
            finishCrafting()
            async.isCancelled = true
        end

        local function f()
            if not async.isCancelled then
                tes3.messageBox("Finished Crafting.")
                async:cancel()
            end
            event.unregister("keyDown", f)
        end
        event.register("keyDown", f)
        async:step("placeBrick", function(next, cancel)
            logger:debug("Placing unfired brick at attach position: %s", os.clock())
            if not safeRef:valid() then
                logger:error("Mould reference is no longer valid during crafting.")
                cancel()
                return
            end
            BrickMould.craftBrick(mouldRef)
        end)
        async:wait{ type = timer.real, duration = BrickMould.CRAFT_SECONDS_PLACEMENT }
        async:step("moveToShed", function(next, cancel)
            logger:debug("Moving crafted brick to shed")
            if not safeRef:valid() then
                logger:error("Mould reference is no longer valid during crafting.")
                cancel()
                return
            end
            local brickRef = BrickMould.findBrickAtAttachPosition(mouldRef)
            if not brickRef then
                logger:error("Crafted brick reference not found at attach position.")
                cancel()
                return
            end
            brickRef:disable()
            brickRef:delete()
            logger:debug("brick ref deleted at %s", os.clock())

            brickShed:addBricks(1)
            tes3.playSound{
                reference = tes3.player,
                soundPath = "ashfall/brick_lo.wav"
            }
        end)
        async:step("checkIngredients", function(next, cancel)
            logger:debug("Checking for raw clay in inventory")
            local clayCount = RawClay.getPlayerClayInInventory()
            if clayCount <= 0 then
                tes3.messageBox("You have no raw clay to craft bricks.")
                cancel()
                return
            end
        end)
        async:wait{ type = timer.real, duration = BrickMould.CRAFT_SECONDS_MOVE }
        async:step("repeat", function(next)
            craft()
        end)
        async:start()
    end

    craft()
end


---@param e activateEventData
function BrickMould.onActivate(e)
        if tes3ui.menuMode() then return end
    if common.helper.isModifierKeyPressed() then return end
    if not BrickMould.isMould(e.target.object) then return end

    local existingBrick = BrickMould.findBrickAtAttachPosition(e.target)
    if existingBrick then
        common.helper.pickUp(existingBrick, true)
        return false
    end

    tes3ui.showMessageMenu{
        message = "Brick Mould",
        buttons = {
            {
                text = "Make Bricks (Auto)",
                enableRequirements = function()
                    return BrickShed.getNearby(1000) ~= nil
                        and RawClay.getPlayerClayInInventory() > 0
                end,
                toooltip = function()
                    return {
                        header = "Brick Crafting",
                        text = "Begin crafting bricks and placing them in a brick shed.",
                    }
                end,
                tooltipDisabled = function()
                    return {
                        header = "Requirements:",
                        text = "- Raw Clay"
                                + "\n- Must be near a Brick Shed.",
                    }
                end,
                callback = function()
                    BrickMould.startCrafting(e.target)
                end
            },
            {
                text = "Make Brick",
                enableRequirements = function()
                    return RawClay.getPlayerClayInInventory() > 0
                end,
                tooltip = function()
                    return {
                        header = "Requirements:",
                        text = "- 1x Raw Clay",
                    }
                end,
                tooltipDisabled = function()
                    return {
                        header = "Requirements:",
                        text = "- 1x Raw Clay",
                    }
                end,
                callback = function()
                    BrickMould.craftBrick(e.target)
                end,
            },
            {
                text = "Pick Up",
                callback = function()
                    timer.delayOneFrame(function()
                        common.helper.pickUp(e.target)
                    end)
                end,
            }
        },
        cancels = true,
    }

    return false
end

return BrickMould