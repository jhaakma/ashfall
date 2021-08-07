local common = require ("mer.ashfall.common.common")
local patinaController = require("mer.ashfall.camping.patinaController")

local function addGrill(item, campfire, itemData)
    --local grillData = common.staticConfigs.grills[item.id:lower()]
    tes3.playSound{ reference = tes3.player, sound = "Item Misc Down"  }
    campfire.data.hasGrill = true
    campfire.data.grillId = item.id:lower()
    campfire.data.grillPatinaAmount = itemData and itemData.data.patinaAmount
    event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire})
    tes3.removeItem{ reference = tes3.player, item = item, itemData = itemData }

    --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
end

local function utensilSelect(campfire)
    timer.delayOneFrame(function()
        tes3ui.showInventorySelectMenu{
            title = "Select Utensil",
            noResultsText = "You do not have any utensils.",
                filter = function(e)
                    return common.staticConfigs.grills[e.item.id:lower()] ~= nil
                end,
            callback = function(e)
                if e.item then
                    addGrill(e.item, campfire, e.itemData)
                end
            end
        }
    end)
end

return {
    text = "Place Utensil",
    showRequirements = function(campfire)
        return (not campfire.data.grillId) 
            and (campfire.data.dynamicConfig 
            and campfire.data.dynamicConfig.grill == "dynamic")
    end,
    enableRequirements = function()
        for id, _ in pairs(common.staticConfigs.grills) do
            if  mwscript.getItemCount{ reference = tes3.player, item = id} > 0 then
                return true
            end
        end
        return false
    end,
    tooltipDisabled = {
        text = "You don't have any suitable utensils."
    },
    callback = utensilSelect
}