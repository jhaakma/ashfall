local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("woodStack")
local config = require ("mer.ashfall.items.woodStack.config")
local WoodStack = {}
local refController = require("mer.ashfall.referenceController")
local MaterialStorage = require("CraftingFramework").MaterialStorage

---@param reference tes3reference
local function isWoodStack(reference)
    return reference.sceneNode and reference.sceneNode:getObjectByName("SWITCH_WOODSTACK") ~= nil
end

refController.registerReferenceController{
    id = "woodStack",
    requirements = function(_, ref)
        return isWoodStack(ref)
    end
}

MaterialStorage:new{
    isStorage = function(self, reference)
        return isWoodStack(reference)
    end,
    getMaterials = function(self, reference)
        local woodAmount = WoodStack.getWoodAmount(reference)
        local item = tes3.getObject("ashfall_firewood")
        ---@type CraftingFramework.MaterialStorage.storedMaterial
        local storedMaterial ={
            item = item,
            count = woodAmount,
            storedIn = reference,
            storageInstance = self
        }
        return {storedMaterial}
    end,
    removeItem = function(self, params)
        if params.item.id:lower() ~= "ashfall_firewood" then return 0 end
        local reference = params.reference
        local woodAmount = WoodStack.getWoodAmount(reference)
        local count = math.min(woodAmount, params.count)
        reference.data.woodAmount = woodAmount - count
        event.trigger("Ashfall:UpdateAttachNodes", { reference = reference })
        logger:debug("Removed %s firewood from %s", count, reference)
        return count
    end
}


function WoodStack.getCapacity(id)
    local conf = config.stacks[id:lower()]
    return conf and conf.capacity or config.defaultCapacity
end

function WoodStack.getWoodAmount(reference)
    if reference.data and reference.data.woodAmount then
        return reference.data.woodAmount
    else
        local conf = config.stacks[reference.id:lower()]
        if conf and conf.minStartingAmount and conf.maxStartingAmount then
            local woodAmount =  math.random(conf.minStartingAmount, conf.maxStartingAmount)
            reference.data.woodAmount = woodAmount
            return woodAmount
        else
            logger:debug("No data or config found for %s, returning 0 woodAmount", reference)
            return 0
        end
    end
end

---@param recipe CraftingFramework.Recipe
function WoodStack.destroyCallback(recipe, e)
    local reference = e.reference
    if reference.data and reference.data.woodAmount and reference.data.woodAmount > 0 then
        local count = reference.data.woodAmount
        local firewood = common.staticConfigs.objectIds.firewood
        tes3.addItem{
            reference = tes3.player,
            count = count,
            item = firewood,
            playSound = true,
            showMessage = true,
        }
    end
end

WoodStack.buttons = {
    addWood = {
        text = "Add Firewood",
        tooltip = function()
            return common.helper.showHint(
                "You can add firewood by dropping it directly onto the wood stack."
            )
        end,
        enableRequirements = function(e)
            local reference = e.reference
            local woodAmount = WoodStack.getWoodAmount(reference)
            local capacity = WoodStack.getCapacity(reference.id)
            logger:debug("woodAmount: %s, capacity: %s", woodAmount, capacity)
            local hasRoom = woodAmount < capacity
            local playerHasWood = common.helper.getItemCount{
                reference = tes3.player,
                item = "ashfall_firewood",
            } > 0
            return hasRoom and playerHasWood
        end,
        tooltipDisabled = {
            text = function()
                local playerHasWood = common.helper.getItemCount{
                    reference = tes3.player,
                    item = "ashfall_firewood",
                } > 0
                return playerHasWood and "Wood Stack is full." or "You have no firewood."
            end
        },
        callback = function(e)
            local reference = e.reference
            local woodAmount = WoodStack.getWoodAmount(reference)
            local capacity = WoodStack.getCapacity(e.reference.object.id )
            logger:debug("woodAmount: %s, capacity: %s", woodAmount, capacity)
            local spaceRemaining = math.max(capacity - woodAmount, 0)
            if spaceRemaining == 0 then
                tes3.messageBox("Wood Stack is full.")
                return
            end
            local playerWood = common.helper.getItemCount{
                reference = tes3.player,
                item = "ashfall_firewood",
            }
            local maxAmount = math.min(spaceRemaining, playerWood)
            logger:debug("maxAmount: %s", maxAmount)
            local t = { amount = maxAmount }
            common.helper.createSliderPopup{
                label = "Add Firewood",
                min = 1,
                max = maxAmount,
                varId = "amount",
                table = t,
                okayCallback = function()
                    common.helper.removeItem{
                        reference = tes3.player,
                        item = "ashfall_firewood",
                        count = t.amount,
                        playSound = true,
                    }
                    tes3.messageBox("Added %s%s.", t.amount > 1 and t.amount .. " " or "", tes3.getObject("ashfall_firewood").name)
                    reference.data.woodAmount = woodAmount + t.amount
                    event.trigger("Ashfall:UpdateAttachNodes", { reference = reference })
                end
            }
        end
    },
    takeWood = {
        text = "Take Firewood",
        enableRequirements = function(e)
            local reference = e.reference
            local woodAmount = WoodStack.getWoodAmount(reference)
            return woodAmount > 0
        end,
        tooltipDisabled = {
            text = "Wood Stack is empty."
        },
        callback = function(e)
            local reference = e.reference
            local woodAmount = WoodStack.getWoodAmount(reference)
            local t = { amount = woodAmount }
            common.helper.createSliderPopup{
                label = "Remove Firewood",
                min = 1,
                max = woodAmount,
                varId = "amount",
                table = t,
                okayCallback = function()
                    tes3.addItem{
                        reference = tes3.player,
                        item = "ashfall_firewood",
                        count = t.amount,
                        playSound = true,
                        showMessage = true,
                    }
                    reference.data.woodAmount = woodAmount - t.amount
                    event.trigger("Ashfall:UpdateAttachNodes", { reference = reference })
                end
            }
        end
    }
}

return WoodStack