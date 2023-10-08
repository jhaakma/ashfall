

local activatorController = require "mer.ashfall.activators.activatorController"
local foodConfig = require "mer.ashfall.config.foodConfig"
local skillConfigs = require("mer.ashfall.config.skillConfigs")
local LiquidContainer = require("mer.ashfall.liquid.LiquidContainer")
local CampfireUtil = {}
local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("campfireUtil")

function CampfireUtil.getUtensilData(dataHolder)
    local utensilId = dataHolder.data.utensilId
    local utensilData = common.staticConfigs.bottleList[utensilId]


    if dataHolder.object and not utensilData then
        utensilData = common.staticConfigs.bottleList[dataHolder.object.id:lower()]
    end
    return utensilData
end

function CampfireUtil.getUtensilCapacity(e)
    local ref = e.dataHolder
    local obj = e.object
    local bottleData = obj and common.staticConfigs.bottleList[obj.id:lower()]
    local utensilData = ref and CampfireUtil.getUtensilData(ref)
    local capacity = (bottleData and bottleData.capacity)
        or ( utensilData and utensilData.capacity )

    return capacity
end

function CampfireUtil.getWaterCapacityFromReference(reference)
    return CampfireUtil.getUtensilCapacity{
        dataHolder = reference,
        object = reference.object,
    }
end


function CampfireUtil.getDataFromUtensilOrCampfire(e)
    local ref = e.dataHolder
    local obj = e.object
    local bottleData = obj and common.staticConfigs.bottleList[obj.id:lower()]
    local utensilData = ref and ref.object and CampfireUtil.getUtensilData(ref)

    return {
        capacity = (bottleData and bottleData.capacity) or ( utensilData and utensilData.capacity ),
        holdsStew = (bottleData and bottleData.holdsStew) or ( utensilData and utensilData.type == "cookingPot")
    }
end


---@class Ashfall.AddIngredToStewType
---@field campfire tes3reference
---@field item tes3ingredient
---@field count number optional, default: 1

local stewIngredientCooldownAmount = 20
---@param e Ashfall.AddIngredToStewType
function CampfireUtil.addIngredToStew(e)
    local campfire = e.campfire
    local item = e.item
    local amount = e.count or 1
    local foodType = foodConfig.getFoodTypeResolveMeat(item)
    local liquidContainer = LiquidContainer.createFromReference(campfire)
    if not liquidContainer then
        logger:error("Could not create liquid container from campfire")
        return
    end
    local capacity = liquidContainer:getStewCapacity(foodType)
    local amountToAdd = math.min(amount, capacity)
    if amountToAdd == 0 then return amountToAdd end

    --Cool down stew
    liquidContainer.stewProgress = math.max(( liquidContainer.stewProgress - stewIngredientCooldownAmount ), 0)

    --initialise stew levels
    liquidContainer.data.stewLevels = liquidContainer.data.stewLevels or {}
    liquidContainer.data.stewLevels[foodType] = liquidContainer.data.stewLevels[foodType] or 0
    --Add ingredient to stew
    logger:debug("old stewLevel: %s", liquidContainer.data.stewLevels[foodType])
    logger:debug("getting capacity for %s", liquidContainer.itemId)
    local waterRatio = liquidContainer.waterAmount / liquidContainer.capacity
    logger:debug("waterRatio: %s", waterRatio)
    local ingredAmountToAdd = amountToAdd * common.staticConfigs.stewIngredAddAmount / waterRatio
    logger:debug("ingredAmountToAdd: %s", ingredAmountToAdd)
    liquidContainer.stewLevels[foodType] = math.min(liquidContainer.stewLevels[foodType] + ingredAmountToAdd, 100)
    liquidContainer.waterType = "stew"
    logger:debug("new stewLevel: %s", liquidContainer.stewLevels[foodType])

    local skillIncrement = skillConfigs.survival.stew.gainPerIngredient * amountToAdd
    common.skills.survival:exercise(skillIncrement)

    tes3.playSound{ reference = tes3.player, sound = "ashfall_water" }
    event.trigger("Ashfall:UpdateAttachNodes", { reference = campfire,})
    return amountToAdd
end


function CampfireUtil.findNamedParentNode(node, name)
    while node and node.parent do
        if node.name and node.name == name then
            return true
        else
            node = node.parent
        end
    end
end

---@return niNode|nil NiNode
function CampfireUtil.findNamedChildNode(node, name)
    if node.name and node.name == name then
        return node
    end
    for _, child in pairs(node.children) do
        local result = CampfireUtil.findNamedChildNode(child, name)
        if result then return result end
    end
end



--Check if you've placed an item on top of a stew
--@param reference tes3reference | tes3itemStack
function CampfireUtil.getPlacedOnContainer()
    local reference = activatorController.currentRef
    if reference then
        --look for just a standalone cooking pot or container
        return common.staticConfigs.bottleList[reference.object.id:lower()] and reference or false
    else
        logger:trace("ray return nothing")
    end
    return false
end

--[[
    When an ingredient is placed when loading a cell,
    perform a ray test to get the object below it and check
    if it has a grill node in its parent list
]]
---@param ingredReference tes3reference
function CampfireUtil.getFoodPlacedOnGrill(ingredReference, campfire)
    local grillNodes = {
        "ASHFALL_GRILLER",
        "SWITCH_GRILL",
        "ATTACH_GRILL"
    }
    for _, nodeName in ipairs(grillNodes) do
        local node = campfire.sceneNode:getObjectByName(nodeName)
        if node then
            return node
        end
    end
end


function CampfireUtil.refCanHangUtensil(reference)
    return reference.sceneNode:getObjectByName("DROP_HANG_UTENSIL")
end


function CampfireUtil.itemCanBeHanged(item)
    local utensilData =  common.staticConfigs.utensils[item.id:lower()]
    if utensilData then
        if utensilData.type == "kettle" or utensilData.type == "cookingPot" then
            local mesh = tes3.loadMesh(item.mesh)
            logger:debug("Mesh: %s", item.mesh)
            local attachPointNode = mesh:getObjectByName("ATTACH_POINT")
            logger:debug("AttachPointNode: %s", attachPointNode)
            return attachPointNode ~= nil
        end
    end
    return false
end


function CampfireUtil.refIsCookingPot(reference)
    return reference.data.utensil == "cookingPot"
        or common.staticConfigs.cookingPots[reference.baseObject.id:lower()]
end

function CampfireUtil.refIsKettle(reference)
    return reference.data.utensil == "kettle"
        or common.staticConfigs.kettles[reference.baseObject.id:lower()]
end

function CampfireUtil.isUtensil(ref)
    return common.staticConfigs.utensils[ref.baseObject.id:lower()] ~= nil
        or ( ref.data and ref.data.utensil ~= nil)
end

function CampfireUtil.isWaterContainer(reference)
    return CampfireUtil.isUtensil(reference)
        or common.staticConfigs.bottleList[reference.object.id:lower()]
end



return CampfireUtil

