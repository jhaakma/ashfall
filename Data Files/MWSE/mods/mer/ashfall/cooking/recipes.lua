local common = require("mer.ashfall.cooking.common")
local meals = require("mer.ashfall.cooking.meals")
local Recipe = require("mer.ashfall.objects.Recipe")
local this = {}

this[common.recipeType.boiled] = {
    Recipe:new{
        id = "crabmeatSoup",
        name = "Crab Soup",
        meal = meals.crabmeatSoup,
        duration = 15,
        description = (
            "Crab Soup is a popular dish from Gnaar Mok, " ..
            "made of local mushrooms and fresh crab meat, boiled in a pot. "
        ),
        ingredients = {
            { 
                name = "Crab Meat", 
                count = 2,
                ids = {"ingred_crab_meat_01"}, 
            },
            { 
                name = "Mushrooms", 
                count = 2,
                ids = {
                    "ingred_bc_hypha_facia",
                    "ingred_bc_bungler's_bane",
                    "ingred_russula_01",
                    "ingred_coprinus_01"
                },
            },
        }, 
    },
    Recipe:new{
        id = "stoneflowerTea",
        name = "Stoneflower Tea",
        meal = meals.stoneflowerTea,
        duration = 10,
        description = (
            "A delicious herbal tea made from Stoneflower petals"
        ),
        ingredients = {
            {
                name = "Stoneflower petals",
                count = 4,
                ids = { "ingred_stoneflower_petals_01" }
            },
        },
    },
}

this[common.recipeType.brewed] = {
    Recipe:new{
        id = "stoneflowerTea",
        name = "Stoneflower Tea",
        meal = meals.stoneflowerTea,
        duration = 10,
        description = (
            "A delicious herbal tea made from Stoneflower petals"
        ),
        ingredients = {
            {
                name = "Stoneflower petals",
                count = 4,
                ids = { "ingred_stoneflower_petals_01" }
            },
        },
    },
}

return this