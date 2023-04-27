local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("campfireVisuals")
local patinaController = require("mer.ashfall.camping.patinaController")
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")
local ReferenceController = require("mer.ashfall.referenceController")
local WoodStack = require("mer.ashfall.items.woodStack")

--[[
    Mapping of campfire states to switch node states.
]]
local switchNodeValues = {
    SWITCH_WOODSTACK = function(reference)
        local amount = WoodStack.getWoodAmount(reference)
        local max = WoodStack.getCapacity(reference.object.id )
        local switchNode = reference.sceneNode:getObjectByName("SWITCH_WOODSTACK")
        local on = switchNode:getObjectByName("ON")
        local off = switchNode:getObjectByName("OFF")

        local maxNodes = 0
        for _, node in pairs(on.children) do
            if node then
                maxNodes = maxNodes + 1
            end
        end
        for _, node in pairs(off.children) do
            if node then
                maxNodes = maxNodes + 1
            end
        end
        logger:debug("maxNodes: %s", maxNodes)
        local activeNodeNum = math.ceil(maxNodes * amount / max)
        logger:debug("activeNodeNum: %s", activeNodeNum)
        --Move active wood to ON node
        for i=1,activeNodeNum,1 do
            local wood = off:getObjectByName(tostring(i))
            if wood then
                logger:debug("Enabling %s", i)
                off:detachChild(wood)
                on:attachChild(wood)
            end
        end
        --Move inactive wood to OFF node
        for i=activeNodeNum+1,maxNodes,1 do
            local wood = on:getObjectByName(tostring(i))
            if wood then
                logger:debug("Disabling %s", i)
                on:detachChild(wood)
                off:attachChild(wood)
            end
        end
        return "ON"
    end,
    SWITCH_BASE = function(reference)
        local isCold = reference.data.hasColdFlame
        local isLit = reference.data.isLit
        if not isLit then
            return "UNLIT"
        else
            return isCold and "COLD" or "LIT"
        end
    end,
    SWITCH_FIRE = function(reference)
        local isLit = reference.data.isLit
        local isCold = reference.data.hasColdFlame
        if not isLit then
            return "UNLIT"
        else
            return isCold and "COLD" or "LIT"
        end
    end,
    SWITCH_CANDLELIGHT = function(reference)
        return reference.data.isLit and "LIT" or "UNLIT"
    end,
    SWITCH_WOOD = function(reference)
        local hasFuel = reference.data.fuelLevel and reference.data.fuelLevel ~= 0
        local isLit = reference.data.isLit
        local isBurned = reference.data.burned

        --stage one: no wood
        if (not hasFuel) and (not isBurned) then
            return "OFF"
        end
        --stage two: wood added
        if (hasFuel) and (not isLit) and (not isBurned) then
            return "UNBURNED"
        end
        --stage three: wood added and lit
        if (hasFuel) and (isLit) then
            return reference.sceneNode:getObjectByName("WOODLIT") and "WOODLIT" or "BURNED"
        end
        --stage hour: wood added and burnt
        if (hasFuel) and (not isLit) and (isBurned) then
            return "BURNED"
        end
    end,
    SWITCH_SUPPORTS = function(reference)

        return reference.data.supportsId and "ON" or "OFF"
    end,
    SWITCH_GRILL = function(reference)
        return reference.data.hasGrill and "ON" or "OFF"
    end,
    SWITCH_COOKING_POT = function(reference)
        return reference.data.utensil == "cookingPot" and "ON" or "OFF"
    end,
    SWITCH_LADLE = function(reference)
        return reference.data.ladle == true and "ON" or "OFF"
    end,
    SWITCH_KETTLE = function(reference)
        return reference.data.utensil == "kettle" and "ON" or "OFF"
    end,
    SWITCH_POT_STEAM = function(reference)
        if reference.data.utensil and reference.data.utensil ~= "cookingPot" then return "OFF" end
        local showSteam = (
            reference.data.waterHeat and
            reference.data.waterHeat >= common.staticConfigs.hotWaterHeatValue
        )
        return showSteam and "ON" or "OFF"
    end,
    SWITCH_KETTLE_STEAM = function(reference)
        if reference.data.utensil and reference.data.utensil ~= "kettle" then return "OFF" end
        local showSteam = (
            reference.data.waterHeat and
            reference.data.waterHeat >= common.staticConfigs.hotWaterHeatValue
        )
        return showSteam and "ON" or "OFF"
    end,
    SWITCH_STEW = function(reference)
        if reference.data.utensil and reference.data.utensil ~= "cookingPot" then return "OFF" end
        return reference.data.stewLevels and "STEW" or "WATER"
    end,
    SWITCH_TEA = function(reference)
        logger:trace("Found tea switch")
        local hasTea = reference.data.waterType ~= nil
            and reference.data.waterType ~= "dirty"
        local thisState = hasTea and "TEA" or "WATER"
        logger:trace("Tea switch state: " .. thisState)
        return thisState
    end,
    SWITCH_WATER_FILTER = function(reference)
        local unfilteredWater = reference.data.unfilteredWater or 0
        local filteredWater = reference.data.waterAmount or 0
        local capacity = common.staticConfigs.bottleList.ashfall_water_filter.capacity
        local isDripping = filteredWater < capacity
            and unfilteredWater > 0
        return isDripping and "DRIPPING" or "OFF"
    end
}

