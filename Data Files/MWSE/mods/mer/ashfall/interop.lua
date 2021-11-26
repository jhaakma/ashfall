
local branchInterop = require "mer.ashfall.branch.branchInterop"

local common = require("mer.ashfall.common.common")
local staticConfigs = common.staticConfigs
local activatorConfig = staticConfigs.activatorConfig
local foodConfig = staticConfigs.foodConfig
local ratingsConfig = require('mer.ashfall.tempEffects.ratings.ratingsConfig')
local climateConfig = require('mer.ashfall.config.weatherRegionConfig')
local teaConfig = require('mer.ashfall.config.teaConfig')
local Activator = require("mer.ashfall.objects.Activator")
local overrides = require("mer.ashfall.config.overrides")

local function listValidActivatorTypes()
    local message = '\n'
    for typeString, _ in pairs(activatorConfig.types) do
        message = message .. '\n' .. typeString
    end
    return message
end

local function listValidWaterContainers()
    local message = '\n'
    for typeString, _ in pairs(staticConfigs.bottleConfig) do
        message = message .. '\n' .. typeString
    end
    return message
end

local function listValidFoodTypes()
    local message = '\n'
    for typeString, _ in pairs(foodConfig.type) do
        message = message .. '\n' .. typeString
    end
    return message
end

local function listValidClimateTypes()
    local message = '\n'
    for typeString, _ in pairs(climateConfig.CLIMATE) do
        message = message .. '\n' .. typeString
    end
    return message
end

local function registerActivatorType(e)
    assert(type(e.id) == 'string', "registerActivatorType: Missing id")
    assert(type(e.name) == 'string', "registerActivatorType: Missing name")
    assert(type(e.type) == 'string', "registerActivatorType: missing type")
    if e.ids then
        assert(type(e.ids) == 'table')
    end
    if e.patterns then
        assert(type(e.patterns) == 'table')
    end
    common.log:debug("Registering '%s' as a new Activator Type", e.type)

    if not activatorConfig.types[e.type] then
        common.log:debug('Type "%s" does not exist, creating', e.type)
        activatorConfig.types[e.type] = activatorConfig.types[e.type]
    end
    local idList = {}
    if e.ids then
        for _, id in ipairs(e.ids) do
            idList[id] = true
        end
    end
    local patternList = {}
    if e.patterns then
        for _, id in ipairs(e.patterns) do
            patternList[id] = true
        end
    end

    if not activatorConfig.list[e.id] then
        activatorConfig.list[e.id] = Activator:new{
            name = e.name,
            type = e.type,
            ids = idList,
            patterns = patternList
        }
    else
        error(string.format("registerActivatorType: %s already exists as an activator type", e.id))
    end

    return true
end

local function registerActivators(e)
    common.log:debug("Registering the following activator %s: ", (e.usePatterns and "patterns" or "ids"))
    for id, activatorType in pairs(e.data) do

        assert(type(id) == 'string', "registerActivator(): Invalid id. Must be a string.")

        local activator = activatorConfig.list[activatorType]
        assert(activator, string.format("registerActivator(): %s is an invalid activator type. Valid types include: %s",
                activatorType, listValidActivatorTypes()))

        if e.usePatterns then
            activator:addPattern(id)
        else
            activator:addId(id)
        end

        common.log:debug("    %s as %s", id, activatorType)
    end
    return true
end
event.register("Ashfall:RegisterActivators", registerActivators)

local function registerWaterSource(e)
    assert(type(e.name) == "string", "registerWaterSource(): No name string provided")
    assert(type(e.ids) == "table", "registerWaterSource(): No table of ids provided")
    local waterType = e.isDirty and activatorConfig.types.dirtyWaterSource or activatorConfig.types.waterSource

    local idList = {}
    for _, id in ipairs(e.ids) do
        idList[id] = true
    end
    activatorConfig.list[e.name] = Activator:new{
        name = e.name,
        type = waterType,
        ids = idList
    }
    return true
end

