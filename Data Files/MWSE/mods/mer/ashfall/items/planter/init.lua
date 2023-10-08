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
    ids = {
        furn_planter_03 = true,
    },
    menuConfig  = {
        name = "Planter",
        menuCommands = {
            Planter.buttons.harvest,
            Planter.buttons.plantSeed,
            Planter.buttons.water,
            Planter.buttons.removePlant,
        },
        tooltipExtra = function(ref, tooltip)
            local Planter = require("mer.ashfall.items.planter.Planter")
            local planter = Planter.new(ref)
            if planter then
                for _, message in ipairs(planter:getTooltipMessages()) do
                    local label = tooltip:createLabel{
                        text = message
                    }
                    label.autoHeight = true
                    label.autoWidth = true
                    label.wrapText = true
                    label.justifyText = "center"
                end
            end
        end
    }
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
        ---@cast container tes3container
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

    --Trace logging : print out all valid seedlings
    if logger:doLog("TRACE") then
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
end

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
    timer.start{
        duration = common.helper.getUpdateIntervalInSeconds(),
        iterations = -1,
        callback = function()
            ReferenceController.iterateReferences("planter", function(planterRef)
                --Grow or recover plant
                local planter = Planter.new(planterRef)
                if planter then
                    planter:progress()
                end
            end)
        end
    }
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


