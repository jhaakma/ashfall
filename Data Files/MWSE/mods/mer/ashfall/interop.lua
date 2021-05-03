
local common = require("mer.ashfall.common.common")
local staticConfigs = common.staticConfigs
local activatorConfig = staticConfigs.activatorConfig
local foodConfig = staticConfigs.foodConfig
local ratingsConfig = require('mer.ashfall.tempEffects.ratings.ratingsConfig')
local climateConfig = require('mer.ashfall.config.weatherRegionConfig')
local teaConfig = require('mer.ashfall.config.teaConfig')

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
        teaConfig.teaTypes[id] = {
            teaName = teaData.teaName,
            teaDescription = teaData.teaDescription,
            effectDescription = teaData.effectDescription,
            priceMultiplier = teaData.priceMultiplier or 5.0,
            onCallBack = teaData.onCallBack,
            spell = teaData.spell,
        }
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
    assert(type(data) == 'table', "registerWoodAxes: data must be a table of axe ids")
    common.log:debug("Registering wood axes: ")
    for _, id in ipairs(data) do
        assert(type(id) == 'string', "registerWoodAxes: id must be a string")
        common.log:debug(id)
        staticConfigs.woodAxes[id:lower()] = true
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
    registerActivators = function(data, usePatterns)
        return registerActivators({ data = data, usePatterns = usePatterns})
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

    registerWoodAxes = function(data)
        return registerWoodAxes(data)
    end,

    --ratings, WIP, need to add support for ids

    -- registerClothingWarmth = function(data)
    --     return registerClothings({ data = data })
    -- end,
    -- registerArmorWarmth = function(data)
    --     return registerArmors({ data = data })
    -- end,
}

return Interop