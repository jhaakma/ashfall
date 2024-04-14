local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("placeUtensil")

---@param reference tes3reference
---@param item tes3item|tes3misc
---@param campfire tes3reference
---@param addedItems table<string, boolean>
---@param itemData tes3itemData
local function addUtensil(reference, item, campfire, addedItems, itemData)
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
            if common.helper.getItemCount{ reference = tes3.player, item = material} >= count then
                common.helper.removeItem{ reference = tes3.player, item = material, count = count, playSound = false}
            end
        end
    else
        common.helper.removeItem{ reference = reference, item = item, itemData = itemData, playSound = false }
    end
    event.trigger("Ashfall:UpdateAttachNodes", { reference = campfire})
    --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
end

local function utensilSelect(campfire)
    local addedItems = {}

    for grillId, data in pairs(common.staticConfigs.grills) do
        local grill = tes3.getObject(grillId)
        if grill then
            local hasInInventory = common.helper.getItemCount{ item = grill, reference = tes3.player } > 0
            if common.helper.playerHasMaterials(data.materials) and not hasInInventory then
                logger:debug("Adding grill to inventory: %s", grillId)
                addedItems[grillId:lower()] = true
                tes3.addItem{ reference = tes3.player, item = grill, count = 1, playSound = false }
            end
        end
    end

    local canAttachGrill = campfire.sceneNode:getObjectByName("ATTACH_GRILL") ~= nil
    local canAttachBellows = campfire.sceneNode:getObjectByName("ATTACH_BELLOWS") ~= nil
    timer.delayOneFrame(function()
        common.helper.showInventorySelectMenu{
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
                    addUtensil(e.reference, e.item, campfire, addedItems, e.itemData)
                end
            end
        }
        timer.delayOneFrame(function()
            for id in pairs(addedItems) do
                common.helper.removeItem{ reference = tes3.player, item = id, count = 1, playSound = false}
            end
        end)
    end)
end

return {
    text = "Place Utensil",
    showRequirements = function(reference)
        if not reference.supportsLuaData then return false end
        return (not reference.data.grillId) and reference.sceneNode:getObjectByName("ATTACH_GRILL")
            or (not reference.data.bellowsId) and reference.sceneNode:getObjectByName("ATTACH_BELLOWS")
    end,
    enableRequirements = function(reference)
        if reference.sceneNode:getObjectByName("ATTACH_GRILL") and not reference.data.grillId then
            for id, data in pairs(common.staticConfigs.grills) do
                local item = tes3.getObject(id)
                if item then
                    if data.materials then
                        logger:debug("Has Materials for %s", id)
                        if common.helper.playerHasMaterials(data.materials) then return true end
                    end
                    if  common.helper.getItemCount{ reference = tes3.player, item = item} > 0 then
                        return true
                    end
                end
            end
        end
        if reference.sceneNode:getObjectByName("ATTACH_BELLOWS") and not reference.data.bellowsId then
            for id, _ in pairs(common.staticConfigs.bellows) do
                local item = tes3.getObject(id)
                if item then
                    if  common.helper.getItemCount{ reference = tes3.player, item = item} > 0 then
                        return true
                    end
                end
            end
        end
        return false
    end,
    tooltip = function()
        return common.helper.showHint(string.format(
            "You can attach a utensil by dropping it directly onto the campfire.",
            common.helper.getModifierKeyString()
        ))
    end,
    tooltipDisabled = {
        text = "You don't have any suitable utensils."
    },
    callback = utensilSelect,

}