local common = require("mer.ashfall.common.common")
local logger = common.createLogger("BrickShed")
local ItemInstance = require("CraftingFramework.carryableContainers.components.ItemInstance")
local Brick = require("mer.ashfall.clay.Brick")
local CraftingFramework = require("CraftingFramework")
local ReferenceManager = CraftingFramework.ReferenceManager
local MaterialStorage = CraftingFramework.MaterialStorage
---@class Ashfall.BrickShedData
---@field brickCount number The current number of bricks stored in the shed


---@class Ashfall.BrickShed : ItemInstance
---@field data Ashfall.BrickShedData
local BrickShed = {
    capacity = 100,
    registeredBrickSheds = {
        ashfall_brick_shed = true
    }
}


ReferenceManager:new{
    requirements = function(_, reference)
        return BrickShed.isBrickShed(reference.baseObject.id)
    end,
    onActivated = function(_, reference)
        BrickShed.wrap(reference, function(brickShed)
            brickShed:updateVisuals()
        end)
    end
}

MaterialStorage:new{
    id = "BrickShed",
    isStorage = function(self, reference)
        return BrickShed.isBrickShed(reference.baseObject.id)
    end,
    getMaterials = function(self, reference)
        return BrickShed.wrap(reference, function(brickShed)
            local brickCount = brickShed.data.brickCount or 0
            local item = tes3.getObject(Brick.rawId)
            ---@type CraftingFramework.MaterialStorage.storedMaterial
            local storedMaterial = {
                item = item,
                count = brickCount,
                storedIn = reference,
                storageInstance = self
            }
            return { storedMaterial }
        end)
    end,
    removeItem = function(self, params)
        if params.item.id:lower() ~= Brick.rawId then return 0 end
        return BrickShed.wrap(params.reference, function(brickShed)
            local brickCount = brickShed.data.brickCount or 0
            local count = math.min(brickCount, params.count)
            brickShed.data.brickCount = brickCount - count
            brickShed:updateVisuals()
            logger:debug("Removed %s bricks from shed", count)
            return count
        end) or 0
    end,
}



---Constructor
---@param reference tes3reference
---@return Ashfall.BrickShed|nil
function BrickShed:new(reference)
    if not BrickShed.isBrickShed(reference.baseObject.id) then
        logger:warn("Attempted to create BrickShed with invalid reference: %s", reference.id)
        return nil
    end

    local instance = ItemInstance:new{
        reference = reference,
        dataKey = "Ashfall_BrickShed"
    }
    setmetatable(instance, self)
    self.__index = self

    return instance --[[@as Ashfall.BrickShed]]
end

function BrickShed:updateVisuals()
    local brickCount = self.data.brickCount or 0
    BrickShed.updateSceneNode(self.reference.sceneNode, brickCount)
end

function BrickShed.updateSceneNode(sceneNode, brickCount)
    local switchParent = sceneNode:getObjectByName("BRICK_SWITCHES")

    local OFF = 0
    local ON = 1
    ---@param switchNode niSwitchNode
    for _, switchNode in pairs(switchParent.children) do
        local num = switchNode.name:match("SWITCH_BRICK_(%d+)")
        if num then
            local shouldShow = brickCount >= tonumber(num)
            switchNode.switchIndex = shouldShow and ON or OFF
        else
            logger:warn("Unexpected node in BRICK_SWITCHES: %s", switchNode.name)
            switchNode.switchIndex = OFF
        end
    end

    local topLevel = sceneNode:getObjectByName("SWITCH_TOPLEVEL")
    topLevel.switchIndex = brickCount > 50 and ON or OFF

    sceneNode:update()
end

---Return true if the shed has capacity for more bricks
---@return boolean
function BrickShed:hasCapacity()
    local brickCount = self.data.brickCount or 0
    return brickCount < BrickShed.capacity
end

function BrickShed:addBricks(count)
    local brickCount = self.data.brickCount or 0
    local newCount = math.min(brickCount + count, BrickShed.capacity)
    self.data.brickCount = newCount
    self:updateVisuals()
end

function BrickShed:removeBricks(count)
    local brickCount = self.data.brickCount or 0
    local newCount = math.max(brickCount - count, 0)
    self.data.brickCount = newCount
    self:updateVisuals()
end

---Prompt player to add bricks
function BrickShed:promptAddBricks()
    if not self:hasCapacity() then
        tes3.messageBox("Brick shed is full.")
        return
    end
    local playerBricks = common.helper.getItemCount{
        reference = tes3.player,
        item = Brick.rawId,
    }
    if playerBricks == 0 then
        tes3.messageBox("You have no bricks to add.")
        return
    end

    local brickCount = self.data.brickCount or 0
    local spaceRemaining = BrickShed.capacity - brickCount
    local maxToAdd = math.min(playerBricks, spaceRemaining)

    local t = { amount = maxToAdd }
    common.helper.createSliderPopup{
        label = "Add Bricks",
        min = maxToAdd > 1 and 1 or 0,
        max = maxToAdd,
        varId = "amount",
        table = t,
        okayCallback = function()
            if t.amount == 0 then return end
            common.helper.removeItem{
                reference = tes3.player,
                item = Brick.rawId,
                count = t.amount,
                playSound = true,
            }
            tes3.messageBox("Added %s%s.", t.amount > 1 and t.amount .. " " or "", tes3.getObject(Brick.rawId).name)
            self:addBricks(t.amount)
        end
    }