local function registerWaterContainers(e)
    local includeOverrides = e.includeOverrides
    common.log:debug("Registering the following water containers:")
    for id, data in pairs(e.data) do
        assert(type(id) == "string", "Water container ID must be a string.")
        id = id:lower()

        if type(data) == "table" then
            --Table for manual values
            assert(data.capacity, "Water container data must include a capacity.")
            assert(type(data.capacity) == "number", "Capacity must be a number.")
            staticConfigs.bottleList[id] = {
                capacity = data.capacity,
                weight = data.weight,
                value = data.value,
                holdsStew = data.holdsStew
            }
            common.log:debug("    %s: { capacity: %d%s%s%s }",
                id,
                data.capacity,
                data.weight and string.format(", weight: %s", data.weight) or "",
                data.value and string.format(", weight: %s", data.value) or "",
                data.holdsStew and string.format(", holdsStew: %s", data.holdsStew) or ""
            )
        elseif type(data) == "number" then
            --Number for just setting a capacity
            staticConfigs.bottleList[id] = { capacity = data }
            common.log:debug("    %s: { capacity: %s }", id, data)
        elseif type(data) == "string" then
            --String for using existing bottle type
            local thisBottleConfig = staticConfigs.bottleConfig[data]

            assert(
                thisBottleConfig,
                string.format("%s is not a valid water container type. Valid types include: %s",
                    data, listValidWaterContainers())
            )

            staticConfigs.bottleList[id] = {
                capacity = thisBottleConfig.capacity,
                holdsStew = thisBottleConfig.holdsStew,
                value = includeOverrides and thisBottleConfig.value or nil,
                weight = includeOverrides and thisBottleConfig.weight or nil,
            }

            local finalConfig = staticConfigs.bottleList[id]
            common.log:debug("    %s: { capacity: %d%s%s }",
                id,
                finalConfig.capacity,
                finalConfig.weight and string.format(", weight: %s", finalConfig.weight) or "",
                finalConfig.value and string.format(", weight: %s", finalConfig.value) or "",
                finalConfig.holdsStew and string.format(", holdsStew: %s", finalConfig.holdsStew) or ""
            )
        end
    end
    return true
end
event.register("Ashfall:RegisterWaterContainers", registerWaterContainers)

local function registerFoods(e)
    common.log:debug("Registering the following food items: ")
    for id, foodType in pairs(e.data) do
        assert(type(id) == "string", "Water container ID must be a string.")
        assert(foodConfig.type[foodType], string.format("%s is not a valid food type. Valid types include: %s", foodType, listValidFoodTypes() ))

        foodConfig.addFood(id, foodType)
        common.log:debug("    %s: %s", id, foodType)
    end
    return true
end
event.register("Ashfall:RegisterFoods", registerFoods)

local function registerHeatSources(e)
    common.log:debug("Registering the following heat sources: ")
    for id, temp in pairs(e.data) do
        assert(type(id) == "string", "RegisterHeatSources: id must be a string")
        assert(type(temp) == "number", "RegisterHeatSources: temp value must be a number")
        staticConfigs.heatSourceValues[id:lower()] = temp
        common.log:debug("    %s: %s", id, temp)
    end
    return true
end
event.register("Ashfall:RegisterHeatSources", registerHeatSources)



local function registerTeas(e)
    for id, teaData in pairs(e.data) do
        assert(type(id) == 'string', "id must be a valid string")
        assert(type(teaData.teaName) == 'string', "teaData.teaName must be a string")
        assert(type(teaData.teaDescription) == 'string', "teaData.teaDescription must be a string")
        assert(type(teaData.effectDescription) == 'string', "teaData.effectDescription must be a string")
        local spell = teaData.spell
        if spell then
            assert(type(spell.id) == 'string', "spell id must be string")
            assert(type(spell.effects) == 'table', "Spell effects must be table")
        end
        teaConfig.teaTypes[id:lower()] = teaData
    end
    return true
end
event.register("Ashfall:RegisterTeas", registerTeas)

local function registerClothingOrArmor(id, warmth, objectType)
    ratingsConfig.warmth[objectType].values[id:lower()] = warmth
    return true
end


local function registerClothings(e)
    common.log:debug("Registering warmth values the following clothing: ")
    for id, warmth in pairs(e.data) do
        registerClothingOrArmor(id, warmth, "clothing")
        common.log:debug("   %s: %s", id, warmth)
    end
    return true
end

local function registerArmors(e)
    common.log:debug("Registering warmth values for the following armor: ")
    for id, warmth in pairs(e.data) do
        registerClothingOrArmor(id, warmth, "armor")
        common.log:debug("   %s: %s", id, warmth)
    end
    return true
end

