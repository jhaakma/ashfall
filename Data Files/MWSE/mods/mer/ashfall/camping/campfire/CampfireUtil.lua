
local AttachConfig = require "mer.ashfall.camping.campfire.AttachConfig"
local CampfireUtil = {}
local common = require ("mer.ashfall.common.common")

--[[
    Get heat based on fuel level and modifiers
]]
function CampfireUtil.getHeat(data)
    local bellowsEffect = 1.0
    local bellowsId = data.bellowsId and data.bellowsId:lower()
    local bellowsData = common.staticConfigs.bellows[bellowsId]
    if bellowsData then
        bellowsEffect = bellowsData.heatEffect
    end

    local isLit = data.isLit
    local fuelLevel = data.fuelLevel or 0
    if (not isLit) or (fuelLevel <= 0) then
        return 0
    else
        return fuelLevel * bellowsEffect
    end
end

function CampfireUtil.getAttachmentConfig(node)
    --default campfire
    local attachmentConfig = AttachConfig.CAMPFIRE
    while node.parent do
        if AttachConfig[node.name] then
            attachmentConfig = AttachConfig[node.name]
            break
        end
        node = node.parent
    end
    return attachmentConfig
end


function CampfireUtil.getGenericUtensilName(obj)
    local name = obj and obj.name
    if name then
        local colonIndex = string.find(obj.name, ":") or 0
        return string.sub(obj.name, 0, colonIndex - 1 )
    end
end

function CampfireUtil.getAttachmentName(campfire, attachConfig)
    if attachConfig.name then
        return attachConfig.name
    elseif attachConfig.idPath then
        local objId = campfire.data[attachConfig.idPath]
        local obj = tes3.getObject(objId)
        return CampfireUtil.getGenericUtensilName(obj)
    end
    --fallback
    return AttachConfig.CAMPFIRE.name
end

function CampfireUtil.addExtraTooltip(attachmentConfig, campfire, tooltip)
    if attachmentConfig.tooltipExtra then
        attachmentConfig.tooltipExtra(campfire, tooltip)
    end
end

function CampfireUtil.getUtensilData(ref)
    local utensilId = ref.data.utensilId
    local utensilData = common.staticConfigs.utensils[utensilId]

    if not utensilData then
        utensilData = common.staticConfigs.utensils[ref.object.id:lower()]
    end
    return utensilData
end


function CampfireUtil.setHeat(refData, newHeat, reference)
    common.log:trace("Setting heat of %s to %s", reference or "[unknown]", newHeat)
    local heatBefore = refData.waterHeat or 0
    refData.waterHeat = math.clamp(newHeat, 0, 100)
    local heatAfter = refData.waterHeat
    --add sound if crossing the boiling barrior
    if reference and not reference.disabled then
        if heatBefore < common.staticConfigs.hotWaterHeatValue and heatAfter > common.staticConfigs.hotWaterHeatValue then
            tes3.removeSound{
                reference = reference,
                sound = "ashfall_boil"
            }
            tes3.playSound{
                reference = reference,
                sound = "ashfall_boil"
            }
        end
        --remove boiling sound
        if heatBefore > common.staticConfigs.hotWaterHeatValue and heatAfter < common.staticConfigs.hotWaterHeatValue then
            common.log:debug("No longer hot")
            tes3.removeSound{
                reference = reference,
                sound = "ashfall_boil"
            }
            event.trigger("Ashfall:UpdateAttachNodes", {campfire = reference})
        end
    end
end

local heatLossAtMinCapacity = 3.0
local heatLossAtMaxCapacity = 1.0
local waterHeatRate = 40--base water heat/cooling speed
local minFuelWaterHeat = 5--min fuel multiplier on water heating
local maxFuelWaterHeat = 10--max fuel multiplier on water heating
function CampfireUtil.updateWaterHeat(refData, capacity, reference)
    if not refData.waterAmount then return end
    local now = tes3.getSimulationTimestamp()
    refData.lastWaterUpdated = refData.lastWaterUpdated or now
    local timeSinceLastUpdate = now - refData.lastWaterUpdated
    refData.lastWaterUpdated = now
    refData.waterHeat = refData.waterHeat or 0
    --Heats up or cools down depending on fuel/is lit
    local heatEffect = -1--negative if cooling down
    if refData.isLit then--based on fuel if heating up
        heatEffect = math.remap(CampfireUtil.getHeat(refData), 0, common.staticConfigs.maxWoodInFire, minFuelWaterHeat, maxFuelWaterHeat)
        common.log:trace("BOILER heatEffect: %s", heatEffect)
    end

    --Amount of water determines how quickly it boils

    local filledAmount = refData.waterAmount / capacity
    common.log:trace("BOILER filledAmount: %s", filledAmount)
    local filledAmountEffect = math.remap(filledAmount, 0.0, 1.0, heatLossAtMinCapacity, heatLossAtMaxCapacity)
    common.log:trace("BOILER filledAmountEffect: %s", filledAmountEffect)

    --Calculate change
    local heatChange = timeSinceLastUpdate * heatEffect * filledAmountEffect * waterHeatRate

    CampfireUtil.setHeat(refData, refData.waterHeat + heatChange, reference)
end

return CampfireUtil

