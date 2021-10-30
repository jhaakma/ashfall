return {
    text = "Add Ladle",
    showRequirements = function(campfire)
        return (
            campfire.sceneNode:getObjectByName("SWITCH_LADLE") and
            not campfire.data.ladle and
            campfire.data.dynamicConfig and
            campfire.data.dynamicConfig.cookingPot == "dynamic"
        )
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