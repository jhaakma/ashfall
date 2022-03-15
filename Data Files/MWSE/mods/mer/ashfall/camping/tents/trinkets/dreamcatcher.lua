local common = require("mer.ashfall.common.common")
local logger = common.createLogger("dreamcatcher")
local function activateDreamCatcher()
    logger:debug("activate dreamcatcher")
    common.data.dreamcatcherActive = true
end
event.register("Ashfall:ActivateDreamCatcher", activateDreamCatcher)

local function deactivateDreamCatcher()
    logger:debug("deactivate dreamcatcher")
    common.data.dreamcatcherActive = nil
end
event.register("Ashfall:DeactivateDreamCatcher", deactivateDreamCatcher)

local lastTime
local function doDreamCatcherEffect(e)
    if not tes3.player then return end

    local hoursPassed = common.helper.getHoursPassed()
    lastTime = lastTime or hoursPassed
    local interval = math.abs(hoursPassed - lastTime)
    interval = math.min(interval, 8.0)
    lastTime = hoursPassed
    --filters
    if not common.data.dreamcatcherActive then return end
    if tes3.isAffectedBy{ reference = tes3.player, effect = tes3.effect.stuntedMagicka} then return end
    --Add Magicka
    logger:trace("Adding magicka recovery")
    logger:trace("delta: %s", interval)
    local intelligence = math.clamp(tes3.mobilePlayer.intelligence.base, 0, 100)
    local fRestMagicMult = tes3.findGMST(tes3.gmst.fRestMagicMult).value
    local recoveryPerHour = fRestMagicMult * intelligence
    local magickaRecovery = recoveryPerHour * interval
    local remaining = math.max(tes3.mobilePlayer.magicka.base - tes3.mobilePlayer.magicka.current, 0)
    magickaRecovery = math.min(magickaRecovery, remaining)
    logger:trace("recoveryPerHour: %s", recoveryPerHour)
    logger:trace("magickaRecovery: %s", magickaRecovery)
    tes3.modStatistic{ reference = tes3.player, name = "magicka", current = magickaRecovery }
end
event.register("enterFrame", doDreamCatcherEffect)