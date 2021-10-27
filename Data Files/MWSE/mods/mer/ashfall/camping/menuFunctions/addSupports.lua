local common = require ("mer.ashfall.common.common")

local function playerHasMaterials(materials)
    if not materials then return false end
    local hasMaterials = true
    for mat, count in pairs(materials) do
        common.log:debug("Count: %s ID: %s", count, mat)
        if tes3.getItemCount{ reference = tes3.player, item = mat } < count then
            hasMaterials =  false
        end
    end
    return hasMaterials
end

local function addSupports(item, campfire, addedItems, itemData)

    local supportsData = common.staticConfigs.supports[item.id:lower()]

    if addedItems[item.id:lower()] then
        common.log:debug("Removing materials for %s", item.id)
        for material, count in pairs(supportsData.materials) do
            if tes3.getItemCount{ reference = tes3.player, item = material} >= count then
                tes3.removeItem{ reference = tes3.player, item = material, count = count, playSound = false}
            end
        end
    else
        common.log:debug("Removing supports: %s", item.id)
        tes3.removeItem{ reference = tes3.player, item = item, itemData = itemData, playSound = false }
    end
    campfire.data.supportsId = item.id:lower()
    event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire})
    --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
end

local function supportsSelect(campfire)
    --Add constructed supports to inventory so they appear in select menu
    local addedItems = {}
    for supportId, data in pairs(common.staticConfigs.supports) do
        local hasInInventory = tes3.getItemCount{ item = supportId, reference = tes3.player } > 0
        if playerHasMaterials(data.materials) and not hasInInventory then
            common.log:debug("Adding support to inventory: %s", supportId)
            addedItems[supportId:lower()] = true
            tes3.addItem{ reference = tes3.player, item = supportId, count = 1, playSound = false }
        end
    end

    timer.delayOneFrame(function()
        tes3ui.showInventorySelectMenu{
            title = "Select Supports",
            noResultsText = "You do not have any supports.",
            filter = function(e)
                return common.staticConfigs.supports[e.item.id:lower()] ~= nil
            end,
            callback = function(e)
                if e.item then
                    addSupports(e.item, campfire, addedItems, e.itemData)
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
    text = "Add Supports",
    showRequirements = function(campfire)
        return (
            campfire.sceneNode:getObjectByName("ATTACH_SUPPORTS") and
            not campfire.data.supportsId and
            campfire.data.dynamicConfig and
            campfire.data.dynamicConfig.supports == "dynamic"
        )
    end,
    enableRequirements = function()
        for item, data in pairs(common.staticConfigs.supports) do
            if data.materials then
                common.log:debug("Has materials")
                if playerHasMaterials(data.materials) then return true end
            end
            common.log:debug("Checking if has item")
            if tes3.getItemCount{ reference = tes3.player, item = item } > 0 then
                return true
            end
        end

        return false
    end,
    tooltipDisabled = {
        text = "You don't have any supports or enough firewood."
    },
    callback = supportsSelect
}