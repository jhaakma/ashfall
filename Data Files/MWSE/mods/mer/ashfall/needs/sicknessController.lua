local this = {}
local common = require("mer.ashfall.common.common")
local foodPoison = common.staticConfigs.conditionConfig.foodPoison
local dysentery = common.staticConfigs.conditionConfig.dysentery
local blightness = common.staticConfigs.conditionConfig.blightness
local flu = common.staticConfigs.conditionConfig.flu

local drainRateHealthy = 200
local drainRateSick = 3

local blightGainRate = 200
local blightDrainRate = 100

local fluIncreaseRate = 300
local fluDecreaseRate = 200


local function calculateFoodPoison(scriptInterval)
    local drainRate
    if foodPoison:getCurrentState() == foodPoison.default then
        common.log:trace("calculateFoodPoison using healthy rate")
        drainRate = drainRateHealthy
    else
        common.log:trace("calculateFoodPoison using sick rate")
        drainRate = drainRateSick
    end 

    local newVal = foodPoison:getValue() - ( scriptInterval * drainRate)
    foodPoison:setValue(newVal)
    common.log:trace("new food poison value: %.f", newVal)
end

local function calculateDysentry(scriptInterval)
    local drainRate
    if dysentery:getCurrentState() == dysentery.default then
        common.log:trace("calculateDysentry using healthy rate")
        drainRate = drainRateHealthy
    else
        common.log:trace("calculateDysentry using sick rate")
        drainRate = drainRateSick
    end

    local newVal = dysentery:getValue() - ( scriptInterval * drainRate)
    
    common.log:trace("New dysentery value: %s", newVal)
    dysentery:setValue(newVal)
end


local weatherController
local function calculateBlightness(scriptInterval)
    if not common.data then return end
    --already has blight, set to 0
    local hasBlight = blightness:hasSpell()
    if hasBlight then
        common.log:trace("Already has blight, setting to 0")
        blightness:setValue(0)
        return
    end


    --Get conditions
    weatherController = weatherController or tes3.worldController.weatherController
    local weather = weatherController.currentWeather
    local isBlightWeather = (
        weather and 
        weather.blightDiseaseChance and
        weather.blightDiseaseChance > 0
    ) 

    local exposedToBlight = (
        isBlightWeather and 
        not common.helper.getInside(tes3.player) and 
        not common.helper.getInTent()
    )

    if exposedToBlight then
        common.log:trace("In a blight storm")
        
        --half from coverage
        local coverage = common.data.coverageRating
        local coverageMulti = math.remap(coverage, 0.0, 1.0, 0.5, 0.0)
        common.log:trace("coverageMulti : %s", coverageMulti)

        --half from face covered
        local faceMulti = common.data.faceCovered == true and 0.0 or 0.5
        common.log:trace("faceMulti : %s", faceMulti)
        --add them up to 0-1.0
        local coveragePlusFaceMulti = coverageMulti + faceMulti

        common.log:trace("----------------Blight coverage: %s", coveragePlusFaceMulti)
        common.log:trace("----------------blight per hour: %s", blightGainRate * coveragePlusFaceMulti)


        local newVal = blightness:getValue() + ( 
            scriptInterval * 
            blightGainRate * 
            coveragePlusFaceMulti
        )
        blightness:setValue(newVal)
    --not exposed to blight, reduce blightness
    else
        common.log:trace("Not exposed to blight")
        local newVal = blightness:getValue() - ( scriptInterval * blightDrainRate )
        blightness:setValue(newVal)
    end

    common.log:trace("New blightness value: %s", blightness:getValue() )
end


local function calculateFlu(scriptInterval)
    -- -100: 1.0x drain
    -- -30: break even (right in the middle of chilly, perfect)
    -- 40: 1.0x recovery
    local playerTemp = math.min(common.staticConfigs.conditionConfig.temp:getValue(), 40)
    local tempEffect = math.remap(playerTemp, -100, 0, 1.0, 0)
    common.log:trace("tempEffect: %s", tempEffect)

    local wetness = common.data.wetness
    local wetEffect = math.remap(wetness, 0, 100, 0, 0.5)
    common.log:trace("wetEffect: %s", wetEffect)

    local adjustedEffect = tempEffect + wetEffect
    common.log:trace("adjustedEffect: %s", adjustedEffect)

    common.log:trace("scriptInterval: %s", scriptInterval)
    local change = scriptInterval * adjustedEffect
    common.log:trace("change: %s", change)
    if change > 0 then
        change = change * fluIncreaseRate
    else
        change = change * fluDecreaseRate
    end
    common.log:trace("rate adjusted change: %s", change)
    local currentValue = flu:getValue()
    local newValue = currentValue + change
    common.log:trace("Flu: Change: %s ; new Value: %s", change, newValue)
    flu:setValue(newValue)
