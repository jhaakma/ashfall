--[[
    Checks for nearby fires and adds warmth
    based on how far away they are.
    Will need special logic for player-built fires which
    have heat based on firewood level
]]--
local this = {}
local common = require("mer.ashfall.common.common")
local HeatUtil = require("mer.ashfall.heat.HeatUtil")
local staticConfigs = common.staticConfigs
local activatorConfig = common.staticConfigs.activatorConfig
local ReferenceController = require("mer.ashfall.referenceController")
---CONFIGS----------------------------------------
--max distance where fire has an effect

local fireValues = {
    light_6th_brazier = 10,
    lantern = 3,
    lamp = 1,
    candle = 1,
    chandelier = 1,
    sconce = 5,
    torch = 5,
    fire = 10,
    flame = 10,
    mc_campfire = 18,
    mc_logfire = 18,
}

local heatCache = {}
local function getHeatSourceValue(ref)

    local baseObject = ref.baseObject
    local cacheHit = heatCache[baseObject]
    if cacheHit then
        return cacheHit
    end

    local lowerId = baseObject.id:lower()
    for pattern, value in pairs(fireValues) do
        if string.find(lowerId, pattern) then
            heatCache[baseObject] = value
            return value
        end
    end
end

local function isLight(ref)
    return ref.baseObject and ref.baseObject.objectType == tes3.objectType.light
end

ReferenceController.registerReferenceController{
    id = "heatSource",
    requirements = function(_, ref)
        if ref.disabled then return false end
        if isLight(ref) then
            return getHeatSourceValue(ref) ~= nil
                and not activatorConfig.list.fire:isActivator(ref)
                and not activatorConfig.list.campfire:isActivator(ref)
        end
        return false
    end
}

ReferenceController.registerReferenceController{
    id = "flame",
    requirements = function(_, ref)
        if ref.disabled then return false end
        return activatorConfig.list.fire:isActivator(ref) == true
            and not activatorConfig.list.campfire:isActivator(ref)
    end
}

local maxFirepitHeat = 40
local maxDistance = 340
--Multiplier when warming hands next to firepit
local warmHandsBonus = 1.4
--------------------------------------------------

--Register heat source
local temperatureController = require("mer.ashfall.temperatureController")
temperatureController.registerExternalHeatSource("fireTemp")

--Check if player has Magic ready stance
local warmingHands
local triggerWarmMessage
local function checkWarmHands()
    if tes3.mobilePlayer.castReady then
        if not warmingHands then
            warmingHands = true
            triggerWarmMessage = true
        end
    else
        warmingHands = false
    end
end

local function getDistance(ref)
    return tes3.player.position:distance(ref.position)
end

local function getHeatAtDistance(maxHeat, distance)
    return math.remap( distance, maxDistance, 0,  0, maxHeat )
end

--[[
    If a heat source is a light object and it has
    no light attachment, block the heat
]]


function this.calculateFireEffect()
    if not staticConfigs.conditionConfig.temp:isActive() then return end
    local totalHeat = 0
    local closeEnough
    common.data.nearCampfire = false

    local function doCampfireHeat(ref)

        local isValid, distance = common.helper.getPlayerNearLitCampfire{
            reference = ref,
            maxDistance = maxDistance
        }
        if isValid then
            --For survival skill
            common.data.nearCampfire = true
            local fuel = HeatUtil.getHeat(ref)
            local isNegativeHeat = fuel < 0
            fuel = math.abs(fuel)
            local heatAtMaxDistance = math.clamp(math.remap(fuel, 0, 10, 0, 60), 0, 60)
            checkWarmHands()
            if warmingHands then
                heatAtMaxDistance = heatAtMaxDistance * warmHandsBonus
            end
            local heatAtThisDistance = getHeatAtDistance(heatAtMaxDistance, distance)
            if isNegativeHeat then
                heatAtThisDistance = -heatAtThisDistance
            end
            totalHeat = totalHeat + heatAtThisDistance

            closeEnough = true
        end
    end
    ReferenceController.iterateReferences("fuelConsumer", doCampfireHeat)

    local function doFlameHeat(ref)
        local distance = getDistance(ref)
        local isValid = distance < maxDistance
            and (not ref.disabled)
            and (not common.helper.isUnlit(ref))
        if isValid then
            local heatAtMaxDistance = maxFirepitHeat
            checkWarmHands()
            if warmingHands then
                heatAtMaxDistance = heatAtMaxDistance * warmHandsBonus
            end
            local heatAtThisDistance = getHeatAtDistance(heatAtMaxDistance, distance)
            totalHeat = totalHeat + heatAtThisDistance
            closeEnough = true
        end
    end
    ReferenceController.iterateReferences("flame", doFlameHeat)

    local function doOtherHeat(ref)
        local distance = getDistance(ref)
        local isValid = distance < maxDistance
            and (not ref.disabled)
            and (not common.helper.isUnlit(ref))
        if isValid then
            local heatAtMaxDistance = getHeatSourceValue(ref)
            local heatAtThisDistance = getHeatAtDistance(heatAtMaxDistance, distance)
            totalHeat = totalHeat + heatAtThisDistance
        end
    end
    ReferenceController.iterateReferences("heatSource", doOtherHeat)

    if not closeEnough then
        warmingHands = false
    end
    if triggerWarmMessage then
        triggerWarmMessage = false
        tes3.messageBox("You warm your hands by the fire")
    end
    common.data.fireTemp = totalHeat
end


return this