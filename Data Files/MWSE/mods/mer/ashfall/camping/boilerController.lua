
local thirstController = require "mer.ashfall.needs.thirstController"
--[[
    --Handles the heating and cooling of objects that can boil water
]]
local common = require ("mer.ashfall.common.common")
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")
local patinaController = require("mer.ashfall.camping.patinaController")
local BOILER_UPDATE_INTERVAL = 0.001


local function addUtensilPatina(campfire,interval)
    if campfire.sceneNode and campfire.data.utensilId then
        common.log:trace("Attempting to add Patina to %s", campfire.data.utensilId)
        local utensilId = campfire.sceneNode:getObjectByName("ATTACH_HANGER")
            or campfire.sceneNode:getObjectByName("HANG_UTENSIL")
        local patinaAmount = campfire.data.utensilPatinaAmount or 0
        local newAmount = math.clamp(patinaAmount+ interval * 100, 0, 100)
        local didAddPatina = patinaController.addPatina(utensilId, newAmount)
        if didAddPatina then
            campfire.data.utensilPatinaAmount = newAmount
            common.log:trace("addUtensilPatina: Added patina to %s node, new amount: %s",utensilId, campfire.data.utensilPatinaAmount)
        else
            common.log:trace("addUtensilPatina: Mesh incompatible with patina mechanic, did not apply")
        end
    end
end

local function updateBoilers(e)

    local function doUpdate(boilerRef)
        --common.log:trace("BOILER updating %s", boilerRef.object.id)
        boilerRef.data.lastWaterUpdated = boilerRef.data.lastWaterUpdated or e.timestamp
        local timeSinceLastUpdate = e.timestamp - boilerRef.data.lastWaterUpdated

        --common.log:trace("BOILER timeSinceLastUpdate %s", timeSinceLastUpdate)

        if timeSinceLastUpdate < 0 then
            common.log:error("BOILER boilerRef.data.lastWaterUpdated(%.4f) is ahead of e.timestamp(%.4f).",
                boilerRef.data.lastWaterUpdated, e.timestamp)
            --something fucky happened
            boilerRef.data.lastWaterUpdated = e.timestamp
        end

        if timeSinceLastUpdate > BOILER_UPDATE_INTERVAL then
            boilerRef.data.lastWaterUpdated = e.timestamp
            local hasFilledPot = (
                boilerRef.data.waterAmount and
                boilerRef.data.waterAmount > 0
            )
            if hasFilledPot then
                common.log:trace("BOILER interval passed, updating heat for %s", boilerRef)
                addUtensilPatina(boilerRef,timeSinceLastUpdate)
                common.log:trace("BOILER hasFilledPot")
                local bottleData = thirstController.getBottleData(boilerRef.object.id)
                local utensilData = CampfireUtil.getUtensilData(boilerRef)
                local capacity = (bottleData and bottleData.capacity) or ( utensilData and utensilData.capacity )

                CampfireUtil.updateWaterHeat(boilerRef.data, capacity, boilerRef)
                if boilerRef.data.waterHeat > common.staticConfigs.hotWaterHeatValue then
                    --boil dirty water away
                    if boilerRef.data.waterType == "dirty" then
                        boilerRef.data.waterType = nil
                    end
                end
                tes3ui.refreshTooltip()
            else
                common.log:trace("BOILER no filled pot, setting waterUpdated to nil")
                boilerRef.data.lastWaterUpdated = nil
            end
        end
    end
    common.helper.iterateRefType("boiler", doUpdate)

end
event.register("simulate", updateBoilers)

-- --Utensils make boiling sound when placed
-- event.register("referenceSceneNodeCreated", function(e)
--     if e.reference.data
--         and e.reference.data.waterHeat
--         and e.reference.data.waterHeat > common.staticConfigs.hotWaterHeatValue
--     then
--         tes3.playSound{
--             reference = e.reference,
--             sound = "ashfall_boil",
--             loop = true
--         }
--     end
-- end)