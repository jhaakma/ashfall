local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local tentConfig = require("mer.ashfall.camping.tents.tentConfig")
local backpackSlot = 11
local backpacks = {
    --legacy armor packs
    ashfall_backpack_b = true,
    ashfall_backpack_w = true,
    ashfall_backpack_n = true,

    ashfall_pack_01 = true,
    ashfall_pack_02 = true,
    ashfall_pack_03 = true,
}


local switchNodes = {
    SWITCH_AXE = {
        items = { 
            ashfall_woodaxe = true,
            ashfall_woodaxe_steel = true,
        },
        blockEquip = true,
        attachMesh = true
    },
    SWITCH_WOOD = {
        items = {ashfall_firewood = true },
        attachMesh = true
    },
    SWITCH_TENT = {
        items = tentConfig.tentMiscToActiveMap,
        attachMesh = true
    }
}


local function registerBackpacks()
    pcall(function()
        tes3.addClothingSlot{slot=backpackSlot, name="Backpack"}
        --tes3.addArmorSlot{slot=backpackSlot, name="Backpack"}
    end)
    for id in pairs(backpacks) do
        local obj = tes3.getObject(id)
        -- remap slot to custom backpackSlot
        obj.slot = backpackSlot
        -- store the bodypart mesh for later
        backpacks[id] = obj.mesh:sub(1, -9) .. ".NIF"
        -- clear bodypart so it doesn't overwrite left pauldron
         obj.parts[1].type = 255
         obj.parts[1].male = nil
    end
end
registerBackpacks()



local m1 = tes3matrix33.new()
m1:fromEulerXYZ(90, 0, 0)
local backpackOffset = {
    translation = tes3vector3.new(22.9866, 0.5588, -1.9998),
    --rotation = tes3matrix33.new(0.2339, -0.0440, 0.9713, 0.0114, -0.9988, -0.0480, 0.9722, 0.0222, -0.2331),
    rotation = m1;
    scale = 0.9,
}

local function detachMesh(parent)
    local existingMesh = parent:getObjectByName("AttachedMesh")
    if existingMesh then
        parent:detachChild(existingMesh)
    end
end

local function attachItem(item, parent)
    local existingMesh = parent:getObjectByName("AttachedMesh")
    if existingMesh then
        parent:detachChild(existingMesh)
    end
    local mesh = tes3.loadMesh(tes3.getObject(item).mesh):clone()
    mesh:clearTransforms()
    mesh.name = "AttachedMesh"
    mesh.appCulled = false
    parent:attachChild(mesh)
end

local function setSwitchNodes(e)
    common.log:trace("backpack setting switch nodes")
    local ref = e.reference
    for switch, data in pairs(switchNodes) do
        local switchNode = ref.sceneNode:getObjectByName(switch)
        if switchNode then
            local itemToAttach
            local index = 1
            local isEquipped
            if data.blockEquip then
                for item, _ in pairs(data.items) do
                    for _, stack in pairs(e.reference.object.equipment) do
                        if stack.object.id:lower() == item then
                            isEquipped = true
                        end
                    end
                end
            end
            if not isEquipped then
                for item, _ in pairs(data.items) do
                    if ref.object.inventory:contains(item) then
                        index = 0
                        
                        itemToAttach = item
                        break
                    end
                end
            end
            switchNode.switchIndex = index
            --Attach item meshes if necessary, or remove if none equipped
            if data.attachMesh then
                if itemToAttach then
                    common.log:trace("attaching item")
                    attachItem(itemToAttach, switchNode.children[1]:getObjectByName("ATTACH_NODE"))
                else
                    detachMesh(switchNode.children[1])
                end
            end
        end
    end
    ref.sceneNode:update()
    ref.sceneNode:updateNodeEffects()
    --ref:updateEquipment() 
end



