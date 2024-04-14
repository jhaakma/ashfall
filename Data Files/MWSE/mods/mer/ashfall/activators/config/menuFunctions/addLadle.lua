local common = require ("mer.ashfall.common.common")

return {
    text = "Add Ladle",
    showRequirements = function(reference)
        if not reference.supportsLuaData then return false end
        local hasLadleNode = reference.sceneNode:getObjectByName("ATTACH_LADLE")
        local hasLadle =  not not reference.data.ladle
        local hasStaticLadle = ( reference.data.dynamicConfig and reference.data.dynamicConfig.ladle == "static")
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
    callback = function(reference)
        for id, _ in pairs(common.staticConfigs.ladles) do
            local ladle = tes3.getObject(id)
            if ladle then
                if common.helper.getItemCount{ reference = tes3.player, item = ladle } > 0 then
                    common.helper.removeItem{ reference = tes3.player, item = ladle }
                    reference.data.ladle = id:lower()
                    event.trigger("Ashfall:UpdateAttachNodes", { reference = reference})
                    break
                end
            end
        end
    end
}