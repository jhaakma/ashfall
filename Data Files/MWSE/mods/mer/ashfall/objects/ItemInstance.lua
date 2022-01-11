--[[
    Represents an individual item and it's associated data,
    regardless of whether it exists as a reference or an item
    inside an inventory.
]]
local ItemInstance = {}
function ItemInstance.new(e)
    --get input
    local reference = e.reference
    local item = reference and reference.object or e.item
    assert(item, "ItemInstance.new: Either a reference or item must be provided.")
    local itemData = e.itemData
    local owner = e.owner
    --create instance
    local itemInstance = {
        item = item,
        itemData = itemData,
        reference = reference,
        owner = owner or tes3.player
    }
    --determine metatable for data field
    local dataMeta
    if reference then
        dataMeta = {
            __index = function(self, key)
                return itemInstance.reference.data
            end,
            __setindex = function(self, key, val)
                itemInstance.reference.data[key] = val
            end
        }
    else
        dataMeta = {
            __index = function(self, key)
                return itemInstance.itemData
                    and itemInstance.itemData.data
                    and itemInstance.itemData.data[key]
            end,
            __setindex = function(self, key, val)
                if not itemInstance.itemData then
                    itemInstance.itemData = tes3.addItemData{
                        to = itemInstance.owner,
                        item = itemInstance.item,
                    }
                end
                itemInstance.itemData.data[key] = val
            end
        }
    end
    itemInstance.data = setmetatable({}, dataMeta)
    return itemInstance
end
return ItemInstance