local common = require("mer.ashfall.common.common")
local logger = common.createLogger("Bellows")

local ReferenceManager = require("CraftingFramework").ReferenceManager

---Class for managing bellows attached to campfire
---@class Ashfall.Camping.Bellows
local Bellows = {}

Bellows.BELLOWS_EFFECT_DURATION_HOURS = 5.0
Bellows.MAX_FIRE_SCALE = 1.4
Bellows.ANIMATION_DURATION = 3.333
Bellows.MAX_HEAT_EFFECT = 1.75
Bellows.MAX_FUEL_DRAIN = 1.25


local bellowsRefManager = ReferenceManager:new{
    requirements = function(self, ref)
        return ref.supportsLuaData and Bellows.hasBellows(ref)
    end,
}

event.register("simulate", function(e)
    bellowsRefManager:iterateReferences(function(reference)
        local now = os.clock()
        local animStartTime = reference.data.bellowsAnimStartTime
        if animStartTime then
            local timeElapsed = now - animStartTime
            if timeElapsed < Bellows.ANIMATION_DURATION then
                local attachNode = Bellows.getAttachNode(reference)
                if attachNode then
                    ---@param node niNode
                    for node in table.traverse{ attachNode } do
                        if node.controller and node.controller:isInstanceOfType(ni.type.NiGeomMorpherController) then
                            node.controller.lastScaledTime = timeElapsed
                        end
                    end
                    return
                end
            end
        end
        bellowsRefManager:removeReference(reference)
    end)
end)

---Get the fuel drain effect multiplier from bellows
---scaled according to time remaining on bellows effect
---@param reference tes3reference The fuel consumer reference with bellows attached
---@return number Fuel drain effect multiplier
function Bellows.getScaledFuelDrainEffect(reference)
    local isActive = Bellows.isBellowsActive(reference)
    if not isActive then
        return 1.0
    end
    --fuel drain between 1 and MAX_FUEL_DRAIN
    local timeFactor = Bellows.getTimeFactor(reference)
    local fuelDrainEffect = math.remap(timeFactor, 0.0, 1.0, 1.0, Bellows.MAX_FUEL_DRAIN)
    return fuelDrainEffect
end

---Gets the heat effect multiplier from bellows,
---scaled according to time remaining on bellows effect
---@param reference tes3reference The fuel consumer reference with bellows attached
---@return nil|number Heat effect multiplier or nil if bellows not active
function Bellows.getScaledHeatEffect(reference)
    local isActive = Bellows.isBellowsActive(reference)
    if not isActive then
        return nil
    end
    --heat between 1 and MAX_HEAT_EFFECT
    local timeFactor = Bellows.getTimeFactor(reference)
    local heatEffect = math.remap(timeFactor, 0.0, 1.0, 1.0, Bellows.MAX_HEAT_EFFECT)
    return heatEffect
end

---Get normalised time remaining on belows effect
---@param reference tes3reference The fuel consumer reference with bellows attached
---@return number Normalised time factor between 0 and 1
function Bellows.getTimeFactor(reference)
    local isActive = Bellows.isBellowsActive(reference)
    if not isActive then
        return 0.0
    end
    local lastBellowsUseTime = reference.data.lastBellowsUseTime
    if lastBellowsUseTime then
        local now = tes3.getSimulationTimestamp()
        local timeElapsed = now - lastBellowsUseTime
        if timeElapsed < Bellows.BELLOWS_EFFECT_DURATION_HOURS then
            return 1.0 - (timeElapsed / Bellows.BELLOWS_EFFECT_DURATION_HOURS)
        end
    end
    return 0.0
end

---Check if bellows is currently active on fuel consumer
---@param reference tes3reference The fuel consumer reference with bellows attached
---@return boolean True if bellows is active
function Bellows.isBellowsActive(reference)
    local bellowsId = reference.data.bellowsId
    local lastBellowsUseTime = reference.data.lastBellowsUseTime
    local bellowsData = common.staticConfigs.bellows[bellowsId]
    if bellowsData and lastBellowsUseTime then
        local now = tes3.getSimulationTimestamp()
        if now - lastBellowsUseTime < Bellows.BELLOWS_EFFECT_DURATION_HOURS then
            return true
        end
    end
    return false
end

---Get bellows data for fuel consumer
---@param reference tes3reference The fuel consumer reference with bellows attached
---@return Ashfall.Bellows.Data|nil Bellows data or nil if no bellows attached
function Bellows.getBellowsData(reference)
    local bellowsId = reference.data.bellowsId
    if bellowsId then
        return common.staticConfigs.bellows[bellowsId]
    end
    return nil
