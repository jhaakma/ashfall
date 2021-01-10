local common = require("mer.ashfall.cooking.common")
local Utensil = require("mer.ashfall.objects.Utensil")
return {
    cookingPot = Utensil:new{
        id = "ashfall_cookingpot",
        name = "Cooking Pot",
        recipeType = common.recipeType.boiled
    },
    grill = Utensil:new{
        id = "grill",
        name = "Grill",
        recipeType = common.recipeType.roasted
    },
    teapot = Utensil:new{
        id = "teapot_01",
        name = "Teapot",
        recipeType = common.recipeType.brewed
    }
} 