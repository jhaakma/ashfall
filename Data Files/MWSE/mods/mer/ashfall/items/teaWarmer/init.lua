local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("teaWarmer")
local teaWarmerConfig = require("mer.ashfall.items.teaWarmer.config")
local midnightOilInterop = include("mer.midnightOil.interop")
local MAX_FUEL_LEVEL = 10
-- Add teawarmers to midnight oil blacklist
if midnightOilInterop then
    for id, _ in pairs(teaWarmerConfig.ids) do
        midnightOilInterop.addToBlacklist(id)
    end
end

local function objectIsTeaWarmer(item)
    return teaWarmerConfig.ids[item.id:lower()] ~= nil
end

--[[
    Block player from equipping tea warmer as a light
]]
---@param e equipEventData
local function preventEquippingTeaWarmer(e)
    if objectIsTeaWarmer(e.item) then
        logger:debug("Preventing tea warmer from being equipped")
        return false
    end
end
event.register("equip", preventEquippingTeaWarmer, { priority = 500 })

local function itemIsCandle(object)
    if object.objectType == tes3.objectType.light then
        return object.id:lower():find("candle") ~= nil
    end
    if midnightOilInterop then
        if object.id:lower() == "mer_lntrn_candle" then
        end
        local candleIds = midnightOilInterop.getCandleIds()
        return candleIds[object.id:lower()] ~= nil
    end
end

local function playerHasCandle()
    for _, stack in pairs(tes3.player.object.inventory) do
        if itemIsCandle(stack.object) then
            return true
        end
    end
    return false
end

local function hasRoomForCandle(teaWarmer)
    local fuelLevel = teaWarmer.data.fuelLevel or 0
    return fuelLevel < MAX_FUEL_LEVEL - 1
end

local function addFuel(teaWarmer)
    tes3.playSound{
        reference = tes3.player,
        sound = "Item Misc Up",
        loop = false
    }
    teaWarmer.data.fuelLevel = MAX_FUEL_LEVEL
    event.trigger("Ashfall:UpdateAttachNodes", { campfire = teaWarmer})
end

local function doLight(teaWarmer)
    teaWarmer.data.isLit = true
    tes3.playSound{ reference = tes3.player, sound = "ashfall_light_fire"  }
    event.trigger("Ashfall:registerReference", { reference = teaWarmer})
    event.trigger("Ashfall:Campfire_Enablelight", { campfire = teaWarmer})
    event.trigger("Ashfall:UpdateAttachNodes", {campfire = teaWarmer})
end

local function pickup(teaWarmer)
    timer.delayOneFrame(function()
        logger:debug("Picking up tea warmer")
        common.helper.pickUp(teaWarmer)
    end)
end

--[[
    If the equipped item is a teawarmer, show a messageBox menu to
    add fuel, light the teawarmer, or pick it up.
]]
---@param e activateEventData
local function showMenuOnEquipTeaWarmer(e)
    if tes3ui.menuMode() then return end
    if objectIsTeaWarmer(e.target) then
        local teaWarmer = e.target
        if common.helper.isModifierKeyPressed() then

        else
            local menu = {
                message = "Tea Warmer",
                buttons = {
                    {
                        text = "Add Candle",
                        requirements = function()
                            return playerHasCandle() and hasRoomForCandle(teaWarmer)
                        end,
                        tooltipDisabled = function()
                            return {
                                text = hasRoomForCandle(teaWarmer)
                                    and "You have no candles."
                                    or "Tea Warmer already has a candle."
                            }
                        end,
                        callback = function()
                            timer.delayOneFrame(function()
                                tes3ui.showInventorySelectMenu{
                                    title = "Select Candle",
                                    noResultsText = "No candles found.",
                                    filter = function(e)
                                        return itemIsCandle(e.item)
                                    end,
                                    callback = function(e)
                                        if e.item then
                                            addFuel(teaWarmer)
                                            tes3.removeItem{
                                                reference = tes3.player,
                                                item = e.item,
                                                itemData = e.itemData,
                                                count = 1
                                            }
                                        end
                                    end,
                                }
                            end)
                        end
                    },
                    {
                        text = "Light",
                        showRequirements = function()
                            return teaWarmer.data.fuelLevel
                                and teaWarmer.data.fuelLevel > 0
                                and teaWarmer.data.isLit ~= true
                        end,
                        callback = function()
                            logger:debug("Lit tea warmer")
                            doLight(teaWarmer)
                        end
                    },
                    {
                        text = "Extinguish",
                        showRequirements = function()
                            return teaWarmer.data.isLit
                        end,
                        callback = function()
                            logger:debug("Extinguish tea warmer")
                            event.trigger("Ashfall:fuelConsumer_Extinguish", { fuelConsumer = teaWarmer, playSound = false })
                        end
                    },
                    {
                        text = "Pick Up",
                        callback = function()
                            pickup(teaWarmer)
                        end
                    },
                },
                doesCancel = true
            }
            common.helper.messageBox(menu)
            return false
        end
    end
end
--Increase priority to override Midnight Oil
event.register("activate", showMenuOnEquipTeaWarmer, { priority = 10 })

local function disableLighting(e)
    if objectIsTeaWarmer(e.reference.object) then
        if not e.reference.data.isLit then
            e.reference:deleteDynamicLightAttachment()
        end
    end
end
event.register("referenceSceneNodeCreated", disableLighting)

