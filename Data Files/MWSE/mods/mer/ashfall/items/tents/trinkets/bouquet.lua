local common = require("mer.ashfall.common.common")
local logger = common.createLogger("bouquet")
local statsEffect = require("mer.ashfall.needs.statsEffect")
local function activateBouquet()
    logger:debug("activate bouquet")
    common.data.bouquetActive = true
end
event.register("Ashfall:ActivateBouquet", activateBouquet)

local function deactivateBouquet()
    logger:debug("deactivate bouquet")
    common.data.bouquetActive = nil
end
event.register("Ashfall:DeactivateBouquet", deactivateBouquet)

local lastTime
local function doBouquetEffect(e)
    if not tes3.player then return end
    --get interval
    local hoursPassed = common.helper.getHoursPassed()
    lastTime = lastTime or hoursPassed
    local interval = math.abs(hoursPassed - lastTime)
    interval = math.min(interval, 8.0)
    lastTime = hoursPassed

    --filters
    if not common.data.bouquetActive then return end
    --Add Fatigue Regen
    logger:trace("Adding fatigue recovery")
    logger:trace("interval: %s", interval)
    --[[
        from openmw research
        x = fFatigueReturnBase + fFatigueReturnMult * (1 - normalizedEncumbrance)
        x *= fEndFatigueMult * endurance
        fatigue += 3600 * x
    ]]
    local endurance = math.clamp(tes3.mobilePlayer.endurance.base, 0, 100)
    local normalizedEncumbrance = tes3.mobilePlayer.encumbrance.normalized
    local fFatigueReturnBase = tes3.findGMST(tes3.gmst.fFatigueReturnBase).value
    local fEndFatigueMult = tes3.findGMST(tes3.gmst.fEndFatigueMult).value
    local fFatigueReturnMult = tes3.findGMST(tes3.gmst.fFatigueReturnMult).value

    local x = fFatigueReturnBase + fFatigueReturnMult * (1 - normalizedEncumbrance)
    x = x * fEndFatigueMult * endurance
    local recoveryPerHour = x * 600
    logger:trace("recoveryPerHour: %s", recoveryPerHour)
    local fatigueRecovery = recoveryPerHour * interval
    logger:trace("fatigueRecovery: %s", fatigueRecovery)
    local remaining = math.max(statsEffect.getMaxStat("fatigue") - tes3.mobilePlayer.fatigue.current, 0)
    logger:trace("remaining: %s", remaining)
    fatigueRecovery = math.min(fatigueRecovery, remaining)
    logger:trace("clamped fatigueRecovery: %s", fatigueRecovery)
    tes3.modStatistic{ reference = tes3.player, name = "fatigue", current = fatigueRecovery }
end
event.register("enterFrame", doBouquetEffect)