---@class Ashfall.SkillConfigs
local SkillConfigs = {}

SkillConfigs.survival = {
    exposure = {
        --- The max multiplier applied to tempature when survival skill is max
        temperatureEffectMax = 0.7,
        --- Skill increase per hour in each weather type
        ---@type table<tes3weather, number>
        weathers = {
            [tes3.weather.rain] = 1,
            [tes3.weather.thunder] = 2,
            [tes3.weather.snow] = 3,
            [tes3.weather.ash] = 3,
            [tes3.weather.blight] = 4,
            [tes3.weather.blizzard] = 4
        },
        --- Skill increase per hour when exposed to fire
        fire = {
            min = 0.5,
            max = 3
        },
        --- Skill increase per hour when soaking wet
        water = {
            max = 3
        },
    },
    brewTea = {
        skillGain = 2
    },
    lightFire = {
        skillGain = 2
    },
    stew = {
        gainPerIngredient = 2
    },
    grill = {
        skillGain = 2
    },
    harvest = {
        gainPerSwing = 1
    }
}

return SkillConfigs