local function registerClimates(e)
    common.log:debug("Registering climate data for the following regions: ")
    for id, data in pairs(e.data) do
        id = id:lower()
        if type(data) == 'table' then
            assert(data.min, "Missing min climate value.")
            assert(data.max, "Missing max climate value.")
            climateConfig.regions[id] = data
            common.log:debug("    %s: { min: %d, max: %d }", id, data.min, data.max)
        elseif type(data) == 'string' then
            local climateData = climateConfig.CLIMATE[data]
            assert(climateData, string.format("Invalid Climate type. Must be ones of the following: %s", listValidClimateTypes()))
            climateConfig.regions[id] = climateData
            common.log:debug("    %s: { min: %d, max: %d }", id, climateData.min, climateData.max)
        else
            mwse.error("Invalid climate data. Must be a table with min/max values, a string matching the following: " .. listValidClimateTypes())
        end
    end
    return true
end

local function registerWoodAxes(data)
    local woodAxeConfig = require("mer.ashfall.items.axe.config")
    assert(type(data) == 'table', "registerWoodAxes: data must be a table of axe ids")
    common.log:debug("Registering wood axes: ")
    for _, id in ipairs(data) do
        assert(type(id) == 'string', "registerWoodAxes: id must be a string")
        common.log:debug(id)
        woodAxeConfig.woodAxes[id:lower()] = true
    end
    return true
end



local Interop = {
    --Block or unblock hunger, thirst and sleep
    blockNeeds = function()
        if common.data then
            common.data.blockNeeds = true
            return true
        end
    end,
    unblockNeeds = function()
        if common.data then
            common.data.blockNeeds = false
            return true
        end
    end,
    --block or unblock sleep
    blockSleepLoss = function()
        if common.data then
            common.data.blockSleepLoss = true
            return true
        end
    end,
    unblockSleepLoss = function()
        if common.data then
            common.data.blockSleepLoss = false
            return true
        end
    end,
    --block or unblock hunger
    blockHunger = function()
        if common.data then
            common.data.blockHunger = true
            return true
        end
    end,
    unblockHunger = function()
        if common.data then
            common.data.blockHunger = false
            return true
        end
    end,
    --block or unblock thirst
    blockThirst = function()
        if common.data then
            common.data.blockThirst = true
            return true
        end
    end,
    unblockThirst = function()
        if common.data then
            common.data.blockThirst = false
            return true
        end
    end,
    --object registrations
    registerActivatorType = registerActivatorType,
    registerActivators = function(data, usePatterns)
        return registerActivators({ data = data, usePatterns = usePatterns})
    end,
    registerWaterSource = function(data)
        return registerWaterSource(data)
    end,

    registerWaterContainers = function(data, includeOverrides)
        return registerWaterContainers({ data = data, includeOverrides = includeOverrides })
    end,
    registerFoods = function(data)
        return registerFoods({ data = data })
    end,
    registerHeatSources = function(data)
        return registerHeatSources({data = data})
    end,
    registerTeas = function(data)
        registerTeas({ data = data })
    end,

    --Survival skill
    progressSurvivalSkill = function(amount)
        if common.skills.survival then
            common.skills.survival:progressSkill(amount)
            assert(type(amount) == 'number', "progressSurvivalSkill: amount must be a number")
            common.log:debug("Progressing skill by %s points", amount)
            return true
        end
    end,
    getSurvivalSkill = function()
        if common.skills.survival then
            local skillValue = common.skills.survival.value
            common.log:debug("getSurvivalSkill: Getting survival skill: %s", skillValue)
            return skillValue
        end
    end,
    --Weather
    registerClimates = function(data)
        return registerClimates({ data = data })
    end,

    getSunlight = function()
        return common.data and common.data.sunTemp or 0
    end,

    getSunlightNormalized = function()
        local normalisedSunlight = 0
        if common.data then
            normalisedSunlight = math.clamp( (common.data.sunTemp / common.staticConfigs.maxSunTemp), 0, 1)
        end
        return normalisedSunlight
    end,

    --Misc
    registerWoodAxes = function(data)
        return registerWoodAxes(data)
    end,

    registerTreeBranches = branchInterop.registerTreeBranches,

    --ratings, WIP, need to add support for ids

    -- registerClothingWarmth = function(data)
    --     return registerClothings({ data = data })
    -- end,
    -- registerArmorWarmth = function(data)
    --     return registerArmors({ data = data })
    -- end,

    registerOverrides = function(data)
        local success = true
        for id, override in pairs(data) do
            if type(override) == 'table' then
                --check override has a weight or value field
                assert(override.weight or override.value, "Override must have a weight or value field")
                common.log:debug("Registering override for %s", id)
                overrides[id] = override

            else
                mwse.log("Invalid override data. Must be a table.")
                success = false
            end
        end
        return success
    end
}


return Interop