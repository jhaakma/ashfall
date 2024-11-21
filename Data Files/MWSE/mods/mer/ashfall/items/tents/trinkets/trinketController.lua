local this = {}
--initialise modules
require("mer.ashfall.items.tents.trinkets.trinketEffects")
require("mer.ashfall.items.tents.trinkets.ward")
require("mer.ashfall.items.tents.trinkets.dreamcatcher")
require("mer.ashfall.items.tents.trinkets.chimes")
require("mer.ashfall.items.tents.trinkets.bouquet")

local common = require("mer.ashfall.common.common")
local logger = common.createLogger("trinketController")
local tentConfig = require("mer.ashfall.items.tents.tentConfig")



local function getTrinketNode(node)
    return node and node:getObjectByName("ATTACH_TRINKET")
end

local function addTrinketSound(ref, trinket)
    if trinket.soundPath then
        logger:debug("playing sound on trinket")
        tes3.playSound{ reference = ref, soundPath = trinket.soundPath, loop = true}
    end
end

local function removeTrinketSound(ref)
    local trinketId = ref.data.trinket
    local trinket = tentConfig.getTrinketData(trinketId)
    if trinket and trinket.soundPath then
        tes3.removeSound{ reference = ref, soundPath = trinket.soundPath}
    end
end

local function attachMeshToRef(ref, trinket)
    addTrinketSound(ref, trinket)
    local meshPath = trinket.mesh
    local trinketNode = getTrinketNode(ref.sceneNode)
    local mesh = common.helper.loadMesh(meshPath)
    trinketNode:attachChild(mesh)
    trinketNode:update()
    trinketNode:updateNodeEffects()
    ref.modified = true

    ref.data.trinket = trinket.id
    event.trigger("Ashfall:registerReference", { reference = ref})
    logger:debug("trinket attached to %s", ref.object.id)
end

function this.tentHasTrinket(tentRef)
    return tentRef and tentRef.data.trinket ~= nil
end

function this.canHaveTrinket(ref)
    return getTrinketNode(ref.sceneNode) ~= nil
end


function this.selectTrinket(tentRef)
    timer.delayOneFrame(function()
        common.helper.showInventorySelectMenu{
            title = "Select Trinket",
            noResultsText = "You don't have any trinkets.",
            filter = function(e)
                return tentConfig.trinkets[e.item.id:lower()] ~= nil
            end,
            callback = function(e)
                if e.item then
                    logger:debug("attaching trinket")
                    this.attachTrinket(e.reference, tentRef, e.item.id)
                end
            end
        }
    end)
end

---comment
---@param reference tes3reference
---@param tentRef tes3reference
---@param trinketId string
function this.attachTrinket(reference, tentRef, trinketId)
    logger:debug("attachTrinket: %s", trinketId)
    local trinketNode = getTrinketNode(tentRef.sceneNode)
    if trinketNode then
        logger:debug("found trinket node for %s", tentRef.object.id)
        --remove existing trinket
        if #trinketNode.children > 0 then
            logger:debug("Found existing child of trinket node, removing")
            trinketNode:detachChildAt(1)
        end

        local trinket = tentConfig.getTrinketData(trinketId)
        if trinket then
            --attach mesh to tent
            attachMeshToRef(tentRef, trinket)
            tes3.removeItem{ reference = reference, item = trinketId, playSound = false}
        else
            logger:error("%s is not a valid trinket.", trinketId)
        end
    else
        logger:error("%s does not have an ATTACH_TRINKET node.", tentRef.object.id)
    end
end

function this.removeTrinket(tentRef)
    local trinketNode = getTrinketNode(tentRef.sceneNode)
    if trinketNode then
        logger:debug("found trinket node for %s", tentRef.object.id)
        if #trinketNode.children > 0 then
            trinketNode:detachChildAt(1)
            trinketNode:update()
            trinketNode:updateNodeEffects()
            tes3.addItem{ reference = tes3.player, item = tentRef.data.trinket }
            removeTrinketSound(tentRef)
            local trinket = tentConfig.getTrinketData(tentRef.data.trinket)
            event.trigger("Ashfall:DisableTrinketEffect", trinket)
            tentRef.data.trinket = nil
        else
            logger:error("%s has no trinket to remove.", tentRef.object.id)
        end
    end
end

local function onRefSceneNodeCreatedAddTrinkets(e)
    local trinketId = e.reference
                and e.reference.data
                and e.reference.data.trinket
    if trinketId and this.canHaveTrinket(e.reference) then
        local trinket = tentConfig.getTrinketData(trinketId)
        if trinket then
            attachMeshToRef(e.reference, trinket)
        end
    end
end
event.register("referenceActivated", onRefSceneNodeCreatedAddTrinkets)


return this