end

local defaultSneezes = {
    male = 'default_male.wav',
    female = 'default_female.wav',
}

local function getFileExists(path, fileName)
    for file in lfs.dir(path) do
		if file == fileName then
			return true
		end
    end
end

local function getSneezeSound()
    local sex = tes3.player.object.female and "female" or "male"
    local race = tes3.player.object.race.id
    local fileName = race .. "_" .. sex .. ".wav"
    local path = "ashfall\\sneezes"
    local sneezePath
    if getFileExists(("Data Files\\Sound\\" ..path), fileName) then
        sneezePath = path .. "\\" .. fileName
    else
        sneezePath = path .. "\\" .. defaultSneezes[sex]
    end
    common.log:debug("Getting sneeze at: %s", sneezePath)

    return sneezePath
end


local sneezeMinInterval = 20
local sneezeMaxInterval = 120
local function sneezeTimer()
    timer.start{
        type = timer.simulate,
        iterations = 1,
        duration = math.random(sneezeMinInterval, sneezeMaxInterval),
        callback = function()
            if flu:getCurrentState() == "hasFlu" then
                tes3.playSound{
                    reference = tes3.player,
                    soundPath = getSneezeSound()
                }
                tes3.messageBox("*Achoo!*")  
            end
            sneezeTimer()
        end
    }
end


function this.calculate(scriptInterval, forceUpdate)
    if scriptInterval == 0 and not forceUpdate then return end
    if not foodPoison:isActive() then
        foodPoison:setValue(0)
    end
    if not dysentery:isActive() then
        dysentery:setValue(0)
    end
    if not blightness:isActive() then
        blightness:setValue(0)
    end
    if not flu:isActive() then
        flu:setValue(0)
    end
    if common.data.blockNeeds == true then
        return
    end
    if foodPoison:isActive() then
        calculateFoodPoison(scriptInterval)
    end
    if dysentery:isActive() then
        calculateDysentry(scriptInterval)
    end
    if blightness:isActive() then
        calculateBlightness(scriptInterval)
    end
    if flu:isActive() then
        calculateFlu(scriptInterval)
    end
end

--[[
    Check whether the player's face is covered to protect against the blight
]]
local parts = {
    head = 0,
    hair = 1
}

local function checkFaceCovered(e)
    if not common.data then return end
    if (e.reference ~= tes3.player) then
        return 
    end

    if not e.bodyPart then
        return
    end

    if e.object then
        if e.object.objectType == tes3.objectType.armor and e.object.slot == tes3.armorSlot.helmet then
            common.log:trace("is helmet")
            common.log:trace("partType: %s", e.bodyPart.partType)
            common.log:trace("part: %s", e.bodyPart.part)
            if e.bodyPart.part == parts.head then
                common.log:trace("Face is covered")
                common.data.faceCovered = true
            else
                common.log:trace("Helmet but is exposed")
                common.data.faceCovered = false
            end
        end
    else
        common.log:trace("not an object")
        if e.bodyPart.part == parts.head then
            common.log:trace("e.bodyPart.part == parts.head ")
            common.data.faceCovered = false
        end

        if e.bodyPart == tes3.mobilePlayer.head then
            common.log:trace("no helmet, Face exposed")
            common.data.faceCovered = false
        end
    end
end
event.register("bodyPartAssigned", checkFaceCovered)

event.register("loaded", function() 
    if not tes3.player.data.equipmentUpdated then
        tes3.player:updateEquipment() 
        tes3.player.data.equipmentUpdated = true
        timer.delayOneFrame(function()
            tes3.player.data.equipmentUpdated = nil
        end)
    end

    sneezeTimer()
end )

return this