return {
    text = "Add Ladle",
    showRequirements = function(campfire)
        local hasLadleNode = campfire.sceneNode:getObjectByName("SWITCH_LADLE")
        local hasLadle =  campfire.data.ladle
        local hasStaticLadle = campfire.data.dynamicConfig and campfire.data.dynamicConfig.ladle == "static"
        mwse.log("hasLadle: %s", hasLadle)
        mwse.log("hasStaticLadle: %s", hasStaticLadle)
        mwse.log("hasLadleNode: %s", hasLadleNode)

        return hasLadleNode
            and not hasLadle
            and not hasStaticLadle
    end,
    enableRequirements = function()
        return mwscript.getItemCount{ reference = tes3.player, item = "misc_com_iron_ladle"} > 0
    end,
    tooltipDisabled = {
        text = "Requires 1 Iron Ladle."
    },
    callback = function(campfire)
        tes3.removeItem{ reference = tes3.player, item = "misc_com_iron_ladle" }
        campfire.data.ladle = true
        event.trigger("Ashfall:UpdateAttachNodes", { campfire = campfire})
    end
}