local supportMapping = {
    supports_01 = {
        path = "ashfall/cf/Supports_01.nif",
    },
    supports_02 = {
        path = "ashfall/cf/Supports_02.nif",
    },
    supports_03 = {
        path = "ashfall/cf/Supports_03.nif",
    }
}

local function getChildIndexByName(collection, name)
	for i, child in ipairs(collection) do
		if (name and child and child.name and child.name:lower() == name:lower()) then
			return i - 1
		end
	end
end

--Iterate over switch nodes and update them based on the current state of the campfire
local function updateSwitchNodes(reference)
    local sceneNode = reference.sceneNode
    local switchNode
    if reference.data and reference.data.destroyed then
        for nodeName, _ in pairs(switchNodeValues) do
            switchNode = sceneNode:getObjectByName(nodeName)
            if switchNode then
                local offIndex = getChildIndexByName(switchNode.children, "OFF")
                switchNode.switchIndex = offIndex or 0
            end
        end
    else
        for nodeName, childNameCallback in pairs(switchNodeValues) do
            switchNode = sceneNode:getObjectByName(nodeName)
            if switchNode then
                local childName = childNameCallback(reference)
                local childIndex = getChildIndexByName(switchNode.children, childName)
                switchNode.switchIndex = childIndex or 0
            end
        end
    end
end

--As fuel levels change, update the radius of light given off by the campfire
local function updateLightingRadius(reference)
    if reference.light then
        local radius = 500 --get this from string data when it ain't fucked
        if not reference.data.isLit then
            reference.light:setAttenuationForRadius(0)
        else
            local heatLevel = math.abs(CampfireUtil.getHeat(reference))
            local newRadius = math.clamp( ( heatLevel / 10 ), 0.1, 1) * radius
            reference.light:setAttenuationForRadius(newRadius)
        end
    end
end

--As fuel levels change, update the size of the flame
local function updateFireScale(reference)
    local fireNodes = {
        reference.sceneNode:getObjectByName("FIRE_PARTICLE_NODE"),
        reference.sceneNode:getObjectByName("COLD_PARTICLE_NODE"),
    }
    for _, fireNode in ipairs(fireNodes) do
        local fuelLevel = math.abs(CampfireUtil.getHeat(reference))
        local newScale = math.remap(fuelLevel, 0, 15, 1, 2)
        newScale = math.clamp(newScale, 1, 2)
        fireNode.scale = newScale
    end
end


