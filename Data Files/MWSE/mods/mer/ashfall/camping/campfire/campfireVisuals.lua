local common = require ("mer.ashfall.common.common")
local patinaController = require("mer.ashfall.camping.patinaController")
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
    SWITCH_LADLE = function(campfire)
        local state = { OFF = 0, ON = 1 }
        return campfire.data.ladle == true and state.ON or state.OFF
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
        local radius = 500 --get this from string data when it ain't fucked
        if not campfire.data.isLit then
            campfire.light:setAttenuationForRadius(0)
        else
            local fuelLevel = campfire.data.fuelLevel or 1
            local newRadius = math.clamp( ( fuelLevel / 10 ), 0.1, 1) * radius
            campfire.light:setAttenuationForRadius(newRadius)
        end
    end
end

--As fuel levels change, update the size of the flame
local function updateFireScale(campfire)
    local fireNode = campfire.sceneNode:getObjectByName("FIRE_PARTICLE_NODE")
    if fireNode then
        local fuelLevel = campfire.data.fuelLevel or 1
        local multiplier = 1 + ( fuelLevel * 0.05 )
        multiplier = math.clamp( multiplier, 0.5, 1.5)
        fireNode.scale = multiplier
    end
end

local function getUtensilData(campfire)
    local utensilId = campfire.data.utensilId
    local utensilData = common.staticConfigs.utensils[utensilId]
    return utensilData
end

--Update the water level of the cooking pot
local function updateWaterHeight(campfire)
    if not campfire.data.waterCapacity then return end
    local utensilData = getUtensilData(campfire)
    if not utensilData then return end
    
    local waterMaxScale = utensilData.waterMaxScale or 1.0
    local waterMaxHeight = utensilData.waterMaxHeight or 20
    local minSteamHeight = utensilData.minSteamHeight or (waterMaxHeight/2)
    local waterLevel = campfire.data.waterAmount or 0
    local scale = math.min(math.remap(waterLevel, 0, campfire.data.waterCapacity, 1, waterMaxScale), waterMaxScale )
    local height = math.min(math.remap(waterLevel, 0, campfire.data.waterCapacity, 0, waterMaxHeight), waterMaxHeight)

    local waterNode = campfire.sceneNode:getObjectByName("POT_WATER")
    if waterNode then
        waterNode.translation.z = height
        waterNode.scale = scale
    end
    local stewNode = campfire.sceneNode:getObjectByName("POT_STEW")
    if stewNode then
        stewNode.translation.z = height
        stewNode.scale = scale
    end
    local steamNode = campfire.sceneNode:getObjectByName("POT_STEAM") 
    if steamNode then
        steamNode.translation.z = math.max(height, minSteamHeight)
    end
end

--Update the size of the steam coming off a cooking pot
local function updateSteamScale(campfire)
    -- local hasSteam = ( 
    --     campfire.data.utensil == "cookingPot" and 
    --     campfire.data.waterHeat and
    --     campfire.data.waterHeat >= common.staticConfigs.hotWaterHeatValue
    -- )
    -- if hasSteam then
    --     local steamScale = math.min(math.remap(campfire.data.waterHeat, common.staticConfigs.hotWaterHeatValue
    -- , 100, 0.5, 1.0), 1.0)
    --     local steamNode = campfire.sceneNode:getObjectByName("POT_STEAM")
    --     if steamNode then steamNode = steamNode.children[1] end
    --     steamNode.scale = steamScale

        -- local potSteam = campfire.sceneNode:getObjectByName("POT_STEAM") 
        -- if potSteam then
        --     local steamScale = math.min(math.remap(campfire.data.waterHeat, common.staticConfigs.hotWaterHeatValue, 100, 0.1, 1.0), 1.0)
        --     local materialProperty = potSteam:getObjectByName("SuperSpray"):getProperty(0x2)
        --     materialProperty.alpha = steamScale
        -- end
    -- end
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
    local collisionSupportsNode = campfire.sceneNode:getObjectByName("COLLISION")
    if collisionSupportsNode then
        if campfire.data.destroyed then     
            --Remove collision node
                collisionSupportsNode.scale = 0
        else
            collisionSupportsNode.scale = 1.0
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


local idToNameMappings = {
    kettle = "Kettle",
    cookingPot = "Cooking Pot",
    grill = "Grill"
}


