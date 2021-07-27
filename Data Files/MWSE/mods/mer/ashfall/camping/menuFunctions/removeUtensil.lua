local common = require ("mer.ashfall.common.common")

local function checkDynamicStatus(campfire)
    return campfire.data.dynamicConfig[campfire.data.utensil] ~= "static"
end

return  {
    text = function(campfire)
        local utensilId = campfire.data.utensilId
        local utensil = tes3.getObject(utensilId)
        return string.format("Remove %s", common.helper.getGenericUtensilName(utensil) or "Utensil")
    end,
    showRequirements = function(campfire)
        return  campfire.data.utensilId ~= nil
        and campfire.data.dynamicConfig 
        and checkDynamicStatus(campfire)
    end,
    enableRequirements = function(campfire)
        return ( not campfire.data.waterAmount or
        campfire.data.waterAmount == 0 )
    end,
    tooltipDisabled = {
        text = "Utensil must be emptied before it can be removed."
    },
    callback = function(campfire)
        mwscript.addItem{ reference = tes3.player, item = campfire.data.utensilId }
        if campfire.data.ladle == true then
            mwscript.addItem{ reference = tes3.player, item = "misc_com_iron_ladle" }
        end
        event.trigger("Ashfall:Campfire_clear_utensils", { campfire = campfire, removeUtensil = true})
        event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire,})
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
    end
}