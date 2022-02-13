
local DropConfig = require "mer.ashfall.camping.campfire.config.DropConfig"
local itemTooltips = require("mer.ashfall.ui.itemTooltips")
local activatorController = require "mer.ashfall.activators.activatorController"
local foodConfig = require "mer.ashfall.config.foodConfig"

local AttachConfig = require "mer.ashfall.camping.campfire.config.AttachConfig"
local CampfireUtil = {}
local common = require ("mer.ashfall.common.common")

--[[
    Get heat based on fuel level and modifiers
]]
function CampfireUtil.getHeat(reference)
    local data = reference.data
    local bellowsEffect = 1.0
    local bellowsId = data.bellowsId and data.bellowsId:lower()
    local bellowsData = common.staticConfigs.bellows[bellowsId]
    if bellowsData then
        bellowsEffect = bellowsData.heatEffect
    end
    local isLit = data.isLit
    local fuelLevel = data.fuelLevel or 0
    local isWeak = common.staticConfigs.activatorConfig.list.teaWarmer:isActivator(reference.object.id:lower())
    local weakEffect = isWeak and 0.1 or 1.0

    if (not isLit) or (fuelLevel <= 0) then
        return 0
    else
        local finalHeat = (fuelLevel * bellowsEffect * weakEffect)
        return finalHeat
    end
end

function CampfireUtil.getAttachmentConfig(reference, node)
    if reference then
        if common.staticConfigs.bottleList[reference.object.id:lower()] then
            return {
                tooltipExtra = function(campfire, tooltip)
                    itemTooltips(campfire.object, campfire.itemData, tooltip)
                end
            }
        end
    end

    if not node then return end
    --default campfire
    local attachmentConfig
    while node.parent do
        if AttachConfig[node.name] then
            attachmentConfig = AttachConfig[node.name]
            break
        end
        node = node.parent
    end
    return attachmentConfig
end

function CampfireUtil.getDropConfig(reference, node)
    --default campfire
    local dropConfig
    while node.parent do
        if DropConfig.node[node.name] then
            dropConfig = DropConfig.node[node.name]
            break
        end
        node = node.parent
    end
    if not dropConfig then
        if common.staticConfigs.bottleList[reference.object.id:lower()] then
            return DropConfig.waterContainer
        end
    end
    return dropConfig
end

function CampfireUtil.getAttachmentName(campfire, attachConfig)
    if attachConfig.name then
        return attachConfig.name
    elseif attachConfig.idPath then
        local objId = campfire.data[attachConfig.idPath]
        if objId then
            local obj = tes3.getObject(objId)
            return common.helper.getGenericUtensilName(obj)
        end
    end
    --fallback
    return nil
end



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

function CampfireUtil.setHeat(refData, newHeat, reference)
    common.log:trace("Setting heat of %s to %s", reference or "[unknown]", newHeat)
    local heatBefore = refData.waterHeat or 0
    refData.waterHeat = math.clamp(newHeat, 0, 100)
    local heatAfter = refData.waterHeat
    --add sound if crossing the boiling barrior
    if reference and not reference.disabled then
        if heatBefore < common.staticConfigs.hotWaterHeatValue and heatAfter > common.staticConfigs.hotWaterHeatValue then
            event.trigger("Ashfall:UpdateAttachNodes", {campfire = reference})
        end
        --remove boiling sound
        if heatBefore > common.staticConfigs.hotWaterHeatValue and heatAfter < common.staticConfigs.hotWaterHeatValue then
            common.log:debug("No longer hot")
            event.trigger("Ashfall:UpdateAttachNodes", {campfire = reference})
        end
    end
end


local heatLossAtMinCapacity = 2.5
local heatLossAtMaxCapacity = 1.0
local waterHeatRate = 40--base water heat/cooling speed
local minFuelWaterHeat = 5--min fuel multiplier on water heating
local maxFuelWaterHeat = 10--max fuel multiplier on water heating
function CampfireUtil.updateWaterHeat(refData, capacity, reference)
    if not refData.waterAmount then return end
    local now = tes3.getSimulationTimestamp()
    refData.lastWaterUpdated = refData.lastWaterUpdated or now
    local timeSinceLastUpdate = now - refData.lastWaterUpdated
    refData.lastWaterUpdated = now
    refData.waterHeat = refData.waterHeat or 0
    local oldHeat = refData.waterHeat
    --Heats up or cools down depending on fuel/is lit
    local heatEffect = -1--negative if cooling down
        --TODO: Implement heatLossMultiplier based on waterContainer data
    --

    common.log:trace("Water heat: %s", oldHeat)

    if refData.isLit and reference then--based on fuel if heating up
        heatEffect = math.remap(CampfireUtil.getHeat(reference), 0, common.staticConfigs.maxWoodInFire, minFuelWaterHeat, maxFuelWaterHeat)
        common.log:trace("BOILER heatEffect: %s", heatEffect)
    else
        common.log:trace("Looking for heat source underneath. Strong heat only heats utensils, weak heat doesn't work on pots")
        local heater, heatType = common.helper.getHeatFromBelow(reference)
        local heaterIsLit = heater and heater.data.isLit
        if heaterIsLit then
            local isUtensil = reference and common.staticConfigs.utensils[reference.object.id:lower()]
            local isCookingPot = reference and common.staticConfigs.cookingPots[reference.object.id:lower()]
            local doStrongHeat = isUtensil and heatType == "strong"
            local doWeakHeat = (not isCookingPot) and heatType == "weak"
            if doStrongHeat then
                heatEffect = math.remap(CampfireUtil.getHeat(heater), 0, common.staticConfigs.maxWoodInFire, minFuelWaterHeat, maxFuelWaterHeat)
            elseif doWeakHeat then
                --Weak flames greatly reduce the rate of heat loss
                --but not for cooking pots
                heatEffect = -0.01
            end
        end
    end

    --Amount of water determines how quickly it boils

    --We use a hardcoded value instead of capacity because it doesn't make sense to heat up slower when the container is smaller
    local filledAmount = math.min(refData.waterAmount / 100, 1)
    common.log:trace("BOILER filledAmount: %s", filledAmount)
    local filledAmountEffect = math.remap(filledAmount, 0.0, 1.0, heatLossAtMinCapacity, heatLossAtMaxCapacity)
    common.log:trace("BOILER filledAmountEffect: %s", filledAmountEffect)

    --Calculate change
    local heatChange = timeSinceLastUpdate * heatEffect * filledAmountEffect * waterHeatRate
    local newHeat = oldHeat + heatChange
    CampfireUtil.setHeat(refData, newHeat, reference)
