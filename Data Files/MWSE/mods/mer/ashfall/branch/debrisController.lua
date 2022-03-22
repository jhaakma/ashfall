-- --[[
--     Handles the randomised placement of natural debris such
--     as branches, stones and flint.
-- ]]
-- local common = require("mer.ashfall.common.common")
-- local logger = common.createLogger("debrisController")
-- local config = require("mer.ashfall.config").config
-- local branchConfig = require("mer.ashfall.branch.branchConfig")

-- local MAX_STEEPNESS = 0.7

-- local function addItemToWorld(debrisId, position, scale)
--     local ref = tes3.createReference{
--         object = debrisId,
--         position = position,
--         cell = tes3.player.cell,
--         scale = scale,
--     }
--     local didOrient = common.helper.orientRefToGround{
--         ref = ref,
--         terrainOnly = true
--     }
--     local tooSteep = math.abs(ref.orientation.x) > MAX_STEEPNESS
--                   or math.abs(ref.orientation.y) > MAX_STEEPNESS
--     --Delete if unable to orient properly
--     if tooSteep or not didOrient then
--         ref:disable()
--         mwscript.setDelete{ reference = ref}
--         return
--     end

--     --Randomise the Z orientation
--     ref.orientation = {
--         ref.orientation.x,
--         ref.orientation.y,
--         math.remap(math.random(), 0, 1, -math.pi, math.pi)
--     }
--     return ref
-- end

-- local function calculateDebrisLocationData(debris, target)
--     local position = {
--         target.position.x +
--             math.random(debris.minPlaceDistance, debris.maxPlaceDistance)
--             * math.random() < 0.5 and 1 or -1,
--         target.position.y +
--             math.random(debris.minPlaceDistance, debris.maxPlaceDistance)
--             * math.random() < 0.5 and 1 or -1,
--         target.position.z + 10000
--     }

--     return {
--         object = debris.object
--         position = position,

--     }
-- end

-- local function addDebrisAroundReference(debris, target, num)
--     for _ = 1, num do


--         local scale = math.random(debris.minScale, debris.maxScale) * 0.01
--         local ref = addItemToWorld(debris.id, position, scale)
--     end
-- end