local common = require("mer.ashfall.common.common")
local ReferenceManager = require("CraftingFramework").ReferenceManager
local UnfiredPottery = require("mer.ashfall.clay.UnfiredPottery")
local FiredPottery = require("mer.ashfall.clay.FiredPottery")
local Glow = require("mer.ashfall.clay.Glow")
---This class manages firing clay by placing it over a fire
---@class Ashfall.FiringController
local FiringController = {}

local potteryRefManager = ReferenceManager:new{
    onActivated = function(_, reference)
        local unfiredPot = UnfiredPottery:new{ reference = reference }
        if unfiredPot then
            Glow.attachToNode(reference.sceneNode)
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