local common = require("mer.ashfall.common.common")
local logger = common.createLogger("ClayGlazeMenu")
local CraftingFramework = require("CraftingFramework")

---Class for managing the Glaze selection menu, using Crafting Framework
---@class Ashfall.Clay.GlazeMenu
local GlazeMenu = {}

local menuActivator = CraftingFramework.MenuActivator:new{
    id = "Ashfall:ClayGlazeMenuActivator",
    type = "event",
    name = "Select Clay Glaze",
    recipes = {}
}

return GlazeMenu