end


function CampfireUtil.isUtensil(ref)
    return common.staticConfigs.utensils[ref.object.id:lower()] ~= nil
        or ( ref.data and ref.data.utensil ~= nil)
end

---@class AshfallAddIngredToStewType
---@field campfire tes3reference
---@field item tes3ingredient
---@field count number optional, default: 1
local stewIngredientCooldownAmount = 20
local skillSurvivalStewIngredIncrement  = 5
---@param e AshfallAddIngredToStewType
function CampfireUtil.addIngredToStew(e)
    local campfire = e.campfire
    local item = e.item
    local amount = e.count or 1
    local foodType = foodConfig.getFoodTypeResolveMeat(item)
    local capacity = CampfireUtil.getStewCapacity{campfire = campfire, foodType = foodType}
    local amountToAdd = math.min(amount, capacity)
    if amountToAdd == 0 then return amountToAdd end
    --Cool down stew
    campfire.data.stewProgress = campfire.data.stewProgress or 0
    campfire.data.stewProgress = math.max(( campfire.data.stewProgress - stewIngredientCooldownAmount ), 0)

    --initialise stew levels
    campfire.data.stewLevels = campfire.data.stewLevels or {}
    campfire.data.stewLevels[foodType] = campfire.data.stewLevels[foodType] or 0
    --Add ingredient to stew
    common.log:debug("old stewLevel: %s", campfire.data.stewLevels[foodType])

    common.log:debug("getting capacity for %s", campfire.object.id)
    local maxCapacity = CampfireUtil.getUtensilCapacity{
        dataHolder = campfire,
        object = campfire.object
    }
    local waterRatio = campfire.data.waterAmount / maxCapacity
    common.log:debug("waterRatio: %s", waterRatio)
    local ingredAmountToAdd = amountToAdd * common.staticConfigs.stewIngredAddAmount / waterRatio
    common.log:debug("ingredAmountToAdd: %s", ingredAmountToAdd)
    campfire.data.stewLevels[foodType] = math.min(campfire.data.stewLevels[foodType] + ingredAmountToAdd, 100)
    campfire.data.waterType = "stew"
    common.log:debug("new stewLevel: %s", campfire.data.stewLevels[foodType])

    common.skills.survival:progressSkill(skillSurvivalStewIngredIncrement*amountToAdd)

    tes3.playSound{ reference = tes3.player, sound = "Swim Right" }
    event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire,})
    return amountToAdd
end

function CampfireUtil.getStewCapacity(e)
    local campfire = e.campfire
    local foodType = e.foodType
    common.log:debug("foodType", foodType)
    common.log:debug("Water amount: %s", campfire.data.waterAmount)

    local maxCapacity = CampfireUtil.getUtensilCapacity{
        dataHolder = campfire,
        object = campfire.object
    }
    local waterRatio = campfire.data.waterAmount / maxCapacity
    common.log:debug("waterRatio: %s", waterRatio)
    local stewLevel = (campfire.data.stewLevels and campfire.data.stewLevels[foodType] or 0)
    common.log:debug("stewLevel: %s", stewLevel)
    local adjustedIngredAmount = common.staticConfigs.stewIngredAddAmount / waterRatio
    common.log:debug("adjustedIngredAmount: %s", adjustedIngredAmount)
    local rawCapacity = 100 - stewLevel
    common.log:debug("rawCapacity: %s", rawCapacity)
    local capacity = math.ceil(rawCapacity / adjustedIngredAmount)
    common.log:debug("capacity: %s", capacity)

    return capacity
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

---@return niNode NiNode
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
        common.log:trace("ray return nothing")
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

function CampfireUtil.getDropText(node, reference, item, itemData)
    local dropConfig = CampfireUtil.getDropConfig(reference, node)
    if not dropConfig then return end
    for _, optionId in ipairs(dropConfig) do
        local option = require('mer.ashfall.camping.dropConfigs.' .. optionId)
        local canDrop, errorMsg = option.canDrop(reference, item, itemData)
        local hasError = (errorMsg ~= nil)
        if canDrop or hasError then
            return option.dropText(reference, item, itemData), hasError
        end
    end
end

function CampfireUtil.refCanHangUtensil(reference)
    return reference.sceneNode:getObjectByName("DROP_HANG_UTENSIL")
end

function CampfireUtil.itemCanBeHanged(item)
    if common.staticConfigs.utensils[item.id:lower()] then
        local mesh = tes3.loadMesh(item.mesh)
        return mesh:getObjectByName("ATTACH_POINT")
    end
end

function CampfireUtil.refCanBeHanged(reference)
    return reference.sceneNode:getObjectByName("ATTACH_POINT")
end

return CampfireUtil