--Update the water level of the cooking pot
local function updateWaterHeight(reference)
    local utensilData = CampfireUtil.getUtensilData(reference)
    if not utensilData then
        return
    end
    local capacity = utensilData.capacity

    local waterMaxScale = utensilData.waterMaxScale or 1.0
    local waterMaxHeight = utensilData.waterMaxHeight or 20
    local minSteamHeight = utensilData.minSteamHeight or (waterMaxHeight/2)
    local waterLevel = reference.data.waterAmount or 0
    local scale = math.min(math.remap(waterLevel, 0, capacity, 1, waterMaxScale), waterMaxScale )
    local height = math.min(math.remap(waterLevel, 0, capacity, 0, waterMaxHeight), waterMaxHeight)

    local waterNode = reference.sceneNode:getObjectByName("POT_WATER")
    if waterNode then
        logger:debug("Found Water Node! Setting height to %s and scale to %s", height, scale)
        waterNode.translation.z = height
        waterNode.scale = scale
    end
    local stewNode = reference.sceneNode:getObjectByName("POT_STEW")
    if stewNode then
        stewNode.translation.z = height
        stewNode.scale = scale
    end
    local teaNode = reference.sceneNode:getObjectByName("POT_TEA")
    if teaNode then
        logger:trace("Found Tea Node! Setting height to %s and scale to %s", height, scale)
        teaNode.translation.z = height
        teaNode.scale = scale
    end
    local steamNode = reference.sceneNode:getObjectByName("POT_STEAM")
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
    local collisionSupportsNode = campfire.sceneNode:getObjectByName("COLLISION_SUPPORTS")
    if collisionSupportsNode then
        if campfire.data.supportsId then
            collisionSupportsNode.scale = 1.0
        else
            collisionSupportsNode.scale = 0.0
        end
    end
    local collisionNode = campfire.sceneNode:getObjectByName("COLLISION")
    if collisionNode then
        if campfire.data.destroyed then
            --Remove collision node
                collisionNode.scale = 0
        else
            collisionNode.scale = 1.0
        end
    end
end

local function updateSounds(campfire)
    if not campfire.data then return end
    local hasWater = campfire.data.waterAmount and campfire.data.waterAmount > 0
    local hasBoilingHeat = campfire.data.waterHeat and campfire.data.waterHeat >= common.staticConfigs.hotWaterHeatValue
    local utensilOrCampfire = campfire.data.utensil or common.staticConfigs.utensils[campfire.object.id:lower()]
    if hasWater and hasBoilingHeat and utensilOrCampfire then
        tes3.removeSound{
            reference = campfire,
            sound = "ashfall_boil"
        }
        tes3.playSound{
            reference = campfire,
            sound = "ashfall_boil",
            loop = true
        }
    else
        logger:trace("campfireVisuals: removing boil sound")
        tes3.removeSound{
            reference = campfire,
            sound = "ashfall_boil"
        }
    end
end

local function updateCampfireVisuals(campfire)
    updateSwitchNodes(campfire)
    updateLightingRadius(campfire)
    updateFireScale(campfire)
    updateWaterHeight(campfire)
    updateSteamScale(campfire)
    updateCollision(campfire)
    campfire:updateSceneGraph()
    campfire.sceneNode:update()
    campfire.sceneNode:updateNodeEffects()
end
local function updateVisuals(e)
    ReferenceController.iterateReferences("fuelConsumer", function(campfire)
        updateLightingRadius(campfire)
        updateFireScale(campfire)
    end)
end
event.register("simulate", updateVisuals)

---@param node niNode
local function moveOriginToAttachPoint(node)
    local attachPoint = node:getObjectByName("ATTACH_POINT")
    if attachPoint then
        logger:trace("Found attach point located at %s", attachPoint.translation)
        node.rotation = attachPoint.rotation:copy()
        node.translation.x = node.translation.x - attachPoint.translation.x
        node.translation.y = node.translation.y - attachPoint.translation.y
        node.translation.z = node.translation.z - attachPoint.translation.z
        node.scale = node.scale * attachPoint.scale
    end
