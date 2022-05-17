
local thirstController = require "mer.ashfall.needs.thirstController"
--[[
    --Handles the heating and cooling of objects that can boil water
]]
local LiquidContainer = require("mer.ashfall.liquid.LiquidContainer")
local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("boilerController")
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")
local patinaController = require("mer.ashfall.camping.patinaController")
local BOILER_UPDATE_INTERVAL = 0.001


local function addUtensilPatina(campfire,interval)
    if campfire.sceneNode and campfire.data.utensilId then
        logger:trace("Attempting to add Patina to %s", campfire.data.utensilId)
        local utensilId = campfire.sceneNode:getObjectByName("ATTACH_HANGER")
            or campfire.sceneNode:getObjectByName("HANG_UTENSIL")
        local patinaAmount = campfire.data.utensilPatinaAmount or 0
        local newAmount = math.clamp(patinaAmount + interval * 1, 0, 100)
        local didAddPatina = patinaController.addPatina(utensilId, newAmount)
        if didAddPatina then
            campfire.data.utensilPatinaAmount = newAmount
            logger:trace("addUtensilPatina: Added patina to %s node, new amount: %s",utensilId, campfire.data.utensilPatinaAmount)
        else
            logger:trace("addUtensilPatina: Mesh incompatible with patina mechanic, did not apply")
        end
    end
end

local function updateBoilers(e)

    local function doUpdate(boilerRef)
        ---@type AshfallLiquidContainer
        local liquidContainer = LiquidContainer.createFromReference(boilerRef)
        --logger:trace("BOILER updating %s", boilerRef.object.id)
        liquidContainer.data.lastWaterUpdated = liquidContainer.data.lastWaterUpdated or e.timestamp
        local timeSinceLastUpdate = e.timestamp - liquidContainer.data.lastWaterUpdated

        --logger:trace("BOILER timeSinceLastUpdate %s", timeSinceLastUpdate)

        if timeSinceLastUpdate < 0 then
            logger:error("BOILER liquidContainer.data.lastWaterUpdated(%.4f) is ahead of e.timestamp(%.4f).",
                liquidContainer.data.lastWaterUpdated, e.timestamp)
            --something fucky happened
            liquidContainer.data.lastWaterUpdated = e.timestamp
        end

        if timeSinceLastUpdate > BOILER_UPDATE_INTERVAL then
            local hasFilledPot = liquidContainer.waterAmount > 0
            if hasFilledPot then
                logger:trace("BOILER interval passed, updating heat for %s", liquidContainer)
                addUtensilPatina(liquidContainer.reference,timeSinceLastUpdate)
                logger:trace("BOILER hasFilledPot")
                local bottleData = thirstController.getBottleData(liquidContainer.itemId)
                local utensilData = CampfireUtil.getUtensilData(liquidContainer.reference)
                local capacity = (bottleData and bottleData.capacity) or ( utensilData and utensilData.capacity )

                CampfireUtil.updateWaterHeat(liquidContainer.data, capacity, liquidContainer.reference)
                if liquidContainer:isBoiling() then
                    --boil dirty water away
                    if liquidContainer:getLiquidType() == "dirty" then
                        liquidContainer.waterType = nil
                    end
                end
                tes3ui.refreshTooltip()
            else
                logger:trace("BOILER no filled pot, setting waterUpdated to nil")
                liquidContainer.data.lastWaterUpdated = nil
            end
        end
    end
    common.helper.iterateRefType("boiler", doUpdate)

end
event.register("simulate", updateBoilers)