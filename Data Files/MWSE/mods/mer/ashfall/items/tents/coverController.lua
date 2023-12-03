local this = {}

local common = require("mer.ashfall.common.common")
local logger = common.createLogger("coverController")
local tentConfig = require("mer.ashfall.items.tents.tentConfig")

local function getAttachCoverNode(node)
    return node and node:getObjectByName("ATTACH_COVER")
end

local function attachMeshToRef(ref, meshPath)
    local attachCoverNode = getAttachCoverNode(ref.sceneNode)
    local mesh = common.helper.loadMesh(meshPath)
    attachCoverNode:attachChild(mesh)
    attachCoverNode:update()
    attachCoverNode:updateNodeEffects()
    ref.modified = true
    logger:debug("cover attached to %s", ref.object.id)
end

function this.tentHasCover(tentRef)
    return tentRef and tentRef.data.tentCover ~= nil
end

function this.canHaveCover(ref)
    return getAttachCoverNode(ref.sceneNode) ~= nil
end


function this.selectCover(tentRef)
    timer.delayOneFrame(function()
        common.helper.showInventorySelectMenu{
            title = "Select Tent Cover",
            noResultsText = "You don't have any tent covers.",
            filter = function(e)
                return tentConfig.coverToMeshMap[e.item.id:lower()] ~= nil
            end,
            callback = function(e)
                if e.item then
                    logger:debug("attaching cover")
                    this.attachCover(e.reference, tentRef, e.item.id)
                end
            end
        }
    end)
end



function this.attachCover(reference, tentRef, coverId)
    local coverNode = getAttachCoverNode(tentRef.sceneNode)
    if coverNode then
        logger:debug("found cover node for %s", tentRef.object.id)
        --remove existing cover
        if #coverNode.children > 0 then
            logger:debug("Found existing child of cover node, removing")
            coverNode:detachChildAt(1)
        end

        local meshPath = tentConfig.coverToMeshMap[coverId:lower()]
        if meshPath then
            --attach mesh to tent
            attachMeshToRef(tentRef, meshPath)
            tentRef.data.tentCover = coverId
            tes3.removeItem{ reference = reference, item = coverId, playSound = false}
        else
            logger:error("%s is not a valid tent cover.", coverId)
        end
    else
        logger:error("%s does not have an ATTACH_COVER node.", tentRef.object.id)
    end
end

function this.removeCover(tentRef)
    local coverNode = getAttachCoverNode(tentRef.sceneNode)
    if coverNode then
        logger:debug("found cover node for %s", tentRef.object.id)
        if #coverNode.children > 0 then
            coverNode:detachChildAt(1)
            coverNode:update()
            coverNode:updateNodeEffects()
            tes3.addItem{ reference = tes3.player, item = tentRef.data.tentCover }
            tentRef.data.tentCover = nil
        else
            logger:error("%s has no cover to remove.", tentRef.object.id)
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