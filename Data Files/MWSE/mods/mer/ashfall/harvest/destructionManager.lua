---@class Ashfall.DestructionManager
---Handles harvestable destruction, animation, and lifecycle management
local DestructionManager = {}

local common = require("mer.ashfall.common.common")
local logger = common.createLogger("destructionManager")
local ReferenceController = require("mer.ashfall.referenceController")
local Activator = require("mer.ashfall.activators.Activator")

-- Constants for destruction mechanics
local CONSTANTS = {
    ANIMATION_ITERATIONS = 1000,           -- Number of animation frames
    RESPAWN_DISTANCE = 8192 / 2,           -- Distance at which harvestables respawn
    FELL_ROTATION_DEGREES = 30,            -- Degrees to rotate fell node
    FELL_ACCELERATION = 10,                -- Acceleration factor for fell animation
    STUMP_ACCELERATION = 4,                -- Acceleration factor for stump lowering
    STUMP_SINK_DISTANCE = 100,             -- Distance to sink stump node
    CLUTTER_HORIZONTAL_DISTANCE = 500,     -- Horizontal distance for clutter detection
    CLUTTER_VERTICAL_DISTANCE = 2000,      -- Vertical distance for clutter detection
    LOOT_HORIZONTAL_DISTANCE = 150,        -- Horizontal distance for loot dropping
    LOOT_VERTICAL_DISTANCE = 2000,         -- Vertical distance for loot dropping
    LOOT_ROOT_HEIGHT = 100,                -- Root height for loot orientation
    GROUND_CHECK_MAX_DISTANCE = 2000,      -- Max distance when checking ground below
    GROUND_ORIENT_ROOT_HEIGHT = 50,        -- Root height for ground orientation
}

-- Matrix objects for rotation calculations (reused to avoid GC)
local m1 = tes3matrix33.new()
local m2 = tes3matrix33.new()

-- ============================================================================
-- REGISTRY MANAGEMENT
-- ============================================================================

---Registry for tracking destroyed harvestables
DestructionManager.destroyedHarvestables = ReferenceController.registerReferenceController{
    id = "destroyedHarvestable",
    ---@param self any
    ---@param ref tes3reference
    requirements = function(self, ref)
        return (ref.data and ref.data.ashfallDestroyedHarvestable)
    end
}

-- ============================================================================
-- HARVEST TRACKING
-- ============================================================================

---Updates the total amount harvested from a reference
---@param reference tes3reference
---@param numHarvested number Amount to add to total
function DestructionManager.updateTotalHarvested(reference, numHarvested)
    reference.data.ashfallTotalHarvested = reference.data.ashfallTotalHarvested or 0
    reference.data.ashfallTotalHarvested = reference.data.ashfallTotalHarvested + numHarvested
    logger:trace("Added %s to total harvested, new total: %s", numHarvested, reference.data.ashfallTotalHarvested)
end

---Gets the total amount harvested from a reference
---@param reference tes3reference
---@return number totalHarvested
function DestructionManager.getTotalHarvested(reference)
    return reference.data.ashfallTotalHarvested or 0
end

-- ============================================================================
-- DESTRUCTION LIMIT MANAGEMENT
-- ============================================================================

---Sets the destruction limit for a reference
---@param reference tes3reference
---@param limit number
function DestructionManager.setDestructionLimit(reference, limit)
    reference.data.ashfallDestructionLimitConfig = limit
    reference.modified = true
end

---Gets the destruction limit for a reference
---@param reference tes3reference
---@return number|nil destructionLimit
function DestructionManager.getDestructionLimit(reference)
    return reference.data.ashfallDestructionLimitConfig
end

---Gets the height of a reference's bounding box
---@param reference tes3reference
---@return number height
function DestructionManager.getRefHeight(reference)
    return (reference.object.boundingBox.max.z - reference.object.boundingBox.min.z) * reference.scale
end

