local common = require("mer.ashfall.common.common")
local logger = common.createLogger("gearPlacement")
local placementConfig = require("mer.ashfall.gearPlacement.config")
--[[
    Orients a placed object and lowers it into the ground so it lays flat against the terrain,
]]

local function onDropGear(e)

    local gearValues = placementConfig[string.lower(e.reference.object.id)]
    if gearValues or (e.reference.object.sourceMod and e.reference.object.sourceMod:lower() == "ashfall.esp") then
        gearValues = gearValues or { maxSteepness = 0.5 }
        local hasWater = e.reference.data and e.reference.data.waterAmount and e.reference.data.waterAmount > 0
        local maxSteepness = gearValues.maxSteepness
        if hasWater then
            maxSteepness = 0
        end
        if gearValues.maxSteepness then
            common.helper.orientRefToGround{ ref = e.reference, maxSteepness = maxSteepness }
        end
        if gearValues.drop then
            logger:debug("Dropping %s by %s", e.reference.object.name, gearValues.drop)
            e.reference.position = {
                e.reference.position.x,
                e.reference.position.y,
                e.reference.position.z - gearValues.drop,
            }
        end
        event.trigger("Ashfall:GearDropped", e)
    end
end
event.register("itemDropped", onDropGear, { priority = 100})


--[[
    For any mesh with the "verticalise" flag, find nodes to set to vertical
]]
local function verticalise(e)
    -- local z = e.node.worldTransform.rotation:copy()
    -- z:toRotationZ(z:toEulerXYZ().z)
    -- e.node.rotation = e.node.parent.worldTransform.rotation:invert() * z
    -- e.node:update()
    local r = e.node.worldTransform.rotation:transpose()
    local eulers = r:toEulerXYZ()
    r:fromEulerXYZ(eulers.x, eulers.y, 0.0)
    e.node.rotation = e.node.rotation * r
    e.node:update()
end

local function verticaliseNode(e)
    local vertNode = e.node:getObjectByName("ALIGN_VERTICAL")
    if vertNode then
        logger:trace("Verticalising node")
        verticalise{ node = vertNode }
    else
        logger:trace("no ALIGN_VERTICAL node found")
    end
    local collisionNode = e.node:getObjectByName("COLLISION_VERTICAL")
    if collisionNode then
        logger:trace("Verticalising collision node")
        verticalise{ node = collisionNode }
    end
end
event.register("Ashfall:VerticaliseNode", verticaliseNode)


local function verticaliseNodes(e)
    if e.reference.disabled then return end
    if not e.reference.sceneNode then return end
    if e.reference.sceneNode:getObjectByName("ALIGN_VERTICAL") then
        local safeRef = tes3.makeSafeObjectHandle(e.reference)
        local function f()
            if not safeRef:valid() then return end
            verticaliseNode{ node = e.reference.sceneNode }
        end
        event.register("enterFrame", f, {doOnce=true})
    end
end
event.register("Ashfall:VerticaliseNodes", verticaliseNodes)
event.register("referenceSceneNodeCreated", verticaliseNodes)