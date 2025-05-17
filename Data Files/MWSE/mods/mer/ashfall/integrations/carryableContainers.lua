local CraftingFramework = require("CraftingFramework")
local CarryableContainer = CraftingFramework.CarryableContainer
local Backpack = require("mer.ashfall.items.backpack")
local common = require("mer.ashfall.common.common")
local logger = common.createLogger("carryableContainers")


---@param self CarryableContainer
local function doEquip(self)
    local item = self.item --[[@as tes3clothing]]
    logger:debug("Equipping backpack `%s`", item.id)
    local didEquip = tes3.mobilePlayer:equip{ item = item }
    if not didEquip then
        logger:error("Failed to equip backpack")
    end
    self:updateStats()
end

local function replaceAndEquip(self)
    logger:debug("replaceAndEquip backpack `%s`", self.item.id)
    if not self:isCopy() then
        logger:debug("Not a copy, replacing")
        self:replaceInInventory()
        timer.frame.delayOneFrame(function()
            logger:debug("Replacing backpack `%s` after a frame", self.item.id)
            doEquip(self)
        end)
    else
        logger:debug("Is a copy, equipping")
        doEquip(self)
    end
end

---@param self CarryableContainer
local function doOpen(self)
    logger:debug("Opening backpack `%s`", self.item.id)
    self:openFromInventory()
end

local callbacks = {
    ---@param self CarryableContainer
    openFromInventory = function(self)
        logger:debug("Opening from inventory")
        if CraftingFramework.Util.isQuickModifierDown() then
            doOpen(self)
        else
            replaceAndEquip(self)
        end
    end,
    ---@param self CarryableContainer
    _openFromInventory = function(self)
        if CraftingFramework.Util.isQuickModifierDown() then
            doOpen(self)
        else
            tes3ui.showMessageMenu{
                message = self.item.name,
                buttons = {
                    {
                        text = "Open",
                        callback = function()
                            timer.delayOneFrame(function() doOpen(self) end)
                        end
                    },
                    { text = "Equip", callback = function() doEquip(self) end },
                },
                cancels = true
            }
        end
    end,
    ---@param self CarryableContainer
    ---@param data CarryableContainer.onCopyCreatedData
    onCopyCreated = function(self, data)
        -- logger:trace("onCopyCreated")
        -- Backpack.registerBackpack(data.copy.id)
        -- common.data.backpacks[data.copy.id:lower()] = true
    end,
    ---@param self CarryableContainer
    getWeightModifier = function(self)
        logger:trace("getWeightModifier()")
        --Set weight modifier to 0.1 if the backpack is equipped,
        --otherwise set it to 1.0
        local equippedStack = tes3.getEquippedItem{
            actor = tes3.player,
            objectType = tes3.objectType.clothing,
            slot = 11
        }
        local isEquipped = equippedStack and equippedStack.object == self.item
        if isEquipped then
            logger:trace("- Updating weight for equipped backpack")
            return self.containerConfig.weightModifier
        end
        logger:trace("- Updating weight for unequipped backpack")
        return 1
    end,
    ---@param self CarryableContainer
    getWeightModifierText = function(self)
        return string.format("Weight Modifier: %.1fx When Equipped", self.containerConfig.weightModifier)
    end,
}



---@type CarryableContainer.containerConfig[]
local containers = {
    {
        -- Brown fur
        itemId = "ashfall_pack_01",
        capacity = 120,
        hasCollision = true,
        openFromInventory = callbacks.openFromInventory,
        onCopyCreated = callbacks.onCopyCreated,
        getWeightModifier = callbacks.getWeightModifier,
        getWeightModifierText = callbacks.getWeightModifierText,
        weightModifier = 0.3,
    },
    {
        -- White fur
        itemId = "ashfall_pack_02",
        capacity = 120,
        hasCollision = true,
        openFromInventory = callbacks.openFromInventory,
        onCopyCreated = callbacks.onCopyCreated,
        getWeightModifier = callbacks.getWeightModifier,
        getWeightModifierText = callbacks.getWeightModifierText,
        weightModifier = 0.3,
    },
    {
        -- Netch leather
        itemId = "ashfall_pack_03",
        capacity = 120,
        hasCollision = true,
        openFromInventory = callbacks.openFromInventory,
        onCopyCreated = callbacks.onCopyCreated,
        getWeightModifier = callbacks.getWeightModifier,
        getWeightModifierText = callbacks.getWeightModifierText,
        weightModifier = 0.5,
    },
    {
        -- Survivalist (bushcrafted)
        itemId = "ashfall_pack_04",
        capacity = 100,
        hasCollision = true,
        openFromInventory = callbacks.openFromInventory,
        onCopyCreated = callbacks.onCopyCreated,
        getWeightModifier = callbacks.getWeightModifier,
        getWeightModifierText = callbacks.getWeightModifierText,
        weightModifier = 0.5,
    },
    {
        -- Traveller (large with cover)
        itemId = "ashfall_pack_05",
        capacity = 150,
        hasCollision = true,
        openFromInventory = callbacks.openFromInventory,
        onCopyCreated = callbacks.onCopyCreated,
        getWeightModifier = callbacks.getWeightModifier,
        getWeightModifierText = callbacks.getWeightModifierText,
        weightModifier = 0.5,
    },
    {
        -- Nordic
        itemId = "ashfall_pack_06",
        capacity = 120,
        hasCollision = true,
        openFromInventory = callbacks.openFromInventory,
        onCopyCreated = callbacks.onCopyCreated,
        getWeightModifier = callbacks.getWeightModifier,
        getWeightModifierText = callbacks.getWeightModifierText,
        weightModifier = 0.3,
    },
    {
        --- Wicker
        itemId = "ashfall_pack_07",
        capacity = 100,
        hasCollision = true,
        openFromInventory = callbacks.openFromInventory,
        onCopyCreated = callbacks.onCopyCreated,
        getWeightModifier = callbacks.getWeightModifier,
        getWeightModifierText = callbacks.getWeightModifierText,
        weightModifier = 0.7,
    },
}

for _, container in ipairs(containers) do
    CarryableContainer.register(container)
end

---@param e unequippedEventData
event.register("unequipped", function(e)
    logger:trace("unequipped %s", e.item)
    local isBackpack = Backpack.isBackpack(e.item)
    if not isBackpack then
        logger:trace("not a backpack")
        return
    end
    local container = CarryableContainer:new{ item = e.item, itemData = e.itemData }
    if not container then
        logger:trace("not a carryable container")
        return
    end
    logger:trace("- updating stats on unequip")
    container:updateStats()
end)

--[[
    TODO:
        Instead of reregistering on load, change isBackpack and isSunshade to check both
        object ID and map to copiedID already stored in Crafting Framework
]]
event.register("loaded", function()
    for backpack in pairs(common.data.backpacks) do
        Backpack.registerBackpack(backpack)
    end
    for sunshade in pairs(common.data.sunshades) do
        common.helper.registerSunshade(sunshade)
    end
end)

---@param e objectCreatedEventData
event.register("objectCreated", function(e)
    if not e.copiedFrom then return end
    logger:debug("created from %s", e.copiedFrom.id)
    if Backpack.isBackpack(e.copiedFrom) then
        logger:debug("objectCreated: registering backpack %s", e.object.id)
        Backpack.registerBackpack(e.object.id)
        common.data.backpacks[e.object.id:lower()] = true
    end
    if common.helper.isSunshade(e.copiedFrom.id) then
        logger:debug("objectCreated: registering sun shade %s", e.object.id)
        common.helper.registerSunshade(e.object.id)
        common.data.sunshades[e.object.id:lower()] = true
    end
end)