---Gets or sets the destruction limit based on reference height
---@param reference tes3reference
---@param destructionLimitConfig Ashfall.Harvest.Config.DestructionLimitConfig
---@return number destructionLimit
function DestructionManager.getSetDestructionLimit(reference, destructionLimitConfig)
    if not reference.data.ashfallDestructionLimitConfig then
        local height = DestructionManager.getRefHeight(reference)
        local minIn = destructionLimitConfig.minHeight
        local maxIn = destructionLimitConfig.maxHeight
        local minOut = destructionLimitConfig.min
        local maxOut = destructionLimitConfig.max
        local limit = math.remap(height, minIn, maxIn, minOut, maxOut)
        limit = math.clamp(limit, minOut, maxOut)
        limit = math.ceil(limit)
        logger:debug("Ref height: %s", height)
        logger:debug("Set destruction limit to %s", limit)
        DestructionManager.setDestructionLimit(reference, limit)
    end
    return reference.data.ashfallDestructionLimitConfig
end

---Checks if a reference has been exhausted (harvested enough times)
---@param reference tes3reference
---@param destructionLimit number
---@return boolean isExhausted
function DestructionManager.isExhausted(reference, destructionLimit)
    local totalHarvested = DestructionManager.getTotalHarvested(reference)
    return totalHarvested >= destructionLimit
end

-- ============================================================================
-- ENABLE/DISABLE HARVESTABLES
-- ============================================================================

---Enables a previously disabled harvestable (respawn)
---@param reference tes3reference
function DestructionManager.enableHarvestable(reference)
    logger:debug("Enabling Disabled Harvestable: %s", reference.id)

    -- Reset nodes to original state
    for _, nodeName in ipairs{"ASHFALL_TREEFALL", "ASHFALL_STUMP"} do
        local node = reference.sceneNode:getObjectByName(nodeName)
        if node then
            local parent = node.parent
            parent:detachChild(node)
            local originalNode = tes3.loadMesh(reference.object.mesh, false):getObjectByName(nodeName)
            parent:attachChild(originalNode)
            originalNode.appCulled = false
            parent:update()
        end
    end

    -- Restore original location if saved
    if reference.data and reference.data.ashfallHarvestOriginalLocation then
        logger:debug("Reseting location of %s", reference)
        tes3.positionCell{
            reference = reference,
            cell = reference.cell,
            position = reference.data.ashfallHarvestOriginalLocation.position,
            orientation = reference.data.ashfallHarvestOriginalLocation.orientation,
        }
    end

    reference:enable()
    reference.data.ashfallDestroyedHarvestable = nil
end

---Updates disabled harvestables, respawning them if player is far enough away
function DestructionManager.updateDisabledHarvestables()
    DestructionManager.destroyedHarvestables:iterate(function(reference)
        if reference.cell == tes3.player.cell then
            if reference.position:distance(tes3.player.position) > CONSTANTS.RESPAWN_DISTANCE then
                DestructionManager.enableHarvestable(reference)
            end
        end
    end)
end

---Disables a harvestable and triggers demolish animation
---@param reference tes3reference
---@param harvestableHeight number
---@param harvestConfig Ashfall.Harvest.Config
function DestructionManager.disableHarvestable(reference, harvestableHeight, harvestConfig)
    logger:debug("Disabling harvestable %s", reference)
    reference.data.ashfallTotalHarvested = nil
    reference.data.ashfallDestructionLimitConfig = nil
    DestructionManager.demolish{
        reference = reference,
        harvestableHeight = harvestableHeight,
        fallSpeed = harvestConfig.fallSpeed, ---@diagnostic disable-line: undefined-field
    }
end

---Checks if harvestable is exhausted and disables it if so
---@param reference tes3reference
---@param harvestConfig Ashfall.Harvest.Config
function DestructionManager.disableExhaustedHarvestable(reference, harvestConfig)
    local destructionLimitConfig = harvestConfig.destructionLimitConfig
    if not destructionLimitConfig then return end

    local destructionLimit = DestructionManager.getSetDestructionLimit(reference, destructionLimitConfig)
    if DestructionManager.isExhausted(reference, destructionLimit) then
        local harvestableHeight = DestructionManager.getRefHeight(reference)
        DestructionManager.disableHarvestable(reference, harvestableHeight, harvestConfig)

        if harvestConfig.fallSound then
            tes3.playSound{ sound = harvestConfig.fallSound}
        end

        if harvestConfig.clutter then
            DestructionManager.disableNearbyRefs(reference, harvestConfig, harvestableHeight)
        end
    end
end

-- ============================================================================
-- NEARBY REFERENCE MANAGEMENT
-- ============================================================================

