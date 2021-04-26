local this = {}
--initialise modules
require("mer.ashfall.camping.tents.trinkets.trinketEffects")
require("mer.ashfall.camping.tents.trinkets.ward")
require("mer.ashfall.camping.tents.trinkets.dreamcatcher")
require("mer.ashfall.camping.tents.trinkets.chimes")
require("mer.ashfall.camping.tents.trinkets.bouquet")

local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local tentConfig = require("mer.ashfall.camping.tents.tentConfig")



local function getTrinketNode(node)
    return node and node:getObjectByName("ATTACH_TRINKET")
end

local function addTrinketSound(ref, trinket)
    if trinket.soundPath then
        common.log:debug("playing sound on trinket")
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
    local mesh = tes3.loadMesh(meshPath):clone()
    trinketNode:attachChild(mesh)
    trinketNode:update()
    trinketNode:updateNodeEffects()
    ref.modified = true

    ref.data.trinket = trinket.id
    event.trigger("Ashfall:registerReference", { reference = ref})
    common.log:debug("trinket attached to %s", ref.object.id)
end

function this.tentHasTrinket(tentRef)
    return tentRef and tentRef.data.trinket ~= nil
end

function this.canHaveTrinket(ref)
    return getTrinketNode(ref.sceneNode) ~= nil
end


function this.selectTrinket(tentRef)
    timer.delayOneFrame(function()
        tes3ui.showInventorySelectMenu{
            title = "Select Trinket",
            noResultsText = "You don't have any trinkets.",
            filter = function(e)
                return tentConfig.trinkets[e.item.id:lower()] ~= nil
            end,
            callback = function(e)
                if e.item then
                    common.log:debug("attaching trinket")
                    this.attachTrinket(tentRef, e.item.id)
                end
            end
        }
    end)
end


function this.attachTrinket(tentRef, trinketId)
    common.log:debug("attachTrinket: %s", trinketId)
    local trinketNode = getTrinketNode(tentRef.sceneNode)
    if trinketNode then
        common.log:debug("found trinket node for %s", tentRef.object.id)
        --remove existing trinket
        if #trinketNode.children > 0 then
            common.log:debug("Found existing child of trinket node, removing")
            trinketNode:detachChildAt(1)
        end

        local trinket = tentConfig.getTrinketData(trinketId)
        if trinket then
            --attach mesh to tent
            attachMeshToRef(tentRef, trinket)
            tes3.removeItem{ reference = tes3.player, item = trinketId, playSound = false}
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
            tes3.addItem{ reference = tes3.player, item = tentRef.data.trinket }
            removeTrinketSound(tentRef)
            local trinket = tentConfig.getTrinketData(tentRef.data.trinket) 
            event.trigger("Ashfall:DisableTrinketEffect", trinket)
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
        local trinket = tentConfig.getTrinketData(trinketId)
        if trinket then
            attachMeshToRef(e.reference, trinket)
        end
    end
end
event.register("referenceSceneNodeCreated", onRefSceneNodeCreatedAddTrinkets)


return this