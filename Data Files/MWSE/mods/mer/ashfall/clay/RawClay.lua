local common = require("mer.ashfall.common.common")
local logger = common.createLogger("RawClay")
local CraftingFramework = require("CraftingFramework")
local Temper = require("mer.ashfall.clay.Temper")

---Class for managing raw clay, from tooltips, tempering, and data management
---@class Ashfall.Clay.RawClay
local RawClay = {
    rawClayId = "ashfall_raw_clay_01",
    brokenClayId = "ashfall_clay_broken_01",
}

--Returns the number of clay in the player's inventory
---@return number
function RawClay.getPlayerClayInInventory()
    local rawCount = CraftingFramework.CarryableContainer.getItemCount{
        reference = tes3.player,
        item = RawClay.rawClayId
    }
    return rawCount
end


---Open Inventory Select Menu to pick a raw clay from player inventory
---@param callback fun(e:  CraftingFramework.showInventorySelectMenu.callbackParams)
function RawClay.openSelectMenu(callback, opts)
        common.helper.showInventorySelectMenu{
            title = "Select Raw Clay",
            filter = function(e)
                if opts.tempered ~= nil then
                    local clayIsTempered = Temper.isTempered{
                        item = e.item,
                        itemData = e.itemData,
                    }
                    if opts.tempered ~= clayIsTempered then
                        return false
                    end
                end
                local id = e.item.id:lower()
                return id == RawClay.rawClayId
            end,
            callback = callback,
            noResultsText = "No matching clay found in inventory.",
            delayFrame = true,
        }
end

return RawClay