---Disables clutter and drops loot near a destroyed harvestable
---@param harvestableRef tes3reference The harvestable being destroyed
---@param harvestConfig Ashfall.Harvest.Config
---@param harvestableHeight number
function DestructionManager.disableNearbyRefs(harvestableRef, harvestConfig, harvestableHeight)
    logger:debug("disabling nearby refs for %s", harvestableRef)
    local ignoreList = {}

    -- First pass: Disable clutter items
    for _, cell in ipairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences() do
            local isClutter = ref ~= harvestableRef
                and harvestConfig.clutter
                and harvestConfig.clutter[ref.baseObject.id:lower()]

            if isClutter then
                logger:trace("%s", ref.id)
                if common.helper.getCloseEnough({
                    ref1 = ref,
                    ref2 = harvestableRef,
                    distHorizontal = CONSTANTS.CLUTTER_HORIZONTAL_DISTANCE,
                    distVertical = CONSTANTS.CLUTTER_VERTICAL_DISTANCE
                }) then
                    logger:debug("close enough, disabling %s", ref.id)
                    DestructionManager.disableHarvestable(ref, harvestableHeight, harvestConfig)
                    table.insert(ignoreList, ref)
                end
            end
        end
    end

    -- Second pass: Drop nearby loot to ground
    for _, cell in ipairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences() do
            local activator = Activator.getForReference(ref)
            local isLoot = ref ~= harvestableRef
                and not (harvestConfig.clutter and harvestConfig.clutter[ref.baseObject.id:lower()])
                and not (activator and activator.type == "woodSource")
                and (ref.baseObject.objectType ~= tes3.objectType.static)

            if isLoot then
                -- Check if loot is close to harvestable
                if common.helper.getCloseEnough({
                    ref1 = ref,
                    ref2 = harvestableRef,
                    distHorizontal = CONSTANTS.LOOT_HORIZONTAL_DISTANCE,
                    distVertical = CONSTANTS.LOOT_VERTICAL_DISTANCE,
                    rootHeight = CONSTANTS.LOOT_ROOT_HEIGHT
                }) then
                    logger:debug("Found nearby %s", ref)
                    local result = common.helper.getGroundBelowRef{
                        doLog = false,
                        ref = ref,
                        ignoreList = ignoreList,
                        maxDistance = CONSTANTS.GROUND_CHECK_MAX_DISTANCE
                    }
                    local refBelow = result and result.reference
                    logger:debug("%s", result and result.reference)

                    if refBelow == harvestableRef then
                        local localIgnoreList = table.copy(ignoreList, {})
                        table.insert(localIgnoreList, harvestableRef)
                        logger:debug("Thing is indeed sitting on stump, orienting %s to ground", ref)

                        if ref.supportsLuaData and common.helper.getStackCount(ref) <= 1 then
                            logger:debug("adding to list of destroyedHarvestables")
                            ref.data.ashfallDestroyedHarvestable = true
                            ref.data.ashfallHarvestOriginalLocation = {
                                position = {
                                    ref.position.x,
                                    ref.position.y,
                                    ref.position.z
                                },
                                orientation = {
                                    ref.orientation.x,
                                    ref.orientation.y,
                                    ref.orientation.z,
                                }
                            }
                            DestructionManager.destroyedHarvestables:addReference(ref)
                        end

                        common.helper.orientRefToGround{
                            ref = ref,
                            ignoreList = localIgnoreList,
                            rootHeight = CONSTANTS.GROUND_ORIENT_ROOT_HEIGHT
                        }
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- ANIMATION FUNCTIONS
-- ============================================================================

---Rotates a node away from the player during fell animation
---@param reference tes3reference
---@param currentTime number
---@param totalTime number
---@param playerZ number Player's Z orientation
---@param acceleration number
---@param node niNode|nil Optional node to rotate
local function rotateNodeAwayFromPlayer(reference, currentTime, totalTime, playerZ, acceleration, node)
    local refZ = reference.orientation.z
    local rotZ = playerZ - refZ + 90

    if node then
        local u = 0
        local t = currentTime / totalTime
        local v = u + acceleration * t
        local rotation = CONSTANTS.FELL_ROTATION_DEGREES / totalTime * v

        local rotX = rotation * math.sin(rotZ)
        local rotY = rotation * math.cos(rotZ)
        m1:toRotationX(math.rad(rotX))
        m2:toRotationY(math.rad(rotY))
        node.rotation = node.rotation * m1:copy() * m2:copy()
        node:update()
    end
