--[[
    Checks for nearby fires and adds warmth
    based on how far away they are. 
    Will need special logic for player-built fires which
    have heat based on firewood level
]]--
local this = {}
local common = require("mer.ashfall.common.common")
local activatorConfig = common.staticConfigs.activatorConfig
---CONFIGS----------------------------------------
--max distance where fire has an effect
local heatValues = {
    lantern = 3,
    lamp = 1,
    candle = 1, 
    chandelier = 1,
    sconce = 5,
    torch = 12,
    fire = 18,
    flame = 20,
}



local heatDefault = 5
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

--Check Ids to see if this light is a firepit of some kind
local function checkForFirePit(id)
    if activatorConfig.list.fire:isActivator(id) then
        return true
    end
    return false
end

function this.calculateFireEffect()
    if not common.staticConfigs.conditionConfig.temp:isActive() then return end
    local totalHeat = 0
    local closeEnough
    common.data.nearCampfire = false
    for _, cell in pairs( tes3.getActiveCells() ) do
        for ref in cell:iterateReferences(tes3.objectType.light) do
            if not ref.disabled then
            --if ref.object.isFire then
                local distance = mwscript.getDistance({reference = "player", target = ref})
                if distance < maxDistance then
                    local maxHeat = heatDefault
                    --Firepits have special logic for hand warming
                    
                    if activatorConfig.list.campfire.ids[ref.object.id:lower()] then
                        if ref.data.isLit then
                            local fuel = ref.data.fuelLevel
                            if fuel then
                                common.data.nearCampfire = true
                                maxHeat = math.clamp(math.remap(fuel, 0, 10, 20, 60), 0, 60)
                                closeEnough = true
                        
                                checkWarmHands()
                                if warmingHands then
                                    maxHeat = maxHeat * warmHandsBonus 
                                end
                            else 
                                maxHeat = 0
                            end
                        else
                            maxHeat = 0
                        end
                    elseif checkForFirePit(ref.object.id) then
                        maxHeat = maxFirepitHeat
                        closeEnough = true
                        
                        checkWarmHands()
                        if warmingHands then
                            maxHeat = maxHeat * warmHandsBonus
                        end
                    --other fires
                    else
                        for pattern, heatValue in pairs(heatValues) do
                            if string.find(string.lower(ref.object.id), pattern) then
                                maxHeat = heatValue
                                --common.log:info("Fire source: %s", ref.object.id)
                            end
                        end
                    end
                    local heat = math.remap( distance, maxDistance, 0,  0, maxHeat )
                    totalHeat = totalHeat + heat
                end
            end
        end
    end
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