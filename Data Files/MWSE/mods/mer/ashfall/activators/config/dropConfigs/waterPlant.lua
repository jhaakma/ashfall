local common = require ("mer.ashfall.common.common")
local LiquidContainer = require("mer.ashfall.liquid.LiquidContainer")
local Planter = require("mer.ashfall.items.planter.Planter")

return {
    dropText = function(target)
        return string.format("Water Planter")
    end,
    --onDrop for Stew handled separately, this only does tea
    canDrop = function(target, item, itemData)
        local vessel = LiquidContainer.createFromInventory(item, itemData)
        local planter = Planter.new(target)
        if not vessel then return false end
        if not planter then return false end
        if not vessel:hasWater() then return false end
        if not planter:canBeWatered() then return false, "Already fully watered" end
        return true
    end,
    onDrop = function(target, reference)
        local vessel = LiquidContainer.createFromReference(reference)
        local planter = Planter.new(target)
        if vessel and planter then
            planter:water(vessel)
            common.helper.pickUp(reference)
        end
    end
}

