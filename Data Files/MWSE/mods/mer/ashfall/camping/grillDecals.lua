local common = require ("mer.ashfall.common.common")

local cookStates = {
    cooked = {texPath = "textures\\Ashfall\\grill\\cooked.dds"},
    burnt = {texPath = "textures\\Ashfall\\grill\\burnt.dds"},
    diseased = {texPath = "textures\\Ashfall\\grill\\diseased.dds"},
    blighted = {texPath = "textures\\Ashfall\\grill\\blighted.dds"}
}

local function traverseNIF(roots)
    local function iter(nodes)
        for i, node in ipairs(nodes or roots) do
            if node then
                coroutine.yield(node)
                if node.children then
                    iter(node.children)
                end
            end
        end
    end
    return coroutine.wrap(iter)
end


--pre-load textures
local function preloadTextures()
    common.log:trace("Preloading Grill textures")
    for _, cookState in pairs(cookStates) do
        local texture = niSourceTexture.createFromPath(cookState.texPath)
        cookState.texture = texture
    end
end
preloadTextures()



local function addDecal(property, decalState)
    local decal 
    if decalState then
        decal = cookStates[decalState].texture
    end
    --Remove old one if it exists
    for index, map in ipairs(property.maps) do
        local texture = map and map.texture
        local fileName = texture and texture.fileName
        
        if fileName then
            common.log:trace("fileName: %s", fileName)
            for _, cookState in pairs(cookStates) do
                if fileName == cookState.texPath then
                    if decal then
                        common.log:trace("Found existing decal, replacing with %s", decal.fileName)
                        map.texture = decal
                    else
                        common.log:trace("Removing existing decal")
                        property:removeDecalMap(index)
                    end
                    return
                end
            end
        end
    end

    if decal then
        --Add new decal
        if property.canAddDecal then
            property:addDecalMap(decal)
            common.log:trace("Adding new decal")
        end
    end
end

local function updateIngredient(e)
    local reference = e.reference
    local decalState = e.reference.data.grillState
    if (not decalState) and e.reference.data.mer_disease then
        decalState = e.reference.data.mer_disease.spellType == tes3.spellType.disease and "diseased" or "blighted"
    end

    common.log:trace("Updating %s decal for %s",
        decalState or "(removing)",
        reference.id
    )
   
    for node in traverseNIF{ reference.sceneNode} do
        local success, texturingProperty, alphaProperty = pcall(function() return node:getProperty(0x4), node:getProperty(0x0) end)
        if (success and texturingProperty) then
            local clonedProperty = node:detachProperty(0x4):clone()
            node:attachProperty(clonedProperty)
            addDecal(clonedProperty, decalState)
            node:updateProperties()
        end
    end
end

event.register("Ashfall:ingredCooked", updateIngredient)


local function ingredPlaced(e)
    local safeRef = tes3.makeSafeObjectHandle(e.reference)
    local function f()
        if not safeRef:valid() then return end
        local isIngredient = (
            e.reference and
            (not common.helper.isStack(e.reference) ) and
            ( e.reference.object.objectType == tes3.objectType.ingredient or 
            e.reference.baseObject.objectType == tes3.objectType.ingredient)
        )
        if isIngredient then
            common.log:debug("Updating decals for %s", e.reference.object.id)
            updateIngredient{ reference = e.reference}
        end
    end
    event.register("enterFrame", f, {doOnce=true})
end
event.register("referenceSceneNodeCreated", ingredPlaced)