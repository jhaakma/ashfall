local ui = require("mer.ashfall.tempEffects.ratings.ratingUI")
local ratings = require("mer.ashfall.tempEffects.ratings.ratings")
local common = require("mer.ashfall.common.common")

--Register heat source
local temperatureController = require("mer.ashfall.temperatureController")
temperatureController.registerInternalHeatSource("warmthRating")
temperatureController.registerRateMultiplier("coverageMulti")

local function updateRatings()
    local warmth = ratings.getTotalWarmth()
    common.data.warmthRating = warmth

    local coverage = ratings.getTotalCoverage()
    common.data.coverageRating = coverage
    common.data.coverageMulti = math.remap(coverage, 0, 1, 1, 0.25 )
end

local function isArmorOrClothing(item)
    return (
        item.objectType == tes3.objectType.armor or
        item.objectType == tes3.objectType.clothing
    )
end

local function onUnequipped(e)
    if isArmorOrClothing(e.item) and e.reference == tes3.player then
        updateRatings()
        event.trigger("Ashfall:updateTemperature")
        ui.updateRatingsUI()
    end
end

local function onEquipped(e)
    if isArmorOrClothing(e.item) and e.reference == tes3.player then
        updateRatings()
        event.trigger("Ashfall:updateTemperature")
        ui.updateRatingsUI()
    end
end

event.register("Ashfall:dataLoaded", function()
    updateRatings()
    ui.updateRatingsUI()
end)

event.register("Ashfall:dataLoadedOnce", function()
    timer.start({
        duration = 1,
        iterations = 1,
        callback = function()
            event.register("unequipped", onUnequipped)
            event.register("equipped", onEquipped)
        end
    })
end)