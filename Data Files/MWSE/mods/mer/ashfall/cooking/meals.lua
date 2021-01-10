local Meal = require ("mer.ashfall.objects.Meal")

return {
    crabmeatSoup = Meal:new{
        id = "ashfall_crab_soup",
        spellId = "ashfall_meal_crabSoup",
    },

    stoneflowerTea = Meal:new{
        id = "food_kwama_egg_01",
        spellId= "ashfall_meal_stoneTea",
        duration = 3,
    }
}