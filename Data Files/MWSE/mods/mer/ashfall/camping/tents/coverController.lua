local this = {}

local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local tentConfig = require("mer.ashfall.camping.tents.tentConfig")

local function getCoverNode(node)
    return node and node:getObjectByName("ATTACH_COVER")
end

local function attachMeshToRef(ref, meshPath)
    local coverNode = getCoverNode(ref.sceneNode)
    local mesh = tes3.loadMesh(meshPath):clone()
    coverNode:attachChild(mesh)
    coverNode:update()
    coverNode:updateNodeEffects()
    ref.modified = true
    common.log:debug("cover attached to %s", ref.object.id)
end


function this.tentHasCover(tentRef)
    return tentRef and tentRef.data.tentCover ~= nil
end

function this.canHaveCover(ref)
    return getCoverNode(ref.sceneNode) ~= nil
end

function this.attachCover(tentRef, coverId)
    local coverNode = getCoverNode(tentRef.sceneNode)
    if coverNode then
        common.log:debug("found cover node for %s", tentRef.object.id)
        --remove existing cover
        if #coverNode.children > 0 then
            common.log:debug("Found existing child of cover node, removing")
            coverNode:detachChildAt(1)
        end

        local meshPath = tentConfig.coverToMeshMap[coverId:lower()]
        if meshPath then
            --attach mesh to tent
            attachMeshToRef(tentRef, meshPath)
            tentRef.data.tentCover = coverId
            tes3.removeItem{ reference = tes3.player, item = coverId}
        else
            common.log:error("%s is not a valid tent cover.", coverId)
        end
    else
        common.log:error("%s does not have an ATTACH_COVER node.", tentRef.object.id)
    end
end

function this.removeCover(tentRef)
    local coverNode = getCoverNode(tentRef.sceneNode)
    if coverNode then
        common.log:debug("found cover node for %s", tentRef.object.id)
        if #coverNode.children > 0 then
            coverNode:detachChildAt(1)
            coverNode:update()
            coverNode:updateNodeEffects()
            tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
            tes3.addItem{ reference = tes3.player, item = tentRef.data.tentCover }
            tentRef.data.tentCover = nil
            
        else
            common.log:error("%s has no cover to remove.", tentRef.object.id)
        end
    end
end

local function onRefSceneNodeCreatedAddCovers(e)
    local coverId = e.reference
                and e.reference.data 
                and e.reference.data.tentCover 
    if coverId and this.canHaveCover(e.reference) then
        local meshPath = tentConfig.coverToMeshMap[coverId:lower()]
        attachMeshToRef(e.reference, meshPath)
    end
end
event.register("referenceSceneNodeCreated", onRefSceneNodeCreatedAddCovers)


return this