end

--Note: these must be ordered correctly, for example, cooking pot comes before ladle
local attachNodes = {
    {
        attachNodeName = "ATTACH_FLAME",
        getDoAttach = function(campfire)
            return campfire.data.isLit == true
        end,
        getAttachMesh = function(campfire)
            --TODO - different flame colors?
            return common.helper.loadMesh("ashfall\\cf\\flame_01.nif")
        end,
    },
    {
        attachNodeName = "ATTACH_FIREWOOD",
        getDoAttach = function(campfire)
            return not not campfire.data.fuelLevel
        end,
        getAttachMesh = function(campfire)
            local firewoodMesh
            --Vanilla replaced campfires get logs of wood, player made get branches
            --TODO - do this properly
            if campfire.data.staticCampfireInitialised then
                firewoodMesh = "ashfall\\cf\\Firewood_02.nif"
            else
                firewoodMesh = "ashfall\\cf\\Firewood_01.nif"
            end
            return common.helper.loadMesh(firewoodMesh)
        end
    },
    {
        attachNodeName = "ATTACH_SUPPORTS",
        getDoAttach = function(campfire)
            return not not campfire.data.supportsId
        end,
        getAttachMesh = function(campfire)
            local supportsItem = tes3.getObject(campfire.data.supportsId)
            if supportsItem then
                local mesh = common.helper.loadMesh(supportsItem.mesh)
                mesh.appCulled = false
                return mesh
            end
        end
    },
    {
        attachNodeName = "HANG_UTENSIL",
        getDoAttach = function(campfire)
            return (not not campfire.data.utensil)
            and (not not campfire.data.utensilId)
        end,
        getAttachMesh = function(campfire)
            local utensilID = campfire.data.utensilId
            local utensilObj = tes3.getObject(utensilID)
            if utensilObj then
                logger:trace("utensil is a valid object")
                local utensilData = common.staticConfigs.utensils[utensilID:lower()]
                if not utensilData then
                    logger:error("%s is not a valid utensil, but was set to campfire.data.utensilId", utensilID)
                end
                local meshId = utensilData and utensilData.meshOverride or utensilObj.mesh
                local mesh = common.helper.loadMesh(meshId)
                local idToNameMappings = {
                    kettle = "KETTLE",
                    cookingPot = "COOKING_POT",
                }
                moveOriginToAttachPoint(mesh)
                mesh.name = idToNameMappings[campfire.data.utensil]
                return mesh
            end
        end,
        postAttach = function(campfire, attachNode)
            local patinaAmount = campfire.data.utensilPatinaAmount
            logger:trace("hangNode updateAttachNodes add patina amount: %s", patinaAmount)
            patinaController.addPatina(attachNode, patinaAmount)
        end
    },
    {
        attachNodeName = "ATTACH_GRILL",
        getDoAttach = function (campfire)
            return not not campfire.data.grillId
        end,
        getAttachMesh = function(campfire)
            local grillId = campfire.data.grillId
            local grillObj = tes3.getObject(grillId)
            if grillObj then
                local data = common.staticConfigs.grills[grillId:lower()]
                if not data then
                    logger:error("%s is not a valid grill, but was set to campfire.data.grillId")
                end
                local meshId = data and data.meshOverride or grillObj.mesh
                local mesh = common.helper.loadMesh(meshId)
                mesh.name = "Grill"
                return mesh
            end
        end,
    },
    --Comes after attach_grill because the grill gets attached to this after the stand was placed
    {
        attachNodeName = "ATTACH_STAND",
        getDoAttach = function(campfire)
            return not not campfire.data.grillId
        end,
        getAttachMesh = function(campfire)
            local grillId = campfire.data.grillId
            if grillId then
                local grillObj = tes3.getObject(grillId)
                if grillObj then
                    local mesh = common.helper.loadMesh(grillObj.mesh)
                    moveOriginToAttachPoint(mesh)
                    return mesh
                end
            end
        end,
        postAttach = function(campfire, attachNode)
            local patinaAmount = campfire.data.grillPatinaAmount
            logger:trace("grillNode updateAttachNodes add patina amount: %s", patinaAmount)
            patinaController.addPatina(attachNode, patinaAmount)
        end
    },
    {
        attachNodeName = "ATTACH_BELLOWS",
        getDoAttach = function(campfire)
            return not not campfire.data.bellowsId
        end,
        getAttachMesh = function(campfire)
            local bellowsId = campfire.data.bellowsId
            if bellowsId then
                local bellowsMesh = tes3.getObject(bellowsId)
                if bellowsMesh then
                    return common.helper.loadMesh(bellowsMesh.mesh)
                end
            end
        end,
    },
    {
        attachNodeName = "ATTACH_LADLE",
        getDoAttach = function(campfire)
            local hasLadle = not not campfire.data.ladle
            logger:trace("Has attach_ladle, has ladle? %s", hasLadle)
            return hasLadle
        end,
        getAttachMesh = function(campfire)
            local ladleObject = tes3.getObject(campfire.data.ladle)
            if ladleObject then
                local meshId = ladleObject.mesh
                local data = common.staticConfigs.ladles[ladleObject.id:lower()]
                if data and data.meshOverride then
                    meshId = data.meshOverride
                end
                logger:trace("mesh: %s", meshId)
                local mesh = common.helper.loadMesh(meshId)
                mesh.appCulled = false
                mesh.name = "Ladle"
                return mesh
            end
        end
    },
}

