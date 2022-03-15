local common = require("mer.ashfall.common.common")
local logger = common.createLogger("chimes")
local function activateWindChimes()
    logger:debug("activate wind chimes")
    common.data.windChimesActive = true
end
event.register("Ashfall:ActivateWindChimes", activateWindChimes)

local function deactivateWindChimes()
    logger:debug("deactivate wind chimes")
    common.data.windChimesActive = nil
end
event.register("Ashfall:DeactivateWindChimes", deactivateWindChimes)

local lastTime
local function doWindChimesEffect(e)
    if not tes3.player then return end

    local hoursPassed = common.helper.getHoursPassed()
    lastTime = lastTime or hoursPassed
    local interval = math.abs(hoursPassed - lastTime)
    interval = math.min(interval, 8.0)
    lastTime = hoursPassed
    --filters
    if not common.data.windChimesActive then return end
    --Add Health Regen
    logger:trace("Adding health recovery")
    logger:trace("interval: %s", interval)
    local endurance = math.clamp(tes3.mobilePlayer.endurance.base, 0, 100)
    local recoveryPerHour = 0.1 * endurance
    local healthRecovery = recoveryPerHour * interval
    local remaining = math.max(tes3.mobilePlayer.health.base - tes3.mobilePlayer.health.current, 0)
    healthRecovery = math.min(healthRecovery, remaining)
    logger:trace("recoveryPerHour: %s", recoveryPerHour)
    logger:trace("healthRecovery: %s", healthRecovery)
    tes3.modStatistic{ reference = tes3.player, name = "health", current = healthRecovery }
end
event.register("enterFrame", doWindChimesEffect)