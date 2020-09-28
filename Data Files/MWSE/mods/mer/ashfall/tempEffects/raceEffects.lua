--[[
    Race effects
    Check if the player is a Khajiit or Werewolf
]]--
local common = require("mer.ashfall.common.common")
local this = {}


--Register heat source
local temperatureController = require("mer.ashfall.temperatureController")
temperatureController.registerBaseTempMultiplier{ id = "vampireColdEffect", coldOnly = true }
temperatureController.registerBaseTempMultiplier{ id = "vampireWarmEffect", warmOnly = true }
temperatureController.registerInternalHeatSource{ id = "furTemp", warmOnly = true }

local werewolfWarmth = 30
local khajiitWarmth = 15
local vampireColdMultiplier = 0.1
local vampireWarmMultiplier = 1.3

function this.calculateRaceEffects()

    common.data.furTemp = 0
    local raceID = tes3.player.object.baseObject.race.id
    if string.lower(raceID) == "khajiit" then
        common.data.furTemp = khajiitWarmth
    end

    --being werewolf overrides khajiit
    
    if tes3.mobilePlayer.werewolf then
        common.data.furTemp = werewolfWarmth
    end

    local PCVampire = tes3.findGlobal("PCVampire").value
    if PCVampire == 1 then
        common.data.vampireColdEffect = vampireColdMultiplier
        common.data.vampireWarmEffect = vampireWarmMultiplier
    else
        common.data.vampireColdEffect = 1
        common.data.vampireWarmEffect = 1
    end

end
return this