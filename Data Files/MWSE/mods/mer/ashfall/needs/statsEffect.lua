local this = {}
local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config").config
local conditionConfig = common.staticConfigs.conditionConfig


local function getMaxHealth()
    local minHeath = common.data and config.needsCanKill and 0 or 1
    local multiplier = conditionConfig.hunger:getStatMultiplier()
    local maxHealth = tes3.mobilePlayer.health.base
    local limit = math.max( minHeath, math.floor( maxHealth * multiplier ) )
    return limit
end
local function getMaxMagicka()
    local minMagicka = 0
    local multiplier = conditionConfig.thirst:getStatMultiplier()
    local maxMagicka = tes3.mobilePlayer.magicka.base
    local limit = math.max(minMagicka, math.floor(maxMagicka * multiplier) )
    return limit
end
local function getMaxFatigue()
    local minFatigue = 0
    local multiplier = conditionConfig.tiredness:getStatMultiplier()
    local maxFatigue = tes3.mobilePlayer.fatigue.base
    return math.max(minFatigue, math.floor(maxFatigue * multiplier) )
end

local baseHealthCache
local function calcHealth()
    --Health, including rest until healed bullshit
    if baseHealthCache then
        tes3.setStatistic({
            reference = tes3.mobilePlayer,
            base = math.floor(baseHealthCache),
            name = "health"
        })
        baseHealthCache = nil
    else
        if not tes3.menuMode() then
            local fortifyEffect = tes3.getEffectMagnitude({
                reference = tes3.player,
                effect = tes3.effect.fortifyHealth,
            })
            local max =  getMaxHealth() + fortifyEffect
            if tes3.mobilePlayer.health.current > max then
                tes3.setStatistic({
                    reference = tes3.mobilePlayer,
                    current = max,
                    name = "health"
                })
                if tes3.mobilePlayer.health.current <= 0 then
                    if not common.data.diedOfHunger then
                        common.data.diedOfHunger = true
                        tes3.messageBox{ message = "You have died of hunger", buttons = { "Okay" } }
                    end
                end
            end
        end
    end
end

local function calcMagicka()
    local fortifyEffect = tes3.getEffectMagnitude({
        reference = tes3.player,
        effect = tes3.effect.fortifyMagicka,
    })
    local max = getMaxMagicka() + fortifyEffect
    if math.floor(tes3.mobilePlayer.magicka.current) > math.floor(max) then
        tes3.setStatistic({
            reference = tes3.mobilePlayer,
            current = max,
            name = "magicka"
        })
    end
end

local function calcFatigue()
    if not tes3ui.menuMode() then
        local fortifyEffect =  tes3.getEffectMagnitude({
            reference = tes3.player,
            effect = tes3.effect.fortifyFatigue,
        })
        local max = getMaxFatigue() + fortifyEffect
        if tes3.mobilePlayer.fatigue.current > max then
            tes3.setStatistic({
                reference = tes3.mobilePlayer,
                current = max,
                name = "fatigue"
            })
        end
    end
end

local function calcThirst()
    if config.needsCanKill then
        if conditionConfig.thirst:getValue() >= 100 then
            local isDead = tes3.mobilePlayer.health.current <= 0
            if isDead then
                tes3.setStatistic({
                    reference = tes3.mobilePlayer,
                    current = -1,
                    name = "health"
                })
                tes3.messageBox{ message = "You have died of thirst", buttons = { "Okay" } }
            end
        end
    end
end

local doInJail
local function turnOnNeeds()
    doInJail = false
    common.data.blockNeeds = false
end
local function checkJail()
    if tes3.mobilePlayer.inJail and not doInJail then
        doInJail = true
        common.data.blockNeeds = true
        timer.start{
            type = timer.real,
            duration = 1,
            callback = turnOnNeeds
        }
    end
end

function this.calculate()
    calcHealth()
    calcMagicka()
    calcFatigue()
    calcThirst()
    checkJail()
end

function this.getMaxStat(stat)
    if stat == "health" then return getMaxHealth() end
    if stat == "magicka" then return getMaxMagicka() end
    if stat == "fatigue" then return getMaxFatigue() end
end

--For "Rest until healed", we need to set base to max while resting
local function enterRestMenu()
    local maxHealth = getMaxHealth()
    baseHealthCache = tes3.mobilePlayer.health.base
    tes3.setStatistic({
        reference = tes3.mobilePlayer,
        base = math.floor(maxHealth),
        name = "health"
    })
end
event.register("uiActivated", enterRestMenu, { filter = "MenuRestWait"})

return this