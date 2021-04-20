local this = {}

local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local tentConfig = require("mer.ashfall.camping.tents.tentConfig")

local function getTrinketNode(node)
    return node and node:getObjectByName("ATTACH_TRINKET")
end

local function attachMeshToRef(ref, meshPath)
    local trinketNode = getTrinketNode(ref.sceneNode)
    local mesh = tes3.loadMesh(meshPath):clone()
    trinketNode:attachChild(mesh)
    trinketNode:update()
    trinketNode:updateNodeEffects()
    ref.modified = true
    common.log:debug("trinket attached to %s", ref.object.id)
    -- timer.frame.delayOneFrame(function()
    --     event.trigger("Ashfall:VerticaliseNode", { node = trinketNode.parent.parent})
    -- end)
    
end


function this.tentHasTrinket(tentRef)
    return tentRef and tentRef.data.trinket ~= nil
end

function this.canHaveTrinket(ref)
    return getTrinketNode(ref.sceneNode) ~= nil
end

function this.attachTrinket(tentRef, trinketId)
    local trinketNode = getTrinketNode(tentRef.sceneNode)
    if trinketNode then
        common.log:debug("found trinket node for %s", tentRef.object.id)
        --remove existing trinket
        if #trinketNode.children > 0 then
            common.log:debug("Found existing child of trinket node, removing")
            trinketNode:detachChildAt(1)
        end

        local meshPath = tentConfig.trinketToMeshMap[trinketId:lower()]
        if meshPath then
            --attach mesh to tent
            attachMeshToRef(tentRef, meshPath)
            tentRef.data.trinket = trinketId
            tes3.removeItem{ reference = tes3.player, item = trinketId}
        else
            common.log:error("%s is not a valid trinket.", trinketId)
        end
    else
        common.log:error("%s does not have an ATTACH_TRINKET node.", tentRef.object.id)
    end
end

function this.removeTrinket(tentRef)
    local trinketNode = getTrinketNode(tentRef.sceneNode)
    if trinketNode then
        common.log:debug("found trinket node for %s", tentRef.object.id)
        if #trinketNode.children > 0 then
            trinketNode:detachChildAt(1)
            trinketNode:update()
            trinketNode:updateNodeEffects()
            tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
            tes3.addItem{ reference = tes3.player, item = tentRef.data.trinket }
            tentRef.data.trinket = nil
        else
            common.log:error("%s has no trinket to remove.", tentRef.object.id)
        end
    end
end

local function onRefSceneNodeCreatedAddTrinkets(e)
    local trinketId = e.reference
                and e.reference.data 
                and e.reference.data.trinket
    if trinketId and this.canHaveTrinket(e.reference) then
        local meshPath = tentConfig.trinketToMeshMap[trinketId:lower()]
        attachMeshToRef(e.reference, meshPath)
    end
end
event.register("referenceSceneNodeCreated", onRefSceneNodeCreatedAddTrinkets)


return this