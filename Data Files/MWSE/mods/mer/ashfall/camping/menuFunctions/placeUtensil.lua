local common = require ("mer.ashfall.common.common")

local function addUtensil(item, campfire, itemData)
    if common.staticConfigs.grills[item.id:lower()] then
        --local grillData = common.staticConfigs.grills[item.id:lower()]
        campfire.data.hasGrill = true
        campfire.data.grillId = item.id:lower()
        campfire.data.grillPatinaAmount = itemData and itemData.data.patinaAmount
    elseif common.staticConfigs.bellows[item.id:lower()] then
        campfire.data.bellowsId = item.id:lower()
    end

    tes3.playSound{ reference = tes3.player, sound = "Item Misc Down"  }
    tes3.removeItem{ reference = tes3.player, item = item, itemData = itemData }
    event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire})
    --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
end

local function utensilSelect(campfire)
    timer.delayOneFrame(function()
        tes3ui.showInventorySelectMenu{
            title = "Select Utensil",
            noResultsText = "You do not have any utensils.",
                filter = function(e)
                    if not campfire.data.grillId then
                        if common.staticConfigs.grills[e.item.id:lower()] ~= nil then return true end
                    end
                    if not campfire.data.bellowsId then
                        if common.staticConfigs.bellows[e.item.id:lower()] ~= nil then return true end
                    end
                    return false
                end,
            callback = function(e)
                if e.item then
                    addUtensil(e.item, campfire, e.itemData)
                end
            end
        }
    end)
end

return {
    text = "Place Utensil",
    showRequirements = function(campfire)
        return (not campfire.data.grillId) and campfire.sceneNode:getObjectByName("ATTACH_GRILL")
            or (not campfire.data.bellowsId) and campfire.sceneNode:getObjectByName("ATTACH_BELLOWS")
    end,
    enableRequirements = function(campfire)
        if not campfire.data.grillId then
            for id, _ in pairs(common.staticConfigs.grills) do
                if  mwscript.getItemCount{ reference = tes3.player, item = id} > 0 then
                    return true
                end
            end
        end
        if not campfire.data.bellowsId then
            for id, _ in pairs(common.staticConfigs.bellows) do
                if  mwscript.getItemCount{ reference = tes3.player, item = id} > 0 then
                    return true
                end
            end
        end
        return false
    end,
    tooltipDisabled = {
        text = "You don't have any suitable utensils."
    },
    callback = utensilSelect
}