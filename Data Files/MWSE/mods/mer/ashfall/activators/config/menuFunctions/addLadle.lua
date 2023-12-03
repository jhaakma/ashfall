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
            local ladle = tes3.getObject(id)
            if ladle then
                if common.helper.getItemCount{ reference = tes3.player, item = ladle } > 0 then
                    return true
                end
            end
        end
        return false
    end,
    tooltip = function()
        return common.helper.showHint("You can add a ladle by dropping it directly onto the cooking pot.")
    end,
    tooltipDisabled = {
        text = "Requires 1 Ladle."
    },
    callback = function(campfire)
        for id, _ in pairs(common.staticConfigs.ladles) do
            local ladle = tes3.getObject(id)
            if ladle then
                if common.helper.getItemCount{ reference = tes3.player, item = ladle } > 0 then
                    common.helper.removeItem{ reference = tes3.player, item = ladle }
                    campfire.data.ladle = id:lower()
                    event.trigger("Ashfall:UpdateAttachNodes", { reference = campfire})
                    break
                end
            end
        end
    end
}