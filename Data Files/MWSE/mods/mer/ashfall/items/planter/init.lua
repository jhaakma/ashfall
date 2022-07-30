local common = require("mer.ashfall.common.common")
local logger = common.createLogger("Planter.init")
local Seedling = require("mer.ashfall.items.planter.Seedling")
local Planter = require("mer.ashfall.items.planter.Planter")
local config = require("mer.ashfall.items.planter.config")
local ReferenceController = require("mer.ashfall.referenceController")
local ActivatorController = require "mer.ashfall.activators.activatorController"

ReferenceController.registerReferenceController{
    id = "planter",
    requirements = function(_, ref)
        return Planter.isPlanter(ref)
    end
}
ActivatorController.registerActivator{
    name = "Planter",
    id = "planter",
    type = "planter",
    requirements = function(_, ref)
        return Planter.isPlanter(ref)
    end,
}

local function hasFloraPattern(id)
    for _, pattern in ipairs(config.floraPatterns) do
        if string.find(id, pattern) then
            return true
        end
    end
    return false
end

---@param container tes3container
local function isValidOrganicContainer(container)
    local id = container.id:lower()
    return container.organic
        and container.respawns
        and container.script == nil
        and #container.inventory > 0
        and hasFloraPattern(id)
        and not config.plantBlacklist[id]
end



do --Initialise Seedling Data
    ---Iterate over every ingredient and find out which ones are valid seedlings
    --Get all ingredients for each organic container
    local startTime = os.clock()
    local containerIngreds = {}
    for container in tes3.iterateObjects(tes3.objectType.container) do
        if isValidOrganicContainer(container) then
            containerIngreds[container] = {}
            for ingred in common.helper.getIngredients(container.inventory) do
                containerIngreds[container][ingred] = true
            end
        end
    end

    --Initialise list of seedlings by finding all ingredients which exist in organic flora
    for ingredient in tes3.iterateObjects(tes3.objectType.ingredient) do
        local validFoodTypes = {
            [common.staticConfigs.foodConfig.type.herb] = true,
            [common.staticConfigs.foodConfig.type.vegetable] = true,
            [common.staticConfigs.foodConfig.type.mushroom] = true,
            [common.staticConfigs.foodConfig.type.food] = true,
        }
        local thisFoodType = common.staticConfigs.foodConfig.getFoodType(ingredient)
        local isValidFoodType = validFoodTypes[thisFoodType]
        local blacklisted = config.seedlingBlacklist[ingredient.id:lower()]

        if isValidFoodType and not blacklisted then
            for container in pairs(containerIngreds) do
                if containerIngreds[container][ingredient] then
                    Seedling.seedlingPlantMap[ingredient] =  Seedling.seedlingPlantMap[ingredient] or {}
                    table.insert(Seedling.seedlingPlantMap[ingredient], container)
                end
            end
        end
    end

    logger:trace("Valid seedlings: ")
    for ingredient, _ in pairs(Seedling.seedlingPlantMap) do
            logger:trace("Seedling: %s", ingredient)
            local containers = Seedling.seedlingPlantMap[ingredient]
            for _, container in pairs(containers) do
                logger:trace("    Container: %s", container.id)
            end
    end
    local endTime = os.clock()
    logger:trace("Time: %.2f", endTime - startTime)
end

local GROWTH_CHECK_INTERVAL = 0.005
local function growSimulate(timestamp)
    tes3.player.tempData.ashfallLastGrowthUpdated = tes3.player.tempData.ashfallLastGrowthUpdated or timestamp
    local lastGrowthUpdated = tes3.player.tempData.ashfallLastGrowthUpdated
    if timestamp - lastGrowthUpdated > GROWTH_CHECK_INTERVAL then
        local hoursPassed = timestamp - lastGrowthUpdated
        tes3.player.tempData.ashfallLastGrowthUpdated = timestamp
        ReferenceController.iterateReferences("planter", function(planterRef)
            --Grow or recover plant
            local planter = Planter.new(planterRef)
            if planter and planter.plantId then
                planter.logger:trace("updating planter")
                if planter:isFullyGrown() then
                    planter.logger:trace("fully grown")
                    planter:updateTimeToHarvest(hoursPassed)
                    --If time has run out, update the mesh to set the switch nodes
                    if planter.timeUntilHarvestable <= 0 then
                        planter.timeUntilHarvestable = 0
                        planter:updateGHNodes()
                    end
                else
                    planter.logger:trace("not fully grown")
                    planter:grow(hoursPassed)
                end
            end
        end)
    end
end

local RAIN_CHECK_INTERVAL = 0.005
local function rainSimulate(timestamp)
    --Check for rain
    tes3.player.tempData.ashfallLastRainCheck = tes3.player.tempData.ashfallLastRainCheck or timestamp
    local lastRainCheck = tes3.player.tempData.ashfallLastRainCheck
    if timestamp - lastRainCheck > RAIN_CHECK_INTERVAL then
        local hoursPassed = timestamp - lastRainCheck
        tes3.player.tempData.ashfallLastRainCheck = timestamp
        ReferenceController.iterateReferences("planter", function(planterRef)
            --Check for rain
            local planter = Planter.new(planterRef)
            if planter then
                planter:doRainWater(hoursPassed)
            end
        end)
    end
end



--Grow plants over time
---@param e simulateEventData
event.register("simulate", function(e)
    growSimulate(e.timestamp)
    rainSimulate(e.timestamp)
end)

---@param e referenceActivatedEventData
local function updatePlanterMeshes(e)
    if ReferenceController.isReference("planter", e.reference) then
        local planter = Planter.new(e.reference)
        if planter then
            logger:trace("Updating planter on referenceActivated")

            planter:updatePlantMesh()
            planter:updateDirtTexture()
            planter:updateDirtWater()
        end
    end
end

event.register("referenceSceneNodeCreated", updatePlanterMeshes)
event.register("referenceActivated", updatePlanterMeshes)
event.register("loaded", function(e)
    ReferenceController.iterateReferences("planter", function(planterRef)
        updatePlanterMeshes({reference = planterRef})
    end)
end)


---@param e uiObjectTooltipEventData
event.register("uiObjectTooltip", function(e)
    local tooltip = e.tooltip
    local ref = e.reference
    if ref and Planter.isPlanter(ref) then
        local planter = Planter.new(ref)
        if not planter then return end
        local messages = planter:getTooltipMessages()
        for _, message in ipairs(messages) do
            common.helper.addLabelToTooltip(tooltip, message)
        end
    end
end)
