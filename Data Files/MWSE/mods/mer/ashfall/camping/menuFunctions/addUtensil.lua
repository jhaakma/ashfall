local common = require ("mer.ashfall.common.common")

local function addUtensil(item, campfire)
    mwscript.removeItem{ reference = tes3.player, item = item }
    local utensilData = common.staticConfigs.utensils[item.id:lower()]
    
    tes3.playSound{ reference = tes3.player, sound = "Item Misc Down"  }

    if utensilData.type == "cookingPot" then
        if mwscript.getItemCount{ reference = tes3.player, item = "misc_com_iron_ladle"} > 0 then
            mwscript.removeItem{ reference = tes3.player, item = "misc_com_iron_ladle" }
            campfire.data.ladle = true
        end
    end
    campfire.data.utensil = utensilData.type
    campfire.data.utensilId = item.id:lower()
    campfire.data.waterCapacity = utensilData.capacity or 100
    common.log:debug("Set water capacity to %s", campfire.data.waterCapacity)
    event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire})
    --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
end

local function utensilSelect(campfire)
    timer.delayOneFrame(function()
        tes3ui.showInventorySelectMenu{
            title = "Select Utensil",
            noResultsText = "You do not have any utensils.",
            filter = function(e)
                return common.staticConfigs.utensils[e.item.id:lower()] ~= nil
            end,
            callback = function(e)
                if e.item then
                    addUtensil(e.item, campfire)
                end
            end
        }
    end)
end

return {
    text = "Hang Utensil",
    showRequirements = function(campfire)
        return (
            campfire.data.hasSupports and
            not campfire.data.utensil and
            campfire.data.dynamicConfig and
            (campfire.data.dynamicConfig.kettle == "dynamic"
            or campfire.data.dynamicConfig.cookingPot == "dynamic")
        )
    end,
    enableRequirements = function()
        for id, _ in pairs(common.staticConfigs.utensils) do
            if  mwscript.getItemCount{ reference = tes3.player, item = id} > 0 then
                return true
            end
        end
        return false
    end,
    tooltipDisabled = { 
        text = "You don't have any utensils."
    },
    callback = utensilSelect
}