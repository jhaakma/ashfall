local common = require("mer.ashfall.common.common")

--[[
    Orients a placed object and lowers it into the ground so it lays flat against the terrain,
]]
 

local function canDropGear()
    if tes3.player.cell.isInterior then
        return false
    end
    if tes3.player.cell.restingIsIllegal then
        if not common.config:getConfig().canCampInSettlements then
            return false
        end
    end 
    return true
end


local function onDropGear(e)
    local gearValues = common.staticConfigs.placementConfig[string.lower(e.reference.object.id)]
    if gearValues then
        if gearValues.blockIllegal then --not currently used?
            if not canDropGear() then
                tes3.addItem{
                    reference = tes3.player,
                    item = e.reference.object,
                    updateGUI = true,
                    count =  1
                }
                e.reference:disable()
                mwscript.setDelete{ reference = e.reference}
                tes3.messageBox("You can't place that here, resting is illegal.")
                return
            end
        end

        timer.frame.delayOneFrame(function()
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
        end)
    end
end

event.register("itemDropped", onDropGear)



--[[
    For any mesh with the "verticalise" flag, find nodes to set to vertical
]]
local function verticalise(node)
    local z = node.worldTransform.rotation:copy()
    z:toRotationZ(z:toEulerXYZ().z)
    node.rotation = node.worldTransform.rotation:invert() * z
    node:update()
end

local function verticaliseNodes(e)

    if e.reference.disabled then return end
    if e.reference.sceneNode and e.reference.sceneNode:hasStringDataWith("verticalise") then
        local safeRef = tes3.makeSafeObjectHandle(e.reference)
        local function f() 
            if not safeRef:valid() then return end
            common.log:debug("Verticalising %s", e.reference.object.id)
            local vertNode = e.reference.sceneNode:getObjectByName("ALIGN_VERTICAL")

            if vertNode then
                verticalise(vertNode)
            else
                common.log:debug("no ALIGN_VERTICAL node found")
            end
            local collisionNode = e.reference.sceneNode:getObjectByName("COLLISION_VERTICAL")
            if collisionNode then
                verticalise(collisionNode)
            end
        end
        event.register("enterFrame", f, {doOnce=true})
    end
end
event.register("Ashfall:VerticaliseNodes", verticaliseNodes)
event.register("referenceSceneNodeCreated", verticaliseNodes)