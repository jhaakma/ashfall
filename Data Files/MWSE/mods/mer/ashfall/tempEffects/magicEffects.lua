--[[
    Calculates temperature effects of magic resistances
    resist calculations called periodically by script timer
    fire/frost damage calculated on spellTicks
]]--

local this = {}
local common = require("mer.ashfall.common.common")

--Register temp effect
local temperatureController = require("mer.ashfall.temperatureController")
temperatureController.registerBaseTempMultiplier{ id = "resistFrostEffect", coldOnly = true }
temperatureController.registerBaseTempMultiplier{ id = "resistFireEffect", warmOnly = true }
temperatureController.registerInternalHeatSource{ id = "frostDamageEffect" }
temperatureController.registerInternalHeatSource{ id = "fireDamageEffect" }

--multiplier at 100% resist
local maxEffect = 0.75
local recoverSpeed = 50
function this.calculateMagicEffects(interval)
    --Frost Resist - Reduces cold temps

    local resistFrost = ( tes3.mobilePlayer.resistFrost or 0 )

    resistFrost = math.remap(math.clamp(resistFrost, 0, 100), 0, 100, 1 ,maxEffect)
    common.data.resistFrostEffect = resistFrost

    --Fire Resist - Reduces hot temps
    local resistFire = ( tes3.mobilePlayer.resistFire or 0 )
    resistFire = math.remap(math.clamp(resistFire, 0, 100), 0, 100, 1, maxEffect)
    common.data.resistFireEffect = resistFire


    --cool down fire/frostdamage
    common.data.fireDamageEffect = common.data.fireDamageEffect or 0
    common.data.fireDamageEffect = common.data.fireDamageEffect +
    ((0 - common.data.fireDamageEffect) * math.min(1, (interval * recoverSpeed)))

    common.data.frostDamageEffect = common.data.frostDamageEffect or 0
    common.data.frostDamageEffect = common.data.frostDamageEffect +
    ((0 - common.data.frostDamageEffect) * math.min(1, (interval * recoverSpeed)))
end

--Fire and Frost damage
local spellDamageEffectMulti = 20
local function calculateDamageTemp(e)
    if not common.data then return end
    if e.target ~= tes3.player then return end

    if e.effectId == tes3.effect.fireDamage or e.effectId == tes3.effect.frostDamage then
        common.log:trace("spell magnitude = %.4f", e.effectInstance.magnitude)
        common.log:trace("e.effectInstance.resistedPercent: %s", e.effectInstance.resistedPercent)
        local damageTemp = 0
        if e.effectInstance.state == tes3.spellState.working then
            damageTemp = e.effectInstance.magnitude
                * (1 - e.effectInstance.resistedPercent/100)
                * spellDamageEffectMulti
            damageTemp = math.clamp(damageTemp, 0, 100)

            common.log:trace("damageTemp: %s", damageTemp)

            if e.effectId == tes3.effect.fireDamage then
                common.data.fireDamageEffect = common.data.fireDamageEffect or 0
                common.data.fireDamageEffect = common.data.fireDamageEffect +
                ((damageTemp - common.data.fireDamageEffect) * math.min(1, e.deltaTime))
                common.log:trace("common.data.fireDamageEffect: %s", common.data.fireDamageEffect)
            elseif e.effectId == tes3.effect.frostDamage then
                damageTemp = -damageTemp --because its cold
                common.data.frostDamageEffect = common.data.frostDamageEffect or 0
                common.data.frostDamageEffect = common.data.frostDamageEffect +
                ((damageTemp - common.data.frostDamageEffect) * math.min(1, e.deltaTime))
            end
        end
    end
end
event.register("spellTick", calculateDamageTemp)



return this
