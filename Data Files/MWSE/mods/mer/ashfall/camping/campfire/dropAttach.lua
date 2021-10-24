--[[
    Controller for dropping items onto a campfire
    Examples include dropping firewood to increase fuel, adding ingredients to stews etc
]]
local CampfireUtil = require "mer.ashfall.camping.campfire.CampfireUtil"
local activatorController = require "mer.ashfall.activators.activatorController"
local function onDrop(e)
    local campfire = activatorController.currentRef
    if campfire then
        local node = activatorController.parentNode
        local dropConfig = CampfireUtil.getDropConfig(node)
        if not dropConfig then return end
        for _, optionId in ipairs(dropConfig) do
            local option = require('mer.ashfall.camping.dropConfigs.' .. optionId)
            if option.canDrop(campfire, e.reference.object, e.reference.itemData) then
                option.onDrop(campfire,e.reference)
            end
        end
    end
end
event.register("itemDropped", onDrop)
