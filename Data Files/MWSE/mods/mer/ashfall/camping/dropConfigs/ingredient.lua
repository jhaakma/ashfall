local common = require ("mer.ashfall.common.common")
local LiquidContainer = require("mer.ashfall.objects.LiquidContainer")
local teaConfig       = require("mer.ashfall.config.teaConfig")
local foodConfig      = require("mer.ashfall.config.foodConfig")
local CampfireUtil    = require("mer.ashfall.camping.campfire.CampfireUtil")

return {
    dropText = function(campfire, item, itemData)
        return string.format("Add %s", item.name)
    end,
    --onDrop for Stew handled separately, this only does tea
    canDrop = function(campfire, item, itemData)
        local hasPot = campfire.data.utensil == "cookingPot"
        local hasWater = campfire.data.waterAmount
            and campfire.data.waterAmount > 0
        local isStewIngred = foodConfig.getStewBuffForId(item)

        local attachedToCampfire = campfire.data.waterCapacity ~= nil
        local hasLadle = campfire.data.ladle == true
        return hasPot
            and attachedToCampfire
            and hasWater
            and hasLadle
            and isStewIngred
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

