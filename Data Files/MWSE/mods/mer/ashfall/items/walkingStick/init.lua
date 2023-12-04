local common = require("mer.ashfall.common.common")
local logger = common.createLogger("walkingStick")

---@type table<string, string>
local STICK_ID_MAP = {
    ashfall_staff_wood = "ashfall_walking_stick",
    ashfall_walking_stick = "ashfall_staff_wood",
}


--- Claim mouse click events on item tiles.
--- @param e itemTileUpdatedEventData
local function onInventoryTileUpdated(e)
    --- @param e tes3uiEventData
    e.element:registerBefore("mouseClick", function(e)
        if common.helper.isModifierKeyPressed() then
            local tileData = e.source:getPropertyObject("MenuInventory_Thing", "tes3inventoryTile") --- @type tes3inventoryTile
            if not tileData then return end

            local stickId = STICK_ID_MAP[tileData.item.id:lower()]
            if not stickId then return end

            local originalStick = tileData.item
            local originalItemData = tileData.itemData

            ---@diagnostic disable-next-line
            tileData = nil

            local isEquipped = tes3.player.object:hasItemEquipped(originalStick)
            if not isEquipped then return end
            local newStick = tes3.getObject(stickId)
            if not newStick then return end

            tes3.removeItem{
                reference = tes3.player,
                item = originalStick,
                itemData = originalItemData,
                playSound = false,
            }
            tes3.addItem{
                reference = tes3.player,
                item = newStick,
                playSound = false,
            }

            if originalItemData then
                local itemData = tes3.addItemData{
                    to = tes3.player,
                    item = newStick,
                }
                itemData.condition = originalItemData.condition
                if originalItemData.data and table.size(originalItemData.data) > 0 then
                    table.copymissing(itemData.data, originalItemData.data)
                end
            end
            tes3.mobilePlayer:equip{
                item = newStick,
            }
            logger:debug("Replaced %s with %s", originalStick.id, stickId)
            tes3.worldController.menuClickSound:play()
            tes3.messageBox("You swap your walking stick to the other hand.")
            return false
        end
    end)
end
event.register("itemTileUpdated", onInventoryTileUpdated)

---@param e uiObjectTooltipEventData
event.register("uiObjectTooltip", function(e)
    if not e.object then return end
    if not tes3ui.menuMode() then return end
    if STICK_ID_MAP[e.object.id:lower()] == nil then return end
    local isEquipped = tes3.player.object:hasItemEquipped(e.object)
    if not isEquipped then return end
    local key = common.helper.getModifierKeyString()
    local tooltipText = string.format("%s + click to swap hands", key)
    common.helper.addLabelToTooltip(e.tooltip, tooltipText)
end)