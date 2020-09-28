local common = require ("mer.ashfall.common.common")

--[[
    Mapping of campfire states to switch node states.
]]
local switchNodeValues = {
    SWITCH_BASE = function(campfire)
        local state = { OFF = 0, LIT = 1, UNLIT = 2 }
        return campfire.data.isLit and state.LIT or state.UNLIT
    end,
    SWITCH_FIRE = function(campfire)
        local state = { OFF = 0, LIT = 1, UNLIT = 2 }
        return campfire.data.isLit and state.LIT or state.UNLIT
    end,
    SWITCH_WOOD = function(campfire)
        local state = { OFF = 0, UNBURNED = 1, BURNED = 2 }
        return campfire.data.burned and state.BURNED or state.UNBURNED
    end,
    SWITCH_SUPPORTS = function(campfire)
        local state = { OFF = 0, ON = 1 }  
        return campfire.data.hasSupports and state.ON or state.OFF
    end,
    SWITCH_GRILL = function(campfire)
        local state = { OFF = 0, ON = 1 }  
        return campfire.data.hasGrill and state.ON or state.OFF
    end,
    SWITCH_COOKING_POT = function(campfire)
        local state = { OFF = 0, ON = 1 }
        return campfire.data.utensil == "cookingPot" and state.ON or state.OFF
    end,
    SWITCH_KETTLE = function(campfire)
        local state = { OFF = 0, ON = 1 }  
        return campfire.data.utensil == "kettle" and state.ON or state.OFF
    end,
    SWITCH_POT_STEAM = function(campfire)
        local state = { OFF = 0, ON = 1 } 
        local showSteam = ( 
            campfire.data.utensil == "cookingPot" and 
            campfire.data.waterHeat and
            campfire.data.waterHeat >= common.staticConfigs.hotWaterHeatValue
        )
        return showSteam and state.ON or state.OFF
    end,
    SWITCH_KETTLE_STEAM = function(campfire)
        local state = { OFF = 0, ON = 1 } 
        local showSteam = ( 
            campfire.data.utensil == "kettle" and 
            campfire.data.waterHeat and
            campfire.data.waterHeat >= common.staticConfigs.hotWaterHeatValue
        )
        return showSteam and state.ON or state.OFF
    end,
    SWITCH_STEW = function(campfire)
        local state = { OFF = 0, WATER = 1, STEW = 2}
        if campfire.data.utensil ~= "cookingPot" then return state.OFF end
        return campfire.data.stewLevels and state.STEW or state.WATER
    end
}


--Iterate over switch nodes and update them based on the current state of the campfire
local function updateSwitchNodes(campfire)
    local sceneNode = campfire.sceneNode
    local switchNode

    if campfire.data.destroyed then
        for nodeName, _ in pairs(switchNodeValues) do
            switchNode = sceneNode:getObjectByName(nodeName)
            if switchNode then
                switchNode.switchIndex = 0
            end
        end
    else
        for nodeName, getIndex in pairs(switchNodeValues) do
            switchNode = sceneNode:getObjectByName(nodeName)
            if switchNode then
                switchNode.switchIndex = getIndex(campfire)
            end
        end
    end
end

--As fuel levels change, update the radius of light given off by the campfire
local function updateLightingRadius(campfire)
    if campfire.light then
        local radius = campfire.object.radius
        if not campfire.data.isLit then
            campfire.light:setAttenuationForRadius(0)
        else
            local newRadius = math.clamp( ( campfire.data.fuelLevel / 10 ), 0.1, 1) * radius
            campfire.light:setAttenuationForRadius(newRadius)
        end
    end
end


--As fuel levels change, update the size of the flame
local function updateFireScale(campfire)
    local multiplier = 1 + ( campfire.data.fuelLevel * 0.05 )
    multiplier = math.clamp( multiplier, 0.5, 1.5)
    local fireNode = campfire.sceneNode:getObjectByName("FIRE_PARTICLE_NODE")
    fireNode.scale = multiplier
end

--Update the water level of the cooking pot
local function updateWaterHeight(campfire)
    local scaleMax = 1.3
    local heightMax = 28
    local waterLevel = campfire.data.waterAmount or 0
    local scale = math.min(math.remap(waterLevel, 0, common.staticConfigs.capacities.cookingPot, 1, scaleMax), scaleMax )
    local height = math.min(math.remap(waterLevel, 0, common.staticConfigs.capacities.cookingPot, 0, heightMax), heightMax)

    local waterNode = campfire.sceneNode:getObjectByName("POT_WATER")
    waterNode.translation.z = height
    waterNode.scale = scale
    local stewnode = campfire.sceneNode:getObjectByName("POT_STEW")
    stewnode.translation.z = height
    stewnode.scale = scale
end

--Update the size of the steam coming off a cooking pot
local function updateSteamScale(campfire)
    local hasSteam = ( 
        campfire.data.utensil == "cookingPot" and 
        campfire.data.waterHeat and
        campfire.data.waterHeat >= common.staticConfigs.hotWaterHeatValue
    
    )
    if hasSteam then
        local steamScale = math.min(math.remap(campfire.data.waterHeat, common.staticConfigs.hotWaterHeatValue
    , 100, 0.5, 1.0), 1.0)
        local steamNode = campfire.sceneNode:getObjectByName("POT_STEAM")
        if steamNode then steamNode = steamNode.children[1] end
        steamNode.scale = steamScale
    end
end

--Update the collision box of the campfire
local function updateCollision(campfire)
    local collisionNode = campfire.sceneNode:getObjectByName("COLLISION_SUPPORTS")
    if collisionNode then
        if campfire.data.hasSupports then
            collisionNode.scale = 1.0
        else
            collisionNode.scale = 0.0
        end
    end

    if campfire.data.destroyed then     
        --Remove collision node
        local collisionNode = campfire.sceneNode:getObjectByName("COLLISION")
        if collisionNode then
            collisionNode.scale = 0
        end
    end
end


local function updateVisuals(e)
    common.helper.iterateRefType("campfire", function(campfire)
        e.all = e.all ~= nil and e.all or true
        if e.all or e.nodes then
            updateSwitchNodes(campfire)
        end
        if e.all or e.lighting then
            updateLightingRadius(campfire)
        end
        if e.all or e.fire then
            updateFireScale(campfire)
        end
        if e.all or e.water then
            updateWaterHeight(campfire)
        end
        if e.all or e.steam then
            updateSteamScale(campfire)
        end
        if e.all or e.collision then
            updateCollision(campfire)
        end
        campfire:updateSceneGraph()
    end)
end

event.register("simulate", updateVisuals)