local this = {}

local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local tentConfig = require("mer.ashfall.camping.tents.tentConfig")

local function getAttachLanternNode(node)
    return node and node:getObjectByName("ATTACH_LANTERN")
end


local function turnLanternOn(tentRef)
    local lanternNode = getAttachLanternNode(tentRef.sceneNode)
    local lanternId = tentRef.data.lantern
    local lanternItem = tes3.getObject(lanternId)

    local lightNode = lanternNode:getObjectByName("LanternLight") or niPointLight.new()
    lightNode.name = "LanternLight"
    if lanternItem.color then
        lightNode.ambient = tes3vector3.new(0,0,0)
        lightNode.diffuse = tes3vector3.new(
            lanternItem.color[1] / 255,
            lanternItem.color[2] / 255,
            lanternItem.color[3] / 255
        )
    else
        lightNode.ambient = tes3vector3.new(0,0,0)
        lightNode.diffuse = tes3vector3.new(255, 255, 255)
    end
    lightNode.translation.z = 0
    lightNode:setAttenuationForRadius(512)
    
    local attachLight = lanternNode
    attachLight:attachChild(lightNode)

    tentRef.sceneNode:update()
    tentRef.sceneNode:updateNodeEffects()
    tentRef:getOrCreateAttachedDynamicLight(lightNode, 1.0)

    --Switch node for rope
    local lightSwitchNode = tentRef.sceneNode:getObjectByName("ATTACH_LANTERN_SWITCH")
    if lightSwitchNode then
        lightSwitchNode.switchIndex = 1
    end
    tentRef:updateLighting()
end

local function turnLanternOff(tentRef)
    local lanternNode = getAttachLanternNode(tentRef.sceneNode)
    common.helper.removeLight(lanternNode)
    local lightNode = lanternNode:getObjectByName("LanternLight")
    lightNode:setAttenuationForRadius(0)
    lightNode.translation.z = 1000
    tentRef.sceneNode:update()
    tentRef.sceneNode:updateNodeEffects()

    --Switch node for rope
    local lightSwitchNode = tentRef.sceneNode:getObjectByName("ATTACH_LANTERN_SWITCH")
    if lightSwitchNode then
        lightSwitchNode.switchIndex = 0
    end
    tentRef:updateLighting()
end



--Lantern stuff
function this.isLantern(obj)
    local isLantern = obj.objectType == tes3.objectType.light
        and obj.canCarry == true
        and ( string.find(obj.id:lower(), "lantern")
            or string.find(obj.name:lower(), "lantern") )
    return isLantern
    --return tentConfig.lanternIds[obj.id:lower()]
end

function this.playerHasLantern()
    for _, stack in pairs(tes3.player.object.inventory) do
        if this.isLantern(stack.object) then
            return true
        end
    end
    return false
end

function this.selectLantern(tentRef)
    timer.delayOneFrame(function()
        tes3ui.showInventorySelectMenu{
            title = "Select Lantern",
            noResultsText = "You don't have any lanterns.",
            filter = function(e)
                return this.isLantern(e.item)
            end,
            callback = function(e)
                if e.item then
                    common.log:debug("attaching lantern")
                    this.attachLantern(tentRef, e.item)
                end
            end
        }
    end)
end

function this.canHaveLantern(ref)
    return getAttachLanternNode(ref.sceneNode) ~= nil
end

function this.tentHasLantern(ref)
    return ref and ref.data.lantern ~= nil
end

local function attachLightToRef(tentRef, lanternItem)
    local lanternMesh = tes3.loadMesh(lanternItem.mesh):clone()
    lanternMesh:clearTransforms()
    local attachLanternNode = getAttachLanternNode(tentRef.sceneNode)
    attachLanternNode:attachChild(lanternMesh, true)
    turnLanternOn(tentRef)
    attachLanternNode:update()
    attachLanternNode:updateNodeEffects()
    tentRef.modified = true
    common.log:debug("lantern attached to %s", tentRef.object.id)
end

function this.attachLantern(tentRef, lanternItem)
    common.log:debug("attachLantern: %s", lanternItem)
    local attachLanternNode = getAttachLanternNode(tentRef.sceneNode)
    if attachLanternNode then
        common.log:debug("found lantern node for %s", tentRef.object.id)
        --remove existing lantern
        if #attachLanternNode.children > 0 then
            common.log:debug("Found existing child of lantern node, removing")
            attachLanternNode:detachChildAt(1)
        end
        --attach mesh to tent
        tentRef.data.lantern = lanternItem.id:lower()
        attachLightToRef(tentRef, lanternItem)
        tes3.removeItem{ reference = tes3.player, item = lanternItem, playSound = false}
        common.log:debug("Registering tent with %s as a reference", lanternItem)
    else
        common.log:error("%s does not have an ATTACH_LANTERN node.", tentRef.object.id)
    end
end

function this.removeLantern(tentRef)
    local attachLanternNode = getAttachLanternNode(tentRef.sceneNode)
    if attachLanternNode and tentRef.data.lantern then
        turnLanternOff(tentRef)
        common.log:debug("found trinket node for %s", tentRef.object.id)
        if #attachLanternNode.children > 0 then
            attachLanternNode:detachChildAt(1)
            attachLanternNode:update()
            attachLanternNode:updateNodeEffects()
            local lantern = tentRef.data.lantern
            tes3.addItem{ reference = tes3.player, item =lantern, playSound = false }
            tentRef.data.lantern = nil
        else
            common.log:error("%s has no lantern to remove.", tentRef.object.id)
        end
    end
end


local function onRefSceneNodeCreatedAddTrinkets(e)
    local lanternId = e.reference
                and e.reference.data 
                and e.reference.data.lantern
    if lanternId and this.canHaveLantern(e.reference) then
        local lantern = tes3.getObject(lanternId)
        if lantern then
            attachLightToRef(e.reference, lantern)
        end
    end
end
event.register("referenceSceneNodeCreated", onRefSceneNodeCreatedAddTrinkets)

return this