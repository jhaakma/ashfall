local common = require ("mer.ashfall.common.common")
local foodConfig      = require("mer.ashfall.config.foodConfig")
local CampfireUtil    = require("mer.ashfall.camping.campfire.CampfireUtil")

return {
    dropText = function(campfire, item, itemData)
        return string.format("Add %s", item.name)
    end,
    --onDrop for Stew handled separately, this only does tea
    canDrop = function(campfire, item, itemData)
        local isStewIngred = foodConfig.getStewBuffForId(item)
        if not isStewIngred then
            return false
        end

        local hasPot = campfire.data.utensil == "cookingPot"
            or common.staticConfigs.cookingPots[item.id:lower()]
        if not hasPot then
            return false
        end

        local hasWater = campfire.data.waterAmount
            and campfire.data.waterAmount > 0
        if not hasWater then
            return false, "No water in pot."
        end

        local hasLadle = campfire.data.ladle == true
        if not hasLadle then
            return false, "No ladle in pot."
        end

        return true
    end,
    onDrop = function(campfire, reference)
        local amount = common.helper.getStackCount(reference)
        local amountAdded = CampfireUtil.addIngredToStew{
            campfire = campfire,
            count = amount,
            item = reference.object
        }

        common.log:debug("amountAdded: %s", amountAdded)
        local remaining = common.helper.reduceReferenceStack(reference, amountAdded)
        if remaining > 0 then
            common.helper.pickUp(reference)
        end
        if amountAdded >= 1 then
            tes3.messageBox("Added %s %s to stew.", amountAdded, reference.object.name)
        else
            tes3.messageBox("You cannot add any more %s.", foodConfig.getFoodTypeResolveMeat(reference.object):lower())
        end
        tes3.playSound{ reference = tes3.player, sound = "Swim Left" }
    end
}

