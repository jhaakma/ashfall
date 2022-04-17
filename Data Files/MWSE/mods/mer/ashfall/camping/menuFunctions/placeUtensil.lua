local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("placeUtensil")

local function addUtensil(item, campfire, addedItems, itemData)

    local grillData = common.staticConfigs.grills[item.id:lower()]
    local bellowsData = common.staticConfigs.bellows[item.id:lower()]
    if grillData then
        --local grillData = common.staticConfigs.grills[item.id:lower()]
        campfire.data.hasGrill = true
        campfire.data.grillId = item.id:lower()
        campfire.data.grillPatinaAmount = itemData and itemData.data.patinaAmount
    elseif bellowsData then
        campfire.data.bellowsId = item.id:lower()
    end


    if grillData and addedItems[item.id:lower()] then
        for material, count in pairs(grillData.materials) do
            if tes3.getItemCount{ reference = tes3.player, item = material} >= count then
                tes3.removeItem{ reference = tes3.player, item = material, count = count, playSound = false}
            end
        end
    else
        tes3.removeItem{ reference = tes3.player, item = item, itemData = itemData, playSound = false }
    end
    event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire})
    --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
end

local function utensilSelect(campfire)
    local addedItems = {}

    for grillId, data in pairs(common.staticConfigs.grills) do
        if tes3.getObject(grillId) then
            local hasInInventory = tes3.getItemCount{ item = grillId, reference = tes3.player } > 0
            if common.helper.playerHasMaterials(data.materials) and not hasInInventory then
                logger:debug("Adding grill to inventory: %s", grillId)
                addedItems[grillId:lower()] = true
                tes3.addItem{ reference = tes3.player, item = grillId, count = 1, playSound = false }
            end
        end
    end

    local canAttachGrill = campfire.sceneNode:getObjectByName("ATTACH_GRILL") ~= nil
    local canAttachBellows = campfire.sceneNode:getObjectByName("ATTACH_BELLOWS") ~= nil
    timer.delayOneFrame(function()
        tes3ui.showInventorySelectMenu{
            title = "Select Utensil",
            noResultsText = "You do not have any utensils.",
                filter = function(e)
                    if canAttachGrill and not campfire.data.grillId then
                        if common.staticConfigs.grills[e.item.id:lower()] ~= nil then return true end
                    end
                    if canAttachBellows and not campfire.data.bellowsId then
                        if common.staticConfigs.bellows[e.item.id:lower()] ~= nil then return true end
                    end
                    return false
                end,
            callback = function(e)
                if e.item then
                    addUtensil(e.item, campfire, addedItems, e.itemData)
                end
            end
        }
        timer.delayOneFrame(function()
            for id in pairs(addedItems) do
                tes3.removeItem{ reference = tes3.player, item = id, count = 1, playSound = false}
            end
        end)
    end)
end

return {
    text = "Place Utensil",
    showRequirements = function(campfire)
        return (not campfire.data.grillId) and campfire.sceneNode:getObjectByName("ATTACH_GRILL")
            or (not campfire.data.bellowsId) and campfire.sceneNode:getObjectByName("ATTACH_BELLOWS")
    end,
    enableRequirements = function(campfire)
        if campfire.sceneNode:getObjectByName("ATTACH_GRILL") and not campfire.data.grillId then
            for id, data in pairs(common.staticConfigs.grills) do
                if data.materials then
                    logger:debug("Has Materials for %s", id)
                    if common.helper.playerHasMaterials(data.materials) then return true end
                end
                if  mwscript.getItemCount{ reference = tes3.player, item = id} > 0 then
                    return true
                end
            end
        end
        if campfire.sceneNode:getObjectByName("ATTACH_BELLOWS") and not campfire.data.bellowsId then
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
    callback = utensilSelect,

}