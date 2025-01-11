local LiquidContainer = require("mer.ashfall.liquid.LiquidContainer")

local CraftingFramework = include("CraftingFramework")
if CraftingFramework then
    local TileDropper = CraftingFramework.TileDropper
    if TileDropper then
        TileDropper.register{
            name = "AshfallLiquidContainer",
            highlightColor = { 0.5, 0.8, 1 },
            keepHeldInCursor = true,
            isValidTarget = function(target)
                local liquidContainer = LiquidContainer.createFromInventory(target.item, target.itemData)
                return liquidContainer ~= nil
                    and liquidContainer.waterAmount < liquidContainer.capacity
            end,
            canDrop = function(e)
                local held = LiquidContainer.createFromInventory(e.held.item, e.held.itemData)
                if not held then return false end
                local target = LiquidContainer.createFromInventory(e.target.item, e.target.itemData)
                return LiquidContainer.canTransfer(held, target)
            end,
            onDrop = function(e)
                local held = LiquidContainer.createFromInventoryWithItemData{ item = e.held.item, itemData = e.held.itemData, reference = e.reference }
                local target = LiquidContainer.createFromInventoryWithItemData{ item = e.target.item, itemData = e.target.itemData, reference = e.reference }
                LiquidContainer.transferLiquid(held, target)
            end
        }
    end
end