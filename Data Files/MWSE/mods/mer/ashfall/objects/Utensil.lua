--[[
    Utensil is a CampFirePart that is used for cooking.
]]--
local common = require("mer.ashfall.cooking.common")

local Parent = require("mer.ashfall.objects.CampFirePart")

local Utensil = Parent:new()
Utensil.recipeType = common.recipeType.prepared

return Utensil