end


---Scale fire according to animation time, starting at 1, quickly
---ramping up to max scale, then slowly back down to 1
---@param reference tes3reference The fuel consumer reference with bellows attached
---@return number Scale multiplier for fire
function Bellows.getFireScaleEffect(reference)
    local animationTime = Bellows.getAnimationTime(reference)
    if animationTime <= 0 or animationTime >= 1 then
        return 1.0
    end

    --Use a curve to scale fire size
    local scaleEffect = 1.0
    if animationTime < 0.3 then
        scaleEffect = math.remap(animationTime, 0.0, 0.3, 1.0, Bellows.MAX_FIRE_SCALE)
    else
        scaleEffect = math.remap(animationTime, 0.3, 1.0, Bellows.MAX_FIRE_SCALE, 1.0)
    end
    return scaleEffect
end

function Bellows.reset(reference)
    reference.data.lastBellowsUseTime = nil
end

---Use the bellows on the fuel consumer
---@param reference tes3reference The fuel consumer reference with bellows attached
function Bellows.use(reference)
    logger:debug("Using bellows on reference: %s", reference.id)
    if Bellows.isAnimating(reference) then
        logger:debug("Bellows is already animating, aborting use")
        return
    end

    local attachNode = Bellows.getAttachNode(reference)
    if not attachNode then
        logger:error("No attach node found on bellows reference: %s", reference.id)
        return
    end

    ---@param node niNode
    for node in table.traverse{ attachNode } do
        if node.controller and node.controller:isInstanceOfType(ni.type.NiGeomMorpherController) then
            logger:debug("Starting bellows morph controller on node: %s", node.name)
            node.controller.frequency = 1
            node.controller.lastScaledTime = 0
        end
    end

    local fuelLevel = reference.data.fuelLevel or 0
    if fuelLevel > 0 then
        tes3.playSound{
            reference = tes3.player,
            soundPath = "ashfall/bellows.wav"
        }
    end
    reference.data.lastBellowsUseTime = tes3.getSimulationTimestamp()
    reference.data.bellowsAnimStartTime = os.clock()
    bellowsRefManager:addReference(reference)
end

---Get the attach node for bellows on fuel consumer
---@param reference tes3reference The fuel consumer reference with bellows attached
---@return niNode|nil The attach node or nil if not found
function Bellows.getAttachNode(reference)
    return reference.sceneNode:getObjectByName("ATTACH_BELLOWS")
end

---Check if lastScaledTime is between 0 and 1
---@param reference tes3reference The fuel consumer reference with bellows attached
---@return boolean True if bellows is animating
function Bellows.isAnimating(reference)
    local animationTime = Bellows.getAnimationTime(reference)
    if animationTime > 0 and animationTime < 1 then
        return true
    end
    return false
end

---get animation time, scaled to between 0 and 1
---@param reference tes3reference The fuel consumer reference with bellows attached
---@return number Normalised animation time between 0 and 1
function Bellows.getAnimationTime(reference)
    local attachNode = Bellows.getAttachNode(reference)
    if not attachNode then
        return 0
    end
    ---@param node niNode
    for node in table.traverse{ attachNode } do
        if node.controller and node.controller:isInstanceOfType(ni.type.NiGeomMorpherController) then
            local lastScaledTime = node.controller.lastScaledTime or 0
            return math.remap(lastScaledTime, 0, Bellows.ANIMATION_DURATION, 0, 1.1)

        end
    end
    return 0
end

---Check if id is bellows
---@param id string The item id to check
---@return boolean True if id is bellows
function Bellows.isBellows(id)
    return common.staticConfigs.bellows[id:lower()] ~= nil
end

function Bellows.hasBellows(reference)
    local bellowsId = reference.data.bellowsId
    return bellowsId ~= nil
end

---When attached, set lastScaledTime to ANIMATION_DURATION to prevent immediate animation
---And then set flag to active
---@param reference tes3reference The fuel consumer reference with bellows attached
---@param attachNode niNode The attach node for the bellows
function Bellows.attach(reference, attachNode)
    if not attachNode then
        return
    end
    ---@param node niNode
    for node in table.traverse{ attachNode } do
        if node.controller and node.controller:isInstanceOfType(ni.type.NiGeomMorpherController) then
            ---@type niTimeController
            local controller = node.controller
            controller.frequency = 0
            controller.lastScaledTime = Bellows.ANIMATION_DURATION + 10
        end
    end

end

function Bellows.remove(reference)
    reference.data.bellowsId = nil
    reference.data.lastBellowsUseTime = nil
end

return Bellows