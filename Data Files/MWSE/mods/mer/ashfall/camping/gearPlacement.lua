local common = require("mer.ashfall.common.common")

--[[
    Orients a placed object and lowers it into the ground so it lays flat against the terrain,
]]

local function onDropGear(e)
    local gearValues = common.staticConfigs.placementConfig[string.lower(e.reference.object.id)]
    if gearValues or (e.reference.object.sourceMod and e.reference.object.sourceMod:lower() == "ashfall.esp") then
        gearValues = gearValues or { maxSteepness = 0.5 }
        if gearValues.maxSteepness then
            common.helper.orientRefToGround{ ref = e.reference, maxSteepness = gearValues.maxSteepness }
        end
        if gearValues.drop then
            common.log:debug("Dropping %s by %s", e.reference.object.name, gearValues.drop)
            e.reference.position = {
                e.reference.position.x,
                e.reference.position.y,
                e.reference.position.z - gearValues.drop,
            }
        end
        event.trigger("Ashfall:GearDropped", e)

    end
end

event.register("itemDropped", onDropGear)



--[[
    For any mesh with the "verticalise" flag, find nodes to set to vertical
]]
local function verticalise(e)
    local z = e.node.worldTransform.rotation:copy()
    z:toRotationZ(z:toEulerXYZ().z)
    e.node.rotation = e.node.worldTransform.rotation:invert() * z
    e.node:update()
end

local function verticaliseNode(e)
    local vertNode = e.node:getObjectByName("ALIGN_VERTICAL")
    if vertNode then
        common.log:debug("Verticalising node")
        verticalise{ node = vertNode }
    else
        common.log:debug("no ALIGN_VERTICAL node found")
    end
    local collisionNode = e.node:getObjectByName("COLLISION_VERTICAL")
    if collisionNode then
        common.log:debug("Verticalising collision node")
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
            common.log:debug("Verticalising %s", e.reference.object.id)
            verticaliseNode{ node = e.reference.sceneNode }
        end
        event.register("enterFrame", f, {doOnce=true})
    end
end
event.register("Ashfall:VerticaliseNodes", verticaliseNodes)
event.register("referenceSceneNodeCreated", verticaliseNodes)