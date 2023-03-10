---@class Ashfall.Harvest.WeaponData
---@field effectiveness number
---@field degradeMulti number

---@class Ashfall.Harvest.Config.Harvestable
---@field id string
---@field count number
---@field chance number

---@class Ashfall.Harvest.Config.DestructionLimitConfig
---@field min number
---@field max number
---@field minHeight number
---@field maxHeight number

---@class Ashfall.Harvest.Config
---@field name string Name needed for error message when harvesting is illegal
---@field weaponTypes table<number, Ashfall.Harvest.WeaponData> Key: tes3.weaponType
---@field weaponIds table<number, Ashfall.Harvest.WeaponData> Key: tes3.weaponType
---@field weaponNamePatterns table<string, Ashfall.Harvest.WeaponData> Key: String pattern to search in object name
---@field requirements function (weapon: tes3equipmentStack) -> boolean Returns true if the weapon meets the requirements
---@field items Ashfall.Harvest.Config.Harvestable[] Array of harvestables
---@field sound string
---@field swingsNeeded number
---@field destructionLimitConfig Ashfall.Harvest.Config.DestructionLimitConfig The min/max that can be harvested before being destroyed
---@field fallSound string The sound to play when the harvestable is destroyed
---@field clutter table<string, boolean> A list of clutter items that are destroyed alongside this harvestable.
---@field dropLoot boolean If set, any items sitting on top of the reference will be "dropped" to the ground
