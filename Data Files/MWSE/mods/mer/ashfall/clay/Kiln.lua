local common = require("mer.ashfall.common.common")
local logger = common.createLogger("Kiln")
local CraftingFramework = require("CraftingFramework")
local ReferenceManager = CraftingFramework.ReferenceManager
local ItemInstance = require("CraftingFramework.carryableContainers.components.ItemInstance")
local TimeGapSimulator = require("CraftingFramework.components.TimeGapSimulator")
local HeatUtil = require("mer.ashfall.heat.HeatUtil")
local HeatCurve = require("mer.ashfall.heat.HeatCurve")
local Campfire = require("mer.ashfall.camping.campfire.Campfire")
local Brick = require("mer.ashfall.clay.Brick")

---@class Ashfall.Clay.Kiln.data
---@field firingProgress number Progress towards firing, from 0 to 1
---@field hourLastUpdated number Game hour when firing progress was last updated

---@class Ashfall.Clay.Kiln : ItemInstance
local Kiln = {
    registeredKilns = {},
    raw_texture = niSourceTexture.createFromPath("textures\\ashfall\\clay\\raw_clay.dds"),
    fired_texture = niSourceTexture.createFromPath("textures\\ashfall\\clay\\fired_clay.dds"),
    PROGRESS_PER_HOUR = 0.25
}


function Kiln:checkAtFiringTemperature()
    local heat = HeatUtil.getHeat(self.reference)
    local firingHeat = Campfire.STAGES.firing.minTemp
    return heat >= firingHeat
end

---@param reference tes3reference
function Kiln:new(reference)
    local instance = ItemInstance:new{
        reference = reference,
        dataKey = "Ashfall_Kiln"
    }
    setmetatable(instance, self)
    self.__index = self
    return instance --[[@as Ashfall.Clay.Kiln]]
end

function Kiln:isFired()
    if (self.data.firingProgress and self.data.firingProgress >= 1) then
        return true
    end
    --otherwise, check materialsUsed
    local materialsUsed = self.reference.data.materialsUsed or {}
    local firedBrickCount = materialsUsed[Brick.firedId] or 0
    if firedBrickCount > 0 then
        return true
    end

    return false
end

function Kiln:updateVisuals()
    logger:debug("Updating visuals for kiln reference: %s", self.reference)
    local sceneNode = self.reference.sceneNode
    if not sceneNode then
        logger:error("No scene node found for kiln reference: %s", self.reference)
        return
    end
    local texture = self:isFired() and Kiln.fired_texture or Kiln.raw_texture
    ---@param triShape niTriShape
    for triShape in sceneNode:traverse{ type = ni.type.triShape} do
        if triShape.texturingProperty and triShape.name == "KILN_CLAY" then
            triShape.texturingProperty = triShape.texturingProperty:clone()
            triShape.texturingProperty.baseMap.texture = texture
            triShape:updateProperties()
        end
    end
end

function Kiln:fireMaterials()
    local rawBrickid = Brick.rawId
    local firedBrickId = Brick.firedId

    logger:debug("Firing materials in kiln reference: %s", self.reference)
    local rawBrickCount = self.reference.data.materialsUsed[rawBrickid] or 0
    self.reference.data.materialsUsed[rawBrickid] = nil
    self.reference.data.materialsUsed[firedBrickId] = self.reference.data.materialsUsed[firedBrickId] or 0
    self.reference.data.materialsUsed[firedBrickId] = self.reference.data.materialsUsed[firedBrickId] + rawBrickCount
end

function Kiln:progressFiring()
    self.data.firingProgress = self.data.firingProgress or 0
    local now = tes3.getSimulationTimestamp()
    self.data.hourLastUpdated = self.data.hourLastUpdated or now
    local hoursPassed = now - self.data.hourLastUpdated
    if hoursPassed < 0 then
        logger:warn("Negative hours passed since last update for kiln reference: %s. This may indicate a problem with the game clock or simulation timestamp.", self.reference)
        hoursPassed = 0
    end
    if hoursPassed <= 0 then
        self.data.hourLastUpdated = now
        return
    end

    -- Refresh snapshot while actively burning so we can simulate long gaps later.
    if self.reference.data
        and self.reference.data.isLit
        and (self.reference.data.fuelLevel or 0) > 0 then
        self.data.lastHeatSourceSnapshot = HeatCurve.snapshotFuelConsumer(self.reference)
    end

    local snap = self.data.lastHeatSourceSnapshot
    if not snap then
        self.data.hourLastUpdated = now
        return
    end

    local snapOffset = self.data.hourLastUpdated - (snap.timestamp or self.data.hourLastUpdated)
    if snapOffset > 0 then
        snap = HeatCurve.advanceSnapshot(snap, snapOffset)
    end

    local firingHeat = Campfire.STAGES.firing.minTemp
    local targetHeatAt = HeatCurve.makeTargetHeatFn(snap)

    TimeGapSimulator.advance(hoursPassed, {
        stepHours = 0.25,
        startTimestamp = self.data.hourLastUpdated,
        targetValueAt = function(tHours)
            return targetHeatAt(tHours)
        end,
        getCurrentValue = function()
            return self.data.firingProgress or 0
        end,
        stepTowardTarget = function(currentProgress, targetHeat, dtHours, timestamp)
            if targetHeat >= firingHeat then
                local progressIncrease = dtHours * Kiln.PROGRESS_PER_HOUR
                self.data.firingProgress = math.clamp(currentProgress + progressIncrease, 0, 1)
            else
                self.data.firingProgress = currentProgress
            end
            self.data.hourLastUpdated = timestamp
        end,
        onStep = function()
            if self.data.firingProgress and self.data.firingProgress >= 1 then
                return false
            end
        end,
    })

    self.data.lastHeatSourceSnapshot = HeatCurve.advanceSnapshot(snap, hoursPassed)
    self.data.hourLastUpdated = now
end

function Kiln.register(id)
    logger:debug("Registering kiln with id: %s", id)
    Kiln.registeredKilns[id:lower()] = true
end

function Kiln.isKiln(id)
    return Kiln.registeredKilns[id:lower()] ~= nil
end

function Kiln.initialise()
    local refManager = ReferenceManager:new{
        requirements = function(_, reference)
            return Kiln.registeredKilns[reference.baseObject.id:lower()] ~= nil
        end,
        onActivated = function(_, reference)
            local kiln = Kiln:new(reference)
            if kiln then
                kiln:updateVisuals()
            end
        end
    }
    event.register("simulate", function(e)
        refManager:iterateReferences(function(reference)
            local kiln = Kiln:new(reference)
            if kiln then
                local isFired = kiln:isFired()
                if isFired then return end
                kiln:progressFiring()
                if kiln:isFired() then
                    logger:trace("Kiln %s has reached firing temperature, updating visuals", reference)
                    kiln:fireMaterials()
                    kiln:updateVisuals()
                end
            else
                logger:error("Failed to create kiln instance for reference: %s", reference)
            end
        end)
    end)
end

return Kiln