end

---Animates the tree fell and stump nodes
---@param e table Animation parameters
local function animateFellNode(e)
    if e.safeRef:valid() then
        -- Rotate fell node
        if e.fellNode then
            rotateNodeAwayFromPlayer(
                e.reference,
                e.currentIteration,
                e.iterations,
                e.playerZ,
                CONSTANTS.FELL_ACCELERATION,
                e.fellNode
            )
        end

        -- Lower stump node
        if e.stumpNode then
            local a = CONSTANTS.STUMP_ACCELERATION
            local u = 0
            local t = e.currentIteration / e.iterations
            local v = u + a * t
            e.stumpNode.translation = e.stumpNode.translation + tes3vector3.new(
                0,
                0,
                -(CONSTANTS.STUMP_SINK_DISTANCE / e.iterations) * v
            )
            e.stumpNode:update()
        end

        e.currentIteration = e.currentIteration + 1
    end
end

---Default animation for harvestables without special nodes
---@param e table Animation parameters
local function animateDefault(e)
    if e.safeRef:valid() then
        local ref = e.safeRef:getObject()
        tes3.positionCell{
            reference = ref,
            cell = ref.cell,
            ---@diagnostic disable-next-line: missing-fields
            position = {
                ref.position.x,
                ref.position.y,
                ref.position.z - (e.harvestableHeight * 0.5) / e.iterations
            },
        }
        e.currentIteration = e.currentIteration + 1
    end
end

---@class Ashfall.DestructionManager.demolish.params
---@field reference tes3reference
---@field harvestableHeight number
---@field fallSpeed? number Optional, default 10
---@field callback? fun(ref: tes3reference) Optional, called when animation is complete

---Demolishes a harvestable with animation
---@param e Ashfall.DestructionManager.demolish.params
function DestructionManager.demolish(e)
    local safeRef = tes3.makeSafeObjectHandle(e.reference)
    if not safeRef then return end

    local iterations = CONSTANTS.ANIMATION_ITERATIONS
    local originalLocation = {
        position = {
            e.reference.position.x,
            e.reference.position.y,
            e.reference.position.z
        },
        orientation = {
            e.reference.orientation.x,
            e.reference.orientation.y,
            e.reference.orientation.z,
        }
    }

    local fellNode = e.reference.sceneNode:getObjectByName("ASHFALL_TREEFALL")
    local stumpNode = e.reference.sceneNode:getObjectByName("ASHFALL_STUMP")
    local playerZ = tes3.player.orientation.z

    logger:debug("Adding to destroyedHarvestables: %s", e.reference.id)
    e.reference.data.ashfallDestroyedHarvestable = true
    DestructionManager.destroyedHarvestables:addReference(e.reference)

    local currentIteration = 0
    local duration = e.fallSpeed or 10

    -- Animation timer
    timer.start{
        duration = duration / iterations,
        iterations = iterations,
        type = timer.simulate,
        callback = function()
            if fellNode then
                local animParams = {
                    safeRef = safeRef,
                    fellNode = fellNode,
                    stumpNode = stumpNode,
                    iterations = iterations,
                    currentIteration = currentIteration,
                    playerZ = playerZ,
                    reference = e.reference
                }
                animateFellNode(animParams)
                currentIteration = animParams.currentIteration
            else
                local animParams = {
                    safeRef = safeRef,
                    iterations = iterations,
                    currentIteration = currentIteration,
                    harvestableHeight = e.harvestableHeight,
                    reference = e.reference
                }
                animateDefault(animParams)
                currentIteration = animParams.currentIteration
            end
        end,
    }

    -- Completion timer
    timer.start{
        duration = duration,
        iterations = 1,
        type = timer.simulate,
        callback = function()
            if safeRef:valid() then
                local ref = safeRef:getObject()
                tes3.positionCell{
                    reference = ref,
                    cell = ref.cell,
                    position = originalLocation.position,
                    orientation = originalLocation.orientation
                }
                ref:disable()
                if e.callback then
                    e.callback(ref)
                end
            end
        end
    }
end

return DestructionManager