local function attachBackpack(parent, fileName, ref)
    if not config.showBackpacks then return end
    local node = tes3.loadMesh(fileName)
    if node then
        node = node:clone()
        node:clearTransforms()
        -- rename the root node so we can easily find it for detaching
        node.name = "Bip01 AttachBackpack"
        -- offset the node to emulate vanilla's left pauldron behavior
        --node.translation = backpackOffset.translation:copy()
        --node.rotation = backpackOffset.rotation:copy()
        node.scale = backpackOffset.scale
        parent:attachChild(node, true)

        local weight = ref.object.race.weight.male
        local height = ref.object.race.height.male
        if ref.object.female then
            weight = ref.object.race.weight.female
            height = ref.object.race.height.female
        end
        
        local weightMod = 1 / weight
        local heightMod = 1 / height
        
        local r = node.rotation
        local scale = tes3vector3.new(heightMod, weightMod, weightMod)
        node.rotation = tes3matrix33.new(r.x * scale, r.y * scale, r.z * scale)
    end
end


local function detachBackpack(parent)
    local node = parent:getObjectByName("Bip01 AttachBackpack")
    if node then
        parent:detachChild(node)
    end
end


local function onEquipped(e)
    -- must be a valid backpack
    local fileName = backpacks[e.item.id]
    if not fileName then 
        return 
    end

    -- get parent for attaching
    local parent = e.reference.sceneNode:getObjectByName("Bip01 Spine1")

    -- detach old backpack mesh
    detachBackpack(parent)
    -- attach new backpack mesh
    attachBackpack(parent, fileName, e.reference)

    --timer.delayOneFrame(function() 
        setSwitchNodes{reference=e.reference}
    --end)
    
    -- update parent scene node
    parent:update()
    parent:updateNodeEffects()
end


local function onUnequipped(e)
    -- must be a valid backpack
    local fileName = backpacks[e.item.id]
    if not fileName then return end

    -- get parent for detaching
    local parent = e.reference.sceneNode:getObjectByName("Bip01 Spine1")

    -- detach old backpack mesh
    detachBackpack(parent)

    timer.delayOneFrame(function() 
        setSwitchNodes{reference=e.reference}
    end)

    -- update parent scene node
    parent:update()
    parent:updateNodeEffects()
end


local function onMobileActivated(e)
    if e.reference.object.equipment then
        for _, stack in pairs(e.reference.object.equipment) do
            onEquipped{reference=e.reference, item=stack.object}
        end
    end
end

local function onLoaded(e)
    onMobileActivated{reference=tes3.player}
    for i, cell in ipairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences(tes3.objectType.npc) do
            onMobileActivated{reference=ref}
        end
    end
end

event.register("loaded", onLoaded)
event.register("equipped", onEquipped)
event.register("unequipped", onUnequipped)
event.register("mobileActivated", onMobileActivated)
event.register("activate", function(e)
    if e.activator == tes3.player then
        timer.delayOneFrame(function()
            common.log:trace("activate")
            setSwitchNodes{ reference = e.activator } 
        end)
    end
end)
 
local function updatePlayer()
    common.log:trace("updating player backpack")
    if tes3.player and tes3.player.mobile then
        --check for existing backpack and equip it
        local equippedBackpack = tes3.getEquippedItem{
            actor = tes3.player, 
            objectType = tes3.objectType.armor,
            slot = backpackSlot
        }
        if equippedBackpack then
            common.log:trace("re-equipping %s", equippedBackpack.object.name)
            onEquipped{reference = tes3.player, item = equippedBackpack.object}
        end

        equippedBackpack = tes3.getEquippedItem{
            actor = tes3.player, 
            objectType = tes3.objectType.clothing,
            slot = backpackSlot
        }
        if equippedBackpack then
            common.log:trace("re-equipping %s", equippedBackpack.object.name)
            onEquipped{reference = tes3.player, item = equippedBackpack.object}
        end
    else
        common.log:trace("player doesn't exist")
    end
end

event.register("itemDropped", updatePlayer)
event.register("menuEnter", updatePlayer)
event.register("menuExit", updatePlayer)
event.register("weaponReadied", updatePlayer)
event.register("Ashfall:triggerPackUpdate", updatePlayer)



