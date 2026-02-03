local common = require("mer.ashfall.common.common")
local ReferenceManager = require("CraftingFramework").ReferenceManager
local UnfiredPottery = require("mer.ashfall.clay.UnfiredPottery")
local FiredPottery = require("mer.ashfall.clay.FiredPottery")
---This class manages firing clay by placing it over a fire
---@class Ashfall.FiringController
local FiringController = {}

local potteryRefManager = ReferenceManager:new{
    onActivated = function(_, reference)
        local unfiredPot = UnfiredPottery:new{ reference = reference }
        if unfiredPot then
            local heated = unfiredPot:getHeatedItem()
            if heated then
                heated:attachGlow()
            end
            unfiredPot:resetLastTemperatureUpdate()
            unfiredPot:resetLastFiredTimestamp()
            unfiredPot:setDecals()
        end
    end,
    requirements = function(self, ref)
        return UnfiredPottery.isUnfiredItem(ref.baseObject)
    end,
}

local firedPotteryRefManager = ReferenceManager:new{
    onActivated = function(_, reference)
        local firedPot = FiredPottery:new{ reference = reference }
        if firedPot then
            local heated = firedPot:getHeatedItem()
            if heated then
                heated:attachGlow()
            end
            firedPot:updateGlow()
            firedPot:setDecals()
        end
    end,
    requirements = function(self, ref)
        return FiredPottery.isFiredItem(ref.baseObject)
    end,
}

---Process a pottery item placed over a fire
---@param potteryRef tes3reference The reference of the pottery item
---@param heatSource tes3reference|nil The heat level from the fire source
function FiringController.processItem(potteryRef, heatSource)
    local potteryItem = UnfiredPottery:new{ reference = potteryRef}
    if not potteryItem then return end
    potteryItem:updateFiring(heatSource)
end

function FiringController.processActivePottery()
    potteryRefManager:iterateReferences(function(reference)
        local heatSource = common.helper.getHeatFromBelow(reference, "strong")
        FiringController.processItem(reference, heatSource)
    end)

    -- Fired pottery should retain heat and visuals after firing, but still cool down.
    firedPotteryRefManager:iterateReferences(function(reference)
        local firedPot = FiredPottery:new{ reference = reference }
        if not firedPot then
            return
        end
        local heatSource = common.helper.getHeatFromBelow(reference, "strong")
        firedPot:updateHeat(heatSource)
    end)
end

---Start a timer on game load to process active pottery items
function FiringController.onLoaded()
    timer.start{
        type = timer.simulate,
        duration = 0.1,
        callback = FiringController.processActivePottery,
        iterations = -1,
    }
end

return FiringController