local function moveOriginToAttachPoint(node)
    local attachPoint = node:getObjectByName("ATTACH_POINT")
    if attachPoint then
        common.log:trace("Found attach point located at %s", attachPoint.translation)
        node.translation.x = node.translation.x - attachPoint.translation.x
        node.translation.y = node.translation.y - attachPoint.translation.y
        node.translation.z = node.translation.z - attachPoint.translation.z
    end
end

local function updateAttachNodes(e)
    common.log:trace("Ashfall:UpdateAttachNodes")
    local campfire = e.campfire
    local sceneNode = campfire.sceneNode
    local hangNode = sceneNode:getObjectByName("HANG_UTENSIL")
    --Hanging utensils
    if hangNode then


        local utensilID = campfire.data.utensilId
        common.log:trace("has hangNode")
        common.log:trace("children: %s", #hangNode.children)
        if campfire.data.utensil and utensilID then
            local name = idToNameMappings[campfire.data.utensil]
            if not name then 
                common.log:error("No valid utensil type set on data.utensil")
                return 
            end
            common.log:trace("Has utensil")
            local utensilObj = tes3.getObject(utensilID)
            if utensilObj then
                if #hangNode.children > 0 then
                    hangNode:detachChildAt(1)
                end
                
                common.log:trace("utensil is a valid object")
                local utensilData = common.staticConfigs.utensils[utensilID:lower()]
                if not utensilData then
                    common.log:error("%s is not a valid utensil, but was set to campfire.data.utensilId")
                end
                local meshId = utensilData and utensilData.meshOverride or utensilObj.mesh
                local mesh = common.loadMesh(meshId)
                mesh.name = name
                moveOriginToAttachPoint(mesh)
                hangNode:attachChild(mesh)


                common.log:trace("Attached %s to campfire", utensilID)
            end
        else
            for i, childNode in ipairs(hangNode.children) do
                if childNode then
                    common.log:trace("removed utensil node")
                    hangNode:detachChildAt(i)
                end
            end
        end

        local patinaAmount = campfire.data.utensilPatinaAmount
        common.log:debug("hangNode updateAttachNodes add patina amount: %s", patinaAmount)
        patinaController.addPatina(hangNode, patinaAmount)
    end
    local grillNode = sceneNode:getObjectByName("ATTACH_GRILL")
    local attachStand
    if grillNode then
        local grillId = campfire.data.grillId
        if grillId then
            local name = idToNameMappings["grill"]
            local grillObj = tes3.getObject(grillId)
            if grillObj then
                if #grillNode.children > 0 then
                    grillNode:detachChildAt(1)
                end
                
                local data = common.staticConfigs.grills[grillId:lower()]
                if not data then
                    common.log:error("%s is not a valid grill, but was set to campfire.data.grillId")
                end
                local meshId = data and data.meshOverride or grillObj.mesh
                local mesh = common.loadMesh(meshId)
                mesh.name = name
                grillNode:attachChild(mesh)

                --If the override mesh has an ATTACH_STAND node, then attach the original mesh to it
                attachStand = mesh:getObjectByName("ATTACH_STAND")
                if attachStand then
                    common.log:debug("Found ATTACH_STAND node")
                    local origMesh = common.loadMesh(grillObj.mesh)
                    attachStand:attachChild(origMesh)
                end

                common.log:trace("Attached %s to campfire", grillId)
            end
        else
            for i, childNode in ipairs(grillNode.children) do
                if childNode then
                    common.log:trace("removed utensil node")
                    grillNode:detachChildAt(i)
                end
            end
        end

        local patinaAmount = campfire.data.grillPatinaAmount
        common.log:debug("grillNode updateAttachNodes add patina amount: %s", patinaAmount)
        patinaController.addPatina((attachStand or grillNode), patinaAmount)

    end




    campfire.sceneNode:update()
    campfire.sceneNode:updateNodeEffects()
end
event.register("Ashfall:UpdateAttachNodes", updateAttachNodes)

local function initialiseAttachNodes()
    common.helper.iterateRefType("campfire", function(campfire)
        updateAttachNodes{ campfire = campfire }
    end)
end
event.register("cellChanged", initialiseAttachNodes)
event.register("loaded", initialiseAttachNodes)
