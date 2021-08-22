
local AttachConfig = require "mer.ashfall.camping.campfire.AttachConfig"
local CampfireUtil = {}
local common = require ("mer.ashfall.common.common")

--[[
    Get heat based on fuel level and modifiers
]]
function CampfireUtil.getHeat(campfire)
    local bellowsEffect = 1.0
    local bellowsId = campfire.data.bellowsId and campfire.data.bellowsId:lower()
    local bellowsData = common.staticConfigs.bellows[bellowsId]
    if bellowsData then
        bellowsEffect = bellowsData.heatEffect
    end

    local isLit = campfire.data.isLit
    local fuelLevel = campfire.data.fuelLevel or 0
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

return CampfireUtil

