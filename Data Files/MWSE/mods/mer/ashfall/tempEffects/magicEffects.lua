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

--multiplier at 100% resist
local maxEffect = 0.75


function this.calculateMagicEffects()


    --Frost Resist - Reduces cold temps
    
    local resistFrost = ( tes3.mobilePlayer.resistFrost or 0 )

    resistFrost = math.remap(math.clamp(resistFrost, 0, 100), 0, 100, 1 ,maxEffect)
    common.data.resistFrostEffect = resistFrost

    --Fire Resist - Reduces hot temps
    local resistFire = ( tes3.mobilePlayer.resistFire or 0 )
    resistFire = math.remap(math.clamp(resistFire, 0, 100), 0, 100, 1, maxEffect)
    common.data.resistFireEffect = resistFire

end


--TODO: Fire and Frost Damage
local function calculateDamageTemp(e)

    --if e.target ~= tes3.player then return end
    if e.effectId == tes3.effect.fireDamage then

    elseif e.effectId == tes3.effect.frostDamage then
        tes3.messageBox("Frost dam: %s", (e.effect.magnitude))
        --common.log:info("Frost dam: %s", (e.effect.magnitude))
    end
end

--event.register("spellTick", calculateDamageTemp)

return this