local function updateAttachNodes(e)
    logger:trace("Ashfall:UpdateAttachNodes: %s", e.reference.object.id)
    local reference = e.reference
    local sceneNode = reference.sceneNode

    if not reference.data then return end
    if not sceneNode then return end
    for _, attachData in ipairs(attachNodes) do
        logger:trace("++++ATTACH NODE: %s+++++++", attachData.attachNodeName)
        local attachNode = sceneNode:getObjectByName(attachData.attachNodeName)
        if attachNode then
            logger:trace("found attach node")
            --remove children
            for i, childNode in ipairs(attachNode.children) do
                if childNode then
                    logger:trace("removed %s children", attachData.attachNodeName)
                    attachNode:detachChildAt(i)
                end
            end
            if attachData.getDoAttach(reference) then
                logger:trace("Do attach: tru, getting mesh")
                local mesh = attachData.getAttachMesh(reference)
                if mesh then
                    mesh.appCulled = false
                    logger:trace("Mesh succeed, attaching %s", mesh)
                    attachNode:attachChild(mesh)
                else
                    logger:trace("Failed to retrieve mesh")
                end
            else
                logger:trace("Do attach: false, removing mesh")
            end
            if attachData.postAttach then
                local attachNode = sceneNode:getObjectByName(attachData.attachNodeName)
                if attachNode then
                    logger:trace("Running Post attach for %s", attachData.attachNodeName)
                    attachData.postAttach(reference, attachNode)
                end
            end
        end
    end

    updateSounds(reference)
    updateCampfireVisuals(reference)
end
event.register("Ashfall:UpdateAttachNodes", updateAttachNodes)


local attachNodeRefTypes = {
    "fuelConsumer",
    "waterContainer",
    "waterFilter",
    "woodStack",
}
local function initialiseAttachNodes()
    for _, refType in ipairs(attachNodeRefTypes) do
        ReferenceController.iterateReferences(refType, function(reference)
            updateAttachNodes{ reference = reference }
        end)
    end
end
event.register("cellChanged", initialiseAttachNodes)
event.register("loaded", initialiseAttachNodes)

event.register("referenceActivated", function(e)
    for _, refType in ipairs(attachNodeRefTypes) do
        if ReferenceController.controllers[refType]:isReference(e.reference) then
            updateAttachNodes{ reference = e.reference }
        end
    end
end)