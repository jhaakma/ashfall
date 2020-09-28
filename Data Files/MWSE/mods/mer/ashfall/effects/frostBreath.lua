
--[[
    Add frosty breath to player/NPCs when it's freezing cold outside
--]]

local common = require("mer.ashfall.common.common")
local this = {}

local coldLevelNeeded = common.staticConfigs.conditionConfig.temp.states.veryCold.max

local function checkEnabled()
    return common.config.getConfig().showFrostBreath
end

local function addBreath(node, x, y, z, scale)
    scale = scale or 1.0
    if not node:getObjectByName("smokepuffs.nif") then
        local smokepuffs = tes3.loadMesh("ashfall\\smokepuffs.nif"):clone()
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


function this.doFrostBreath()

    local temp = common.data.weatherTemp
    local isCold = temp < coldLevelNeeded

    local function addRemoveBreath(ref, isGuar)

        if ( ref.mobile and ref.sceneNode ) then
            local node 
            if isGuar then
                node = ref.sceneNode:getObjectByName("Bip01 Ponytail12")
            else
                node = ref.sceneNode:getObjectByName("Bip01 Head")
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

    for _,cell in pairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences(tes3.objectType.npc) do
            addRemoveBreath(ref)
        end
        for ref in cell:iterateReferences(tes3.objectType.creature) do
            if ref.baseObject.id == "mer_tgw_guar" or  ref.baseObject.id == "mer_tgw_guar_w" then
                addRemoveBreath(ref, true)
            end
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


