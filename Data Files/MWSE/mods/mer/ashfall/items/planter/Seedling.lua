local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.items.planter.config")

---@class Ashfall.Seedling
---@field ingredient tes3ingredient
---@field plant tes3container
---@field logger MWSELogger
---@field plantContainers tes3container[] A list of all containers that have leveled items containing this seedling.
---@field seedlingPlantMap table<tes3ingredient, tes3container[]> A map of all seedlings to all containers that have them.
local Seedling = {
    seedlingPlantMap = {}
}

Seedling.__tostring = function(self)
    return string.format("Seedling(%s)", self.ingredient.id)
end

---Constructor
---@param ingredient tes3ingredient|tes3item
---@return Ashfall.Seedling|nil
function Seedling:new(ingredient)
    if not Seedling.seedlingPlantMap[ingredient] then
        return nil
    end
    local seedling = {
        ingredient = ingredient,
        logger = common.createLogger("Seedling(" .. ingredient.id .. ")"),
        plantContainers = Seedling.seedlingPlantMap[ingredient]
    }
    setmetatable(seedling, self)
    self.__index = self
    return seedling
end

---@return boolean
function Seedling.isSeedling(ingredient)
    return Seedling.seedlingPlantMap[ingredient] ~= nil
end

--Pick a random container from the list of plant containers for this seedling.
---@return tes3container
function Seedling:pickPlant()
    self.plant = table.choice(self.plantContainers)
    return self.plant
end



return Seedling