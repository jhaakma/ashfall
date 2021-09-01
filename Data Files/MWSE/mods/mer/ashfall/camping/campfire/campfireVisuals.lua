local common = require ("mer.ashfall.common.common")
local patinaController = require("mer.ashfall.camping.patinaController")
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")
local referenceController = require("mer.ashfall.referenceController")
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
        return campfire.data.supportsId and state.ON or state.OFF
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
        if campfire.data.utensil and campfire.data.utensil ~= "cookingPot" then return state.OFF end
        local showSteam = (
            campfire.data.waterHeat and
            campfire.data.waterHeat >= common.staticConfigs.hotWaterHeatValue
        )
        return showSteam and state.ON or state.OFF
    end,
    SWITCH_KETTLE_STEAM = function(campfire)
        local state = { OFF = 0, ON = 1 }
        if campfire.data.utensil and campfire.data.utensil ~= "kettle" then return state.OFF end
        local showSteam = (
            campfire.data.waterHeat and
            campfire.data.waterHeat >= common.staticConfigs.hotWaterHeatValue
        )
        return showSteam and state.ON or state.OFF
    end,
    SWITCH_STEW = function(campfire)
        local state = { OFF = 0, WATER = 1, STEW = 2}
        if campfire.data.utensil and campfire.data.utensil ~= "cookingPot" then return state.OFF end
        return campfire.data.stewLevels and state.STEW or state.WATER
    end,
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

--Iterate over switch nodes and update them based on the current state of the campfire
local function updateSwitchNodes(campfire)
    local sceneNode = campfire.sceneNode
    local switchNode

    if campfire.data and campfire.data.destroyed then
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
                local index = getIndex(campfire)
                switchNode.switchIndex = index
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
            local heatLevel = CampfireUtil.getHeat(campfire.data)
            local newRadius = math.clamp( ( heatLevel / 10 ), 0.1, 1) * radius
            campfire.light:setAttenuationForRadius(newRadius)
        end
    end
end

--As fuel levels change, update the size of the flame
local function updateFireScale(campfire)
    local fireNode = campfire.sceneNode:getObjectByName("FIRE_PARTICLE_NODE")
    if fireNode then
        local fuelLevel = CampfireUtil.getHeat(campfire.data)
        local multiplier = 1 + ( fuelLevel * 0.05 )
        multiplier = math.clamp( multiplier, 0.5, 1.5)
        fireNode.scale = multiplier
    end
end


--Update the water level of the cooking pot
local function updateWaterHeight(ref)


    local utensilData = CampfireUtil.getUtensilData(ref)
    if not utensilData then return end

    local capacity = utensilData.capacity
    if not capacity then
        common.log:trace("Couldn't get capacity")
        return
    end

    local waterMaxScale = utensilData.waterMaxScale or 1.0
    local waterMaxHeight = utensilData.waterMaxHeight or 20
    local minSteamHeight = utensilData.minSteamHeight or (waterMaxHeight/2)
    local waterLevel = ref.data.waterAmount or 0
    local scale = math.min(math.remap(waterLevel, 0, capacity, 1, waterMaxScale), waterMaxScale )
    local height = math.min(math.remap(waterLevel, 0, capacity, 0, waterMaxHeight), waterMaxHeight)

    local waterNode = ref.sceneNode:getObjectByName("POT_WATER")
    if waterNode then
        waterNode.translation.z = height
        waterNode.scale = scale
    end
    local stewNode = ref.sceneNode:getObjectByName("POT_STEW")
    if stewNode then
        stewNode.translation.z = height
        stewNode.scale = scale
    end
    local steamNode = ref.sceneNode:getObjectByName("POT_STEAM")
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
    if campfire.data and campfire.data.waterHeat and campfire.data.waterHeat >= common.staticConfigs.hotWaterHeatValue then
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
        tes3.removeSound{
            reference = campfire,
            sound = "ashfall_boil"
        }
    end
end

local function updateCampfireVisuals(campfire)
    common.log:trace("updateCampfireVisuals: %s", campfire.object.id)
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
    common.helper.iterateRefType("campfire", updateCampfireVisuals)
end

event.register("simulate", updateVisuals)

---@param node niNode
local function moveOriginToAttachPoint(node)
    local attachPoint = node:getObjectByName("ATTACH_POINT")
    if attachPoint then
        common.log:trace("Found attach point located at %s", attachPoint.translation)
        node.rotation = attachPoint.rotation:copy()
        node.translation.x = node.translation.x - attachPoint.translation.x
        node.translation.y = node.translation.y - attachPoint.translation.y
        node.translation.z = node.translation.z - attachPoint.translation.z
    end
end

local attachNodes = {
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
            return common.loadMesh(firewoodMesh)
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
                local mesh = common.loadMesh(supportsItem.mesh)
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
                common.log:trace("utensil is a valid object")
                local utensilData = common.staticConfigs.utensils[utensilID:lower()]
                if not utensilData then
                    common.log:error("%s is not a valid utensil, but was set to campfire.data.utensilId", utensilID)
                end
                local meshId = utensilData and utensilData.meshOverride or utensilObj.mesh
                local mesh = common.loadMesh(meshId)
                local idToNameMappings = {
                    kettle = "Kettle",
                    cookingPot = "Cooking Pot",
                }
                moveOriginToAttachPoint(mesh)
                mesh.name = idToNameMappings[campfire.data.utensil]
                return mesh
            end
        end,
        postAttach = function(campfire, attachNode)
            local patinaAmount = campfire.data.utensilPatinaAmount
            common.log:trace("hangNode updateAttachNodes add patina amount: %s", patinaAmount)
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
                    common.log:error("%s is not a valid grill, but was set to campfire.data.grillId")
                end
                local meshId = data and data.meshOverride or grillObj.mesh
                local mesh = common.loadMesh(meshId)
                mesh.name = "Grill"
                return mesh
            end
        end,
    },
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
                    return common.loadMesh(grillObj.mesh)
                end
            end
        end,
        postAttach = function(campfire, attachNode)
            local patinaAmount = campfire.data.grillPatinaAmount
            common.log:trace("grillNode updateAttachNodes add patina amount: %s", patinaAmount)
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
                    return common.loadMesh(bellowsMesh.mesh)
                end
            end
        end,
    }
}

local function updateAttachNodes(e)
    common.log:trace("Ashfall:UpdateAttachNodes: %s", e.campfire.object.id)
    local campfire = e.campfire
    local sceneNode = campfire.sceneNode

    for _, attachData in ipairs(attachNodes) do
        common.log:trace("++++ATTACH NODE: %s+++++++", attachData.attachNodeName)
        local attachNode = sceneNode:getObjectByName(attachData.attachNodeName)
        if attachNode then
            common.log:trace("found attach node")
            --remove children
            for i, childNode in ipairs(attachNode.children) do
                if childNode then
                    common.log:trace("removed %s children", attachData.attachNodeName)
                    attachNode:detachChildAt(i)
                end
            end
            if attachData.getDoAttach(campfire) then
                common.log:trace("Do attach: tru, getting mesh")
                local mesh = attachData.getAttachMesh(campfire)
                if mesh then
                    common.log:trace("Mesh succeed, attaching")
                    attachNode:attachChild(mesh)
                else
                    common.log:trace("Failed to retrieve mesh")
                end
            else
                common.log:trace("Do attach: false, removing mesh")
            end
            if attachData.postAttach then
                local attachNode = sceneNode:getObjectByName(attachData.attachNodeName)
                if attachNode then
                    common.log:trace("Running Post attach for %s", attachData.attachNodeName)
                    attachData.postAttach(campfire, attachNode)
                end
            end
        end
    end

    updateSounds(campfire)
    updateCampfireVisuals(campfire)
end
event.register("Ashfall:UpdateAttachNodes", updateAttachNodes)

local function initialiseAttachNodes()
    common.helper.iterateRefType("campfire", function(campfire)
        updateAttachNodes{ campfire = campfire }
    end)
    common.helper.iterateRefType("boiler", function(campfire)
        updateAttachNodes{ campfire = campfire }
    end)
end
event.register("cellChanged", initialiseAttachNodes)
event.register("loaded", initialiseAttachNodes)

event.register("referenceSceneNodeCreated", function(e)
    if referenceController.controllers.utensil:requirements(e.reference) then
        updateAttachNodes{ campfire = e.reference }
    end
    if referenceController.controllers.kettle:requirements(e.reference) then
        updateAttachNodes{ campfire = e.reference }
    end
end)