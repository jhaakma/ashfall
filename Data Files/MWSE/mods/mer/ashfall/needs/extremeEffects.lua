--[[
    Deal with when your needs are at extreme levels. Passing out from exhaustion etc
    Doesn't deal with hunger because you just die. 
]]
local common = require("mer.ashfall.common.common")
local thirst = common.staticConfigs.conditionConfig.thirst
local tiredness = common.staticConfigs.conditionConfig.tiredness

--Tired
local passedOut
local function passOut()
    common.log:debug("extremeEffects - Passing out")
    local hours = 2.5 + math.random(0.5)
    local secondsTaken = 5
    local function wakeUp(e)
        common.log:debug("extremeEffects - Waking up")
        tiredness:setValue(65)
        tes3.setStatistic{
            reference = tes3.mobilePlayer,
            current = 50,
            name = "fatigue"
        }
        --common.data.blockNeeds = false
        passedOut = false
        tes3.messageBox{
            message = "You passed out from exhaustion", 
            buttons = {"Okay"}
        }
    end
    common.helper.fadeTimeOut(hours, secondsTaken, wakeUp)
end
local function checkTired()
    --Sleep
    local isPassedOut = (
        common.config.getConfig().enableTiredness and
        tiredness:getValue() >= 100 and 
        tes3.mobilePlayer.fatigue.current <= 0  and 
        passedOut ~= true
    )
    if isPassedOut then
        common.log:debug("extremeEffects - passing out in 2 seconds")
        passedOut = true
        --common.data.blockNeeds = true
        tes3.setStatistic({
            reference = tes3.mobilePlayer,
            current = -1,
            name = "fatigue"
        })
        timer.start{
            duration = 2,
            callback = passOut
        }
    end
end

--Heat
local function checkHot()
    local temp = common.staticConfigs.conditionConfig.temp
    if temp:getCurrentState() == "scorching" then

    end
end

 


local function checkStats()
    checkTired()
    checkHot()
end
event.register("simulate", checkStats)


--Thirst
local function applyThirstDamage()
    local doDamage = (
        not tes3.menuMode() and 
        common.config.getConfig().enableThirst and
        tes3.mobilePlayer.health.current > 0 and 
        thirst:getValue() >= thirst.max and
        common.config.getConfig().needsCanKill == true and
        common.data.blockForFade ~= true
    )
    if doDamage then
        local damage = math.max(1, tes3.mobilePlayer.health.current / 10)
        tes3.mobilePlayer:applyHealthDamage(damage)
        tes3.messageBox("You are dying of thirst!")
    end
end
event.register("loaded", function()
    timer.start{
        callback = applyThirstDamage,
        type = timer.real,
        duration = 5,
        iterations = -1
    }
end)

