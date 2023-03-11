local common = require("mer.ashfall.common.common")
local logger = common.createLogger("SkinningService")
local HarvestService = require("mer.ashfall.harvest.service")
local skinningConfig = require("mer.ashfall.skinning.config")
local CraftingFramework = include("CraftingFramework")

if not CraftingFramework then
    logger:error("CraftingFramework not found")
end

---@class Ashfall.SkinningService
local SkinningService = {}

local function isValidActor(target)
    local objType = target and target.baseObject.objectType
    local creatureType = target.object.type
    if not objType then return false end
    return skinningConfig.actorTypes[objType] == true
        and skinningConfig.creatureTypes[creatureType] == true
end

local function isValidMaterial(ingredient)
    for materialType, _ in pairs(skinningConfig.materials) do
        local material = CraftingFramework.Material.getMaterial(materialType)
        if material then
            if material:itemIsMaterial(ingredient.id) then
                return true
            end
        end
    end
end

local function isValidFoodType(ingredient)
    for foodType, _ in pairs(skinningConfig.foodTypes) do
        local foodConfig = common.staticConfigs.foodConfig
        if foodConfig.getFoodType(ingredient) == foodConfig.type[foodType] then
            return true
        end
    end
end

function SkinningService.hasMeatDuplicates(ingredients)
    local MAX_MEAT = 2
    local meatCount = 0
    for ingredId, _ in pairs(ingredients) do
        local ingredient = tes3.getObject(ingredId)
        if isValidFoodType(ingredient) then
            meatCount = meatCount + 1
        end
    end
    return meatCount > MAX_MEAT
end

---@param target tes3reference
---@param currentIngredients table<string, boolean>
---@return string|nil
local function getMeatAlternative(target, currentIngredients)
    for ingredId, meatConfig in pairs(skinningConfig.extraSkinnables) do
        --find config for this creature
        if meatConfig.creatures[target.baseObject.id:lower()] then
            logger:debug("Checking current ingredients for alternatives")
            for ingred, _ in pairs(currentIngredients) do
                --skip if existing meat is found
                if meatConfig.alternatives and meatConfig.alternatives[ingred:lower()] then
                    logger:debug("Found existing meat %s", ingred)
                    return nil
                end
            end
            logger:debug("Found meat %s for creature %s",
                ingredId, target.baseObject.id)
            return ingredId
        end
    end
end

function SkinningService.getSkinnableIngredients(reference)
    return reference
    and reference.data
    and reference.data.ashfall_skinnable_ingredients
end

---@param target tes3reference
---@return table<string, boolean>|nil
function SkinningService.calculateSkinnableIngredients(target)
    logger:debug("getSkinnableIngredients() - target: %s", target)
    if not isValidActor(target) then return end
    logger:debug("is valid actor type")
    local ingredients = {}
    logger:debug("Getting contents")
    local maxDepth = 50
    local currentDepth = 0
    ---@param ingred tes3ingredient
    for ingred in common.helper.getIngredients(target.baseObject.inventory) do
        if currentDepth > maxDepth then
            logger:error("Max depth reached")
            break
        end
        currentDepth = currentDepth + 1
        if isValidMaterial(ingred) or isValidFoodType(ingred) then
            ingredients[ingred.id:lower()] = true
        end
            --find duplicates
        if SkinningService.hasMeatDuplicates(ingredients) then
            logger:warn("Found too many duplicate meat, aborting")
            return {}
        end
    end
    logger:debug("Filtered contents size: %d", table.size(ingredients))

    local meatAlternative = getMeatAlternative(target, ingredients)
    if meatAlternative then
        local meatObj = tes3.getObject(meatAlternative)
        logger:assert(meatObj ~= nil, "Could not find meat alternative %s", meatAlternative)
        ingredients[meatAlternative:lower()] = true
    end

    --Log all the ingredient ids
    logger:debug("skinnable ingreds: ")
    for ingredId, _ in pairs(ingredients) do
        logger:debug("- %s", ingredId)
    end

    return ingredients
end

---@param target tes3reference
---@param ingredients table<string, boolean>
function SkinningService.removeIngredientsFromCorpse(target, ingredients)
    logger:debug("removeIngredientsFromCorpse()")
    if not isValidActor(target) then
        logger:debug("Not a valid actor type")
        return
    end
    ---@type table<string, number>
    local removedItems = {}
    for ingred, _  in pairs(ingredients) do
        logger:debug("Removing %s from corpse", ingred)
        local count = tes3.getItemCount{ item = ingred, reference = target }
        tes3.removeItem{
            reference = target,
            item = ingred,
            count = count
        }
        removedItems[ingred:lower()] = count
    end
    return removedItems
end

function SkinningService.calculateDestructionLimit(reference)
    --Set initial value based on skill
    local survivalSkill = common.skills.survival.value
    local destructionLimit = math.remap(survivalSkill,
        skinningConfig.MIN_SURVIVAL_SKILL,
        skinningConfig.MAX_SURVIVAL_SKILL,
        skinningConfig.MIN_DESTRUCTION_LIMIT,
        skinningConfig.MAX_DESTRUCTION_LIMIT)
    destructionLimit = math.clamp(destructionLimit,
    skinningConfig.MIN_DESTRUCTION_LIMIT,
    skinningConfig.MAX_DESTRUCTION_LIMIT)
    logger:debug("Initial destructionLimit: %s", destructionLimit)
    --Add some randomness
    destructionLimit = destructionLimit + math.random(0, skinningConfig.HARVEST_VARIANCE)
    logger:debug("DestructionLimit after random: %s", destructionLimit)
    --Height influence
    local height = HarvestService.getRefHeight(reference)
    local heightEffect = math.remap(height,
        skinningConfig.MIN_HEIGHT,
        skinningConfig.MAX_HEIGHT,
        skinningConfig.MIN_HEIGHT_EFFECT,
        skinningConfig.MAX_HEIGHT_EFFECT)
    heightEffect = math.clamp(heightEffect,
        skinningConfig.MIN_HEIGHT_EFFECT,
        skinningConfig.MAX_HEIGHT_EFFECT)
    logger:debug("Height effect: %s", heightEffect)
    destructionLimit = math.ceil(destructionLimit * heightEffect)
    logger:debug("DestructionLimit after height effect: %s", destructionLimit)
    return destructionLimit
end

function SkinningService.harvest(reference, ingredients)
    HarvestService.resetSwings(reference)
    common.skills.survival:progressSkill(skinningConfig.SWINGS_NEEDED * 2)
    local pickId = table.choice(table.keys(ingredients))
    local pick = tes3.getObject(pickId)
    if not pick then
        logger:error("Could not find ingredient %s", pick)
        return
    end
    HarvestService.showHarvestedMessage(1, pick.name)
    logger:debug("Ingredient harvest: %s", pick.id)
    tes3.addItem{
        reference = tes3.player,
        item = pick.id,
        count = 1
    }
    HarvestService.updateTotalHarvested(reference, 1)
end

return SkinningService