
--[[
    Add frosty breath to player/NPCs when it's freezing cold outside
--]]

local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config").config
local this = {}

local coldLevelNeeded = common.staticConfigs.conditionConfig.temp.states.veryCold.max

local function checkEnabled()
    return config.showFrostBreath
end

local function addBreath(node, x, y, z, scale)
    scale = scale or 1.0
    if not node:getObjectByName("smokepuffs.nif") then
        local smokepuffs = common.helper.loadMesh("ashfall\\smokepuffs.nif")
        node:attachChild(smokepuffs, true)
        smokepuffs.translation.x = x
        smokepuffs.translation.y = y
        smokepuffs.translation.z = z
        smokepuffs.scale = smokepuffs.scale * scale
        smokepuffs.rotation = node.worldTransform.rotation:invert()
    end
end

local function removeBreath(node)
    if node:getObjectByName("smokepuffs.nif") then
        node:detachChild(node:getObjectByName("smokepuffs.nif"), true)
    end
end

---@param ref tes3reference
---@param isCold boolean
---@param isGuar? boolean
local function addRemoveBreath(ref, isCold, isGuar)
    local valid = ref
        and ref.mobile
        and ref.sceneNode
        and not ref.disabled

    if valid then
        local node
        if isGuar then
            node = ref.sceneNode:getObjectByName("Bip01 Ponytail12")
        else
            node = ref.sceneNode:getObjectByName("Bip01 Head")
        end
        if not node then
            return
        end
        local isAlive = ( ref.mobile.health.current > 0 )
        local isAboveWater = ( ref.mobile.underwater == false )
        if isCold and isAboveWater and isAlive and checkEnabled() then
            if isGuar then
                addBreath(node, 25, 0, 0, 2.0)
            else
                addBreath(node, 0, 11, 0)
            end
        else
            removeBreath(node)
        end
    end
end

function this.doFrostBreath()

    local temp = common.data.weatherTemp
    local isCold = temp < coldLevelNeeded

    local actors = tes3.findActorsInProximity{ reference = tes3.player, range = 8192 }
    for _, actor in ipairs(actors) do
        if actor.actorType == tes3.actorType.npc then
            addRemoveBreath(actor.reference, isCold)
        elseif actor.actorType == tes3.actorType.creature  and actor.reference.supportsLuaData and actor.reference.data.tgw then
            addRemoveBreath(actor.reference, isCold, true)
        end
    end

    local node = tes3.player.sceneNode and tes3.player.sceneNode:getObjectByName("Bip01 Head")
    if node then
        if isCold and tes3.mobilePlayer.underwater == false and checkEnabled() then
            addBreath(node, 0, 11, 0)
        else
            removeBreath(node)
        end
    end

    node = tes3.worldController.worldCamera.cameraRoot
    if node then
        local isAboveWater = ( tes3.mobilePlayer.underwater == false )
        if isCold and not tes3.is3rdPerson() and isAboveWater and checkEnabled() then
            addBreath(node, 0, 5, -16)
        else
            removeBreath(node)
        end
    end
end
return this


