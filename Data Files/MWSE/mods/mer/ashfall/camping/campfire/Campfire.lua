local common = require("mer.ashfall.common.common")
local logger = common.createLogger("Campfire")
local Activator = require("mer.ashfall.activators.Activator")
---Hopefully the beginning of a unified class for campfire logic
---@exact
---@class Ashfall.Campfire : Ashfall.Campfire.CampfireData
---@field name string (Default: "Campfire") The name of the campfire
---@field maxFuel number (Default: 16) The maximum fuel level the kiln can hold
---@field heatMultiplier number (Default: 1.0) Multiplier on the heat produced at a given fuel level
---@field damageChanceMultiplier number (Default: 1.0) Multiplier on the chance of pottery damage occurring during firing
---@field fuelBurnMultiplier number (Default: 1.0) Multiplier on the rate of fuel consumption
local Campfire = {
    registeredCampfires = {},
    defaults = {
        name = "Campfire",
        maxFuel = 14,
        heatMultiplier = 1.0,
        damageChanceMultiplier = 1.0,
        fuelBurnMultiplier = 1.0,
    },
    ---Unified stages configuration with minTemp, name, and color
    ---Stages are ordered from lowest to highest temperature
    ---@type table<Ashfall.Campfire.FiringStage, Ashfall.Campfire.STAGE>
    STAGES = {
        cooking = {
            minTemp = 1,
            name = "Cooking",
            color = {1.0, 0.4, 0.0}
        },
        firing = {
            minTemp = 15,
            name = "Firing",
            color = {1.0, 0.3, 0.3}
        },
        glazing = {
            minTemp = 25,
            name = "Glazing",
            color = {1.0, 0.5, 0.8}
        },
    },
}

---@alias Ashfall.Campfire.FiringStage
---| "cooking"
---| "firing"
---| "glazing"

---@class Ashfall.Campfire.STAGE
---@field minTemp number Minimum temperature for this stage
---@field name string Name of the stage
---@field color number[] RGB color associated with the stage

---@type Ashfall.Campfire.STAGE[]
Campfire.ORDERED_STAGES = {
    Campfire.STAGES.cooking,
    Campfire.STAGES.firing,
    Campfire.STAGES.glazing,
}

---@class Ashfall.Campfire.CampfireData
---@field id string The object ID of the campfire
---@field name nil|string (Default: "Campfire") The name of the campfire
---@field maxFuel nil|number (Default: 16) The maximum fuel level the kiln can hold
---@field heatMultiplier nil|number (Default: 1.0) Multiplier on the heat produced at a given fuel level
---@field damageChanceMultiplier nil|number (Default: 1.0) Multiplier on the chance of pottery damage occurring during firing
---@field fuelBurnMultiplier nil|number (Default: 1.0) Multiplier on the rate of fuel consumption


---Register a new campfire
---@param campfireData Ashfall.Campfire.CampfireData
---@return Ashfall.Campfire
function Campfire.registerCampfire(campfireData)
    logger:assert(type(campfireData.id) == "string", "Campfire must have an id")
    local campfire = table.copy(campfireData)
    table.copymissing(campfire, Campfire.defaults)
    Campfire.registeredCampfires[campfireData.id:lower()] = campfire
    setmetatable(campfire, { __index = Campfire })

    ---@cast campfire Ashfall.Campfire

    if not Activator.get("campfire") then
        Activator:new{
            id = campfire.id,
            type = "campfire",
            name = campfire.name,
        }
    end

    Activator.get("campfire"):addId(campfireData.id)
    logger:debug("Registered campfire: %s", campfire.id)

    return campfire
end


---Check if an object id is a registered campfire
---@param id string The object id to check
---@return boolean
function Campfire.isCampfire(id)
    return Campfire.registeredCampfires[id:lower()] ~= nil
end


---Get kiln data for an object id
---@param id string The object id to check
---@return Ashfall.Campfire|nil
function Campfire.getCampfire(id)
    return Campfire.registeredCampfires[id:lower()]
end

---Get the max fuel level for a campfire
---@param id string The object id
---@return number maxFuel
function Campfire.getMaxFuel(id)
    local campfireData = Campfire.getCampfire(id)
    if campfireData then
        return campfireData.maxFuel
    else
        return Campfire.defaults.maxFuel
    end
end

---Get the fuel burn multiplier for a campfire
---@param id string The object id
---@return number fuelBurnMultiplier
function Campfire.getFuelBurnMultiplier(id)
    local campfireData = Campfire.getCampfire(id)
    if campfireData then
        return campfireData.fuelBurnMultiplier
    else
        return Campfire.defaults.fuelBurnMultiplier
    end
end

---Get the damage chance multiplier for a campfire
---@param id string The object id
---@return number damageChanceMultiplier
function Campfire.getDamageChanceMultiplier(id)
    local campfireData = Campfire.getCampfire(id)
    if campfireData then
        return campfireData.damageChanceMultiplier
    else
        return Campfire.defaults.damageChanceMultiplier
    end
end

---Get the heat multiplier for a campfire
---@param id string The object id
---@return number heatMultiplier
function Campfire.getHeatMultiplier(id)
    local campfireData = Campfire.getCampfire(id)
    if campfireData then
        return campfireData.heatMultiplier
    else
        return Campfire.defaults.heatMultiplier
    end
end


function Campfire.canDisassemble(reference)
    return reference and reference.supportsLuaData
        and reference.data.materialsUsed ~= nil
end

---Get the stage for the given heat
---@param heat number The current heat level
---@return Ashfall.Campfire.STAGE?
function Campfire.getStageForHeat(heat)
    local currentStage
    for _, stage in ipairs(Campfire.ORDERED_STAGES) do
        if heat >= stage.minTemp then
            currentStage = stage
        else
            break
        end
    end
    return currentStage
end

---Check if heat is at or above a specific stage
---@param heat number The current heat level
---@param stage Ashfall.Campfire.STAGE The stage to compare against
---@return boolean
function Campfire.isHeatAtOrAboveStage(heat, stage)
    return heat >= stage.minTemp
end

---Check if heat is below a specific stage
---@param heat number The current heat level
---@param stage Ashfall.Campfire.STAGE The stage to compare against
---@return boolean
function Campfire.isHeatBelowStage(heat, stage)
    return heat < stage.minTemp
end

---Get the order/index of a stage (1-based)
---@param stage Ashfall.Campfire.STAGE The stage to find
---@return number? The 1-based index, or nil if not found
function Campfire.getStageOrder(stage)
    for i, s in ipairs(Campfire.ORDERED_STAGES) do
        if s == stage then
            return i
        end
    end
    return nil
end

---Check if one stage is higher than another
---@param stage1 Ashfall.Campfire.STAGE First stage
---@param stage2 Ashfall.Campfire.STAGE Second stage
---@return boolean True if stage1 is higher than stage2
function Campfire.isStageHigherThan(stage1, stage2)
    local order1 = Campfire.getStageOrder(stage1)
    local order2 = Campfire.getStageOrder(stage2)
    if not order1 or not order2 then return false end
    return order1 > order2
end

return Campfire