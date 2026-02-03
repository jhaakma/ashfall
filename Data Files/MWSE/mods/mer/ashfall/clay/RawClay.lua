local common = require("mer.ashfall.common.common")
local logger = common.createLogger("RawClay")
local CraftingFramework = require("CraftingFramework")

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
function RawClay.openSelectMenu(callback)
    timer.delayOneFrame(function()
        common.helper.showInventorySelectMenu{
            title = "Select Raw Clay",
            filter = function(e)
                local id = e.item.id:lower()
                return id == RawClay.rawClayId
            end,
            callback = callback,
            noResultsText = "No raw clay found in inventory."
        }
    end)
end

return RawClay
