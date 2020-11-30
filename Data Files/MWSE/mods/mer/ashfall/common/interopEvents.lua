
local common = require("mer.ashfall.common.common")
local staticConfigs = common.staticConfigs
local activatorConfig = staticConfigs.activatorConfig
local foodConfig = staticConfigs.foodConfig

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


event.register("Ashfall:RegisterActivators", function(e)
    --[[
        Example:
        event.trigger("Ashfall:RegisterActivators", {
            my_Well_id_01 = "well"
        })
    ]]
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
    --Register a logger to event to check if they registered properly
    event.trigger("Ashfall:ActivatorsRegistered", { ids = e.ids})
end)


event.register("Ashfall:RegisterWaterContainers", function(e)
    --[[
        Example:
        event.trigger("Ashfall:RegisterWaterContainers", {

            --set values to what other vanilla cups are set to
            my_bottle_02: "cup", 

            --set capacity to 25
            my_bottle_03: 25 

            --set values manually
            my_bottle_01: {
                capacity = 25, --required
                weight = 2, --optional
                value = 10 --optional
            },

        })
    ]]
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
                value = data.value
            }
            common.log:debug("    %s: { capacity: %d%s%s }",
                data.capacity, 
                data.weight and (", weight: " .. data.weight) or "",
                data.value and (", weight: " .. data.value) or ""
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

            staticConfigs.bottleList[id] = thisBottleConfig
            
            common.log:debug("    %s: { capacity: %d%s%s }",
                id,
                thisBottleConfig.capacity, 
                thisBottleConfig.weight and (", weight: " .. thisBottleConfig.weight) or "",
                thisBottleConfig.value and (", weight: " .. thisBottleConfig.value) or ""
            )
        end
    end
end)

event.register("Ashfall:RegisterFoods", function(e)
    --[[
        Example:
        event.trigger("Ashfall:RegisterFoods", {
            myFoodId_01 = "meat",
            myFoodId_02 = "meat",
            myFoodId_03 = "vegetable",
            myFoodId_04 = "mushroom",
        })
    ]]

    common.log:debug("Registering the following food items: ")
    for id, foodType in pairs(e.data) do
        assert(type(id) == "string", "Water container ID must be a string.")
        assert(foodConfig.type[foodType], "%s is not a valid food type. Valid types include: " .. listValidFoodTypes())

        foodConfig.addFood(id, foodType)
        common.log:debug("    %s: %s", id, foodType)
    end
end)

event.register("Ashfall:RegisterHeatSources", function(e)
    --[[
        event.trigger("Ashfall:RegisterHeatSources", { data = {
            myHeatSourceId = 50
        }})
    ]]
    common.log:debug("Registering the following heat sources: ")
    for id, temp in pairs(e.data) do
        assert(type(id) == "string", "RegisterHeatSources: id must be a string")
        assert(type(temp) == "number", "RegisterHeatSources: temp value must be a number")
        staticConfigs.heatSourceValues[id:lower()] = temp
        common.log:debug("    %s: %s", id, temp)
    end
end)

-- local function registerTeas(e)
--     for _, teaData in ipairs(e) do
--         assert()

--     end
-- end
-- event.register("Ashfall:RegisterTeas", registerTeas)

event.trigger("Ashfall:Interop")