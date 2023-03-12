---@class Ashfall.ItemInstance.new.params
---@field reference tes3reference|nil
---@field item tes3item|tes3object|nil
---@field itemData tes3itemData|nil
---@field owner tes3reference|nil

--[[
    Represents an individual object and it's associated data,
    regardless of whether it exists as a reference or an object
    inside an inventory.
]]
---@class Ashfall.ItemInstance : Ashfall.ItemInstance.new.params
local ItemInstance = {}

---@param e Ashfall.ItemInstance.new.params
---@return Ashfall.ItemInstance
function ItemInstance:new(e)
    local itemInstance = setmetatable({}, self)
    itemInstance.reference = e.reference
    itemInstance.item = e.item or e.reference.baseObject
    itemInstance.dataHolder = e.itemData or e.reference
    itemInstance.id = itemInstance.item.id:lower()
    -- reference data
    itemInstance.data = setmetatable({}, {
        __index = function(_, k)
            if not (
                itemInstance.dataHolder
                and itemInstance.dataHolder.data
            ) then
                return nil
            end
            return itemInstance.dataHolder.data.joyOfPainting[k]
        end,
        __newindex = function(_, k, v)
            if not (
                itemInstance.dataHolder
                and itemInstance.dataHolder.data
            ) then
                if not itemInstance.reference then
                    --create itemData
                    itemInstance.dataholder = tes3.addItemData{
                        to = tes3.player,
                        item = itemInstance.item,
                    }
                end
            end
            itemInstance.dataHolder.data = v
        end
    })
    return itemInstance

end
return ItemInstance