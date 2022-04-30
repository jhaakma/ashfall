local common = require ("mer.ashfall.common.common")

return {
    text = "Add Ladle",
    showRequirements = function(campfire)
        local hasLadleNode = campfire.sceneNode:getObjectByName("ATTACH_LADLE")
        local hasLadle =  not not campfire.data.ladle
        local hasStaticLadle = ( campfire.data.dynamicConfig and campfire.data.dynamicConfig.ladle == "static")
        return hasLadleNode
            and (not hasLadle)
            and (not hasStaticLadle)
    end,
    enableRequirements = function()
        for id, _ in pairs(common.staticConfigs.ladles) do
            if tes3.getObject(id) then
                if tes3.getItemCount{ reference = tes3.player, item = id} > 0 then
                    return true
                end
            end
        end
        return false
    end,
    tooltipDisabled = {
        text = "Requires 1 Ladle."
    },
    callback = function(campfire)
        for id, _ in pairs(common.staticConfigs.ladles) do
            if tes3.getObject(id) then
                if tes3.getItemCount{ reference = tes3.player, item = id} > 0 then
                    tes3.removeItem{ reference = tes3.player, item = id }
                    campfire.data.ladle = id:lower()
                    event.trigger("Ashfall:UpdateAttachNodes", { campfire = campfire})
                    break
                end
            end
        end
    end
}