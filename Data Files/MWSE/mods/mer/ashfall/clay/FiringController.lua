local common = require("mer.ashfall.common.common")
local ReferenceManager = require("CraftingFramework").ReferenceManager
local UnfiredPottery = require("mer.ashfall.clay.UnfiredPottery")
local FiredPottery = require("mer.ashfall.clay.FiredPottery")
local PotteryRecipe = require("mer.ashfall.clay.PotteryRecipe")
local HeatedItem = require("mer.ashfall.clay.HeatedItem")
local StaggeredRefProcessor = require("mer.ashfall.common.StaggeredRefProcessor")
---This class manages firing clay by placing it over a fire
---@class Ashfall.FiringController
local FiringController = {}

local unfiredPotRefManager = ReferenceManager:new{
    onActivated = function(_, reference)
        local unfiredPot = UnfiredPottery:new{ reference = reference }
        if unfiredPot then
            unfiredPot:resetLastTemperatureUpdate()
            unfiredPot:resetLastFiredTimestamp()
            unfiredPot:updateVisuals()

            -- Initialize dampness if not already set
            local dampComponent = unfiredPot:getDampComponent()
            if dampComponent and not dampComponent.data.dampness then
                dampComponent.data.dampness = 0.0
                dampComponent.data.lastUpdateTime = tes3.getSimulationTimestamp()
                dampComponent:updateVisuals()
            end
        end
    end,
    requirements = function(self, ref)
        return UnfiredPottery.isUnfiredItem(ref.baseObject)
    end,
}

local firedPotRefManager = ReferenceManager:new{
    onActivated = function(_, reference)
        local recipe = PotteryRecipe.getRecipeByFiredItemId(reference.baseObject.id)
        if recipe and recipe.isBasic then
            local heated = HeatedItem:new{ reference = reference, item = reference.baseObject, itemData = reference }
            if heated then
                heated:updateVisuals()
            end
            return
        end

        local firedPot = FiredPottery:new{ reference = reference }
        if firedPot then
            firedPot:updateGlow()
            firedPot:setDecals()
        end
    end,
    requirements = function(self, ref)
        return PotteryRecipe.isFiredPotteryItem(ref.baseObject)
    end,
}

---Process a pottery item placed over a fire
---@param e { reference: tes3reference, heatSource: tes3reference?, heatType: "strong"|"weak" }
function FiringController.processItem(e)
    local potteryItem = UnfiredPottery:new{ reference = e.reference}
    if not potteryItem then return end
    potteryItem:updateFiring{
        heatSource = e.heatSource,
        heatType = e.heatType,
    }
end

function FiringController.processActivePottery()
    unfiredPotRefManager:iterateReferences(function(reference)
        local heatSource, heatType = common.helper.getHeatFromBelow(reference)
        FiringController.processItem{
            reference = reference,
            heatSource = heatSource,
            heatType = heatType,
        }
    end)

    -- Fired pottery should retain heat and visuals after firing, but still cool down.
    firedPotRefManager:iterateReferences(function(reference)
        local recipe = PotteryRecipe.getRecipeByFiredItemId(reference.baseObject.id)
        local heatSource = common.helper.getHeatFromBelow(reference, "strong")
        if recipe and recipe.isBasic then
            FiredPottery.updateHeatSimple(reference, heatSource)
            return
        end

        local firedPot = FiredPottery:new{ reference = reference }
        if not firedPot then
            return
        end
        firedPot:updateHeat(heatSource)
    end)
end

local function processUnfired(reference)
    local heatSource, heatType = common.helper.getHeatFromBelow(reference)
    FiringController.processItem{
        reference = reference,
        heatSource = heatSource,
        heatType = heatType,
    }
end

local function processFired(reference)
    local recipe = PotteryRecipe.getRecipeByFiredItemId(reference.baseObject.id)
    local heatSource = common.helper.getHeatFromBelow(reference, "strong")
    if recipe and recipe.isBasic then
        FiredPottery.updateHeatSimple(reference, heatSource)
        return
    end

    local firedPot = FiredPottery:new{ reference = reference }
    if not firedPot then
        return
    end
    firedPot:updateHeat(heatSource)
end

---@param processor StaggeredRefProcessor
local function fillUnfiredProcessor(processor)
    unfiredPotRefManager:iterateReferences(function(reference)
        processor:add(reference)
    end)
end

---@param processor StaggeredRefProcessor
local function fillFiredProcessor(processor)
    firedPotRefManager:iterateReferences(function(reference)
        processor:add(reference)
    end)
end

local unfiredProcessor = StaggeredRefProcessor.new{
    callback = processUnfired,
    interval = 0.01,
    refsPerFrame = 1,
    removeAfterProcessing = false,
    onEmpty = fillUnfiredProcessor,
}

local firedProcessor = StaggeredRefProcessor.new{
    callback = processFired,
    interval = 0.01,
    refsPerFrame = 1,
    removeAfterProcessing = false,
    onEmpty = fillFiredProcessor,
}

---Start a timer on game load to process active pottery items
function FiringController.onLoaded()
    unfiredProcessor:stop()
    unfiredProcessor:clear()
    fillUnfiredProcessor(unfiredProcessor)
    unfiredProcessor:start()

    firedProcessor:stop()
    firedProcessor:clear()
    fillFiredProcessor(firedProcessor)
    firedProcessor:start()
end

return FiringController