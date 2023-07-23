local this = {}

local common = require("mer.ashfall.common.common")
local logger = common.createLogger("lanternController")

local function getAttachLanternNode(node)
    return node and node:getObjectByName("ATTACH_LANTERN")
end


local function turnLanternOn(tentRef)
    local lanternNode = getAttachLanternNode(tentRef.sceneNode)
    local lanternId = tentRef.data.lantern.id
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

    local isLight = obj.objectType == tes3.objectType.light
    local canCarry = obj.canCarry == true
    local idIsLantern = string.find(obj.id:lower(), "lantern")
    local nameIsLantern = string.find(obj.name:lower(), "lantern")

    if not isLight then return false end
    if not canCarry then return false end
    if idIsLantern then return true end
    if nameIsLantern then return true end
    return false
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
                    logger:debug("attaching lantern")
                    this.attachLantern(tentRef, e.item, e.itemData)
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
    local lanternMesh = common.helper.loadMesh(lanternItem.mesh)
    lanternMesh:clearTransforms()
    local attachLanternNode = getAttachLanternNode(tentRef.sceneNode)
    attachLanternNode:attachChild(lanternMesh, true)
    turnLanternOn(tentRef)
    attachLanternNode:update()
    attachLanternNode:updateNodeEffects()
    tentRef.modified = true
    logger:debug("lantern attached to %s", tentRef.object.id)
end

function this.attachLantern(tentRef, lanternItem, lanternData)
    logger:debug("attachLantern: %s", lanternItem)
    local attachLanternNode = getAttachLanternNode(tentRef.sceneNode)
    if attachLanternNode then
        logger:debug("found lantern node for %s", tentRef.object.id)
        --remove existing lantern
        if #attachLanternNode.children > 0 then
            logger:debug("Found existing child of lantern node, removing")
            attachLanternNode:detachChildAt(1)
        end
        --attach mesh to tent
        tentRef.data.lantern = {
            id = lanternItem.id:lower(),
            data = lanternData
        }
        if lanternData then
            logger:debug("Printing lanternData.data")
            logger:debug(json.encode(lanternData.data))
            tentRef.data.lantern.data = {
                timeLeft = lanternData.timeLeft,
                data = lanternData.data
            }
        end
        attachLightToRef(tentRef, lanternItem)
        tes3.removeItem{ reference = tes3.player, item = lanternItem, playSound = false}
        logger:debug("Registering tent with %s as a reference", lanternItem)
    else
        logger:error("%s does not have an ATTACH_LANTERN node.", tentRef.object.id)
    end
end

function this.removeLantern(tentRef)
    local attachLanternNode = getAttachLanternNode(tentRef.sceneNode)
    if attachLanternNode and tentRef.data.lantern then
        turnLanternOff(tentRef)
        logger:debug("found trinket node for %s", tentRef.object.id)
        if #attachLanternNode.children > 0 then
            attachLanternNode:detachChildAt(1)
            attachLanternNode:update()
            attachLanternNode:updateNodeEffects()
            local lantern = tentRef.data.lantern
            tes3.addItem{ reference = tes3.player, item =lantern.id, playSound = false }
            if tentRef.data.lantern.data then
                local itemData = tes3.addItemData{
                    to = tes3.player,
                    item = lantern.id,
                    updateGUI = true
                }
                if itemData then
                    itemData.data = tentRef.data.lantern.data.data
                    itemData.timeLeft = tentRef.data.lantern.data.timeLeft
                end
            end
            tentRef.data.lantern = nil
        else
            logger:error("%s has no lantern to remove.", tentRef.object.id)
        end
    end
end


local function onRefSceneNodeCreatedAddTrinkets(e)
    local lanternId = e.reference
                and e.reference.data
                and e.reference.data.lantern
                and e.reference.data.lantern.id
    if lanternId and this.canHaveLantern(e.reference) then
        local lantern = tes3.getObject(lanternId)
        if lantern then
            attachLightToRef(e.reference, lantern)
        end
    end
end
event.register("referenceSceneNodeCreated", onRefSceneNodeCreatedAddTrinkets)

return this