end


---Prompt player to take bricks
function BrickShed:promptTakeBricks()
    local brickCount = self.data.brickCount or 0
    if brickCount == 0 then
        tes3.messageBox("No bricks to take.")
        return
    end
    local t = { amount = brickCount }
    common.helper.createSliderPopup{
        label = "Take Bricks",
        min = brickCount > 1 and 1 or 0,
        max = brickCount,
        varId = "amount",
        table = t,
        okayCallback = function()
            if t.amount == 0 then return end
            tes3.addItem{
                reference = tes3.player,
                item = Brick.rawId,
                count = t.amount,
                playSound = true,
                showMessage = true,
            }
            self:removeBricks(t.amount)
        end
    }
end

---Wrap a reference in a BrickShed instance if possible, and execute a callback with the instance
---@param reference tes3reference
---@param callback fun(brickShed: Ashfall.BrickShed): any
---@return any
function BrickShed.wrap(reference, callback)
    if reference == nil then return end
    if not BrickShed.isBrickShed(reference.baseObject.id) then return end
    local brickShed = BrickShed:new(reference)
    if callback then
        return callback(brickShed)
    end
end


---@type table<string, craftingFrameworkMenuButtonData>
BrickShed.buttons = {
    craft = {
        text = "Craft",
        showRequirements = function(e)
            return BrickShed.wrap(e.reference, function(brickShed)
                return (brickShed.data.brickCount or 0) > 0
            end) or false
        end,
        callback = function()
            Brick.rawMenuActivator:openMenu()
        end
    },
    addBricks = {
        text = "Add Brick",
        enableRequirements = function(e)
            return BrickShed.wrap(e.reference, function(brickShed)
                local hasCapacity = brickShed:hasCapacity()
                local playerHasBricks = common.helper.getItemCount{
                    reference = tes3.player,
                    item = Brick.rawId,
                } > 0
                return hasCapacity and playerHasBricks
            end)
        end,
        tooltipDisabled = {
            text = function(e)
                return BrickShed.wrap(e.reference, function(brickShed)
                    local hasCapacity = brickShed:hasCapacity()
                    local playerHasBricks = common.helper.getItemCount{
                        reference = tes3.player,
                        item = Brick.rawId,
                    } > 0
                    if not hasCapacity then
                        return "Brick shed is full."
                    elseif not playerHasBricks then
                        return "You have no bricks to add."
                    end
                end) or "Invalid reference."
            end
        },
        callback = function(e)
            BrickShed.wrap(e.reference, function(brickShed)
                brickShed:promptAddBricks()
            end)
        end,
    },

    takeBricks = {
        text = "Take Bricks",
        enableRequirements = function(e)
            return BrickShed.wrap(e.reference, function(brickShed)
                local brickCount = brickShed.data.brickCount or 0
                return brickCount > 0
            end)
        end,
        tooltipDisabled = { text = "No bricks to take." },
        callback = function(e)
            BrickShed.wrap(e.reference, function(brickShed)
                brickShed:promptTakeBricks()
            end)
        end,
    }
}


---@param id string The object ID of the brick shed
function BrickShed.register(id)
    BrickShed.registeredBrickSheds[id:lower()] = true
end

function BrickShed.isBrickShed(id)
    return BrickShed.registeredBrickSheds[id:lower()] ~= nil
end


---@param e CraftingFramework.Craftable.callback.params
function BrickShed.destroyCallback(_, e)
    local reference = e.reference
    BrickShed.wrap(reference, function(brickShed)
        local brickCount = brickShed.data.brickCount or 0
        if brickCount > 0 then
            tes3.addItem{
                reference = tes3.player,
                item = Brick.rawId,
                count = brickCount,
                playSound = false,
                showMessage = true,
            }
            tes3.playSound{
                reference = tes3.player,
                soundPath = "ashfall/brick_lo.wav"
            }
        end
    end)
end

---Find a nearby brick shed reference
---@return Ashfall.BrickShed|nil
function BrickShed.getNearby(maxDistance)
    for _, cell in pairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences{ tes3.objectType.activator} do
            if BrickShed.isBrickShed(ref.baseObject.id) and ref.position:distance(tes3.player.position) < (maxDistance or 2000) then
                return BrickShed:new(ref)
            end
        end
    end
end

return BrickShed