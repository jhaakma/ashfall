--[[
    Checks for nearby fires and adds warmth
    based on how far away they are.
    Will need special logic for player-built fires which
    have heat based on firewood level
]]--
local this = {}
local common = require("mer.ashfall.common.common")
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")
local staticConfigs = common.staticConfigs
local activatorConfig = common.staticConfigs.activatorConfig
local refController = require("mer.ashfall.referenceController")
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

refController.registerReferenceController{
    id = "heatSource",
    requirements = function(_, ref)
        if ref.disabled then return false end
        if isLight(ref) then
            return getHeatSourceValue(ref) ~= nil
                and not activatorConfig.list.fire:isActivator(ref.object.id)
                and not activatorConfig.list.campfire:isActivator(ref.object.id)
        end
        return false
    end
}

refController.registerReferenceController{
    id = "flame",
    requirements = function(_, ref)
        if ref.disabled then return false end
        return activatorConfig.list.fire:isActivator(ref.object.id) == true
            and not activatorConfig.list.campfire:isActivator(ref.object.id)
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
local function isUnlit(ref)
    if ref.baseObject.objectType == tes3.objectType.light then
        return ref:getAttachedDynamicLight() == nil
    end
    return false
end

function this.calculateFireEffect()
    if not staticConfigs.conditionConfig.temp:isActive() then return end
    local totalHeat = 0
    local closeEnough
    common.data.nearCampfire = false

    local function doCampfireHeat(ref)
        local distance = getDistance(ref)

        local isValid = distance < maxDistance
            and (not ref.disabled)
            and ref.data.isLit
            and (not isUnlit(ref))

        if isValid then
            --For survival skill
            common.data.nearCampfire = true
            local fuel = CampfireUtil.getHeat(ref)
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
    common.helper.iterateRefType("fuelConsumer", doCampfireHeat)

    local function doFlameHeat(ref)
        local distance = getDistance(ref)
        local isValid = distance < maxDistance
            and (not ref.disabled)
            and (not isUnlit(ref))
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
    common.helper.iterateRefType("flame", doFlameHeat)

    local function doOtherHeat(ref)
        local distance = getDistance(ref)
        local isValid = distance < maxDistance
            and (not ref.disabled)
            and (not isUnlit(ref))
        if isValid then
            local heatAtMaxDistance = getHeatSourceValue(ref)
            local heatAtThisDistance = getHeatAtDistance(heatAtMaxDistance, distance)
            totalHeat = totalHeat + heatAtThisDistance
        end
    end
    common.helper.iterateRefType("heatSource", doOtherHeat)

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