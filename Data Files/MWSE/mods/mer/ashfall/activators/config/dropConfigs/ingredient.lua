local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("ingredient")
local foodConfig = require("mer.ashfall.config.foodConfig")
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")
local LiquidContainer = require("mer.ashfall.liquid.LiquidContainer")

return {
    dropText = function(campfire, item, itemData)
        return string.format("Add %s", item.name)
    end,
    --onDrop for Stew handled separately, this only does tea
    canDrop = function(targetRef, item, itemData)
        local isStewIngred = foodConfig.getStewBuffForId(item)
        if not isStewIngred then
            return false
        end

        if not CampfireUtil.refIsCookingPot(targetRef) then
            return false
        end

        local hasWater = targetRef.data.waterAmount
            and targetRef.data.waterAmount > 0
        if not hasWater then
            return false, "No water in pot."
        end

        local hasLadle = not not targetRef.data.ladle
        if not hasLadle then
            return false, "No ladle in pot."
        end

        return true
    end,
    onDrop = function(targetRef, droppedRef)
        local amount = common.helper.getStackCount(droppedRef)
        local amountAdded = CampfireUtil.addIngredToStew{
            campfire = targetRef,
            count = amount,
            item = droppedRef.object
        }

        logger:debug("amountAdded: %s", amountAdded)
        local remaining = common.helper.reduceReferenceStack(droppedRef, amountAdded)
        if remaining > 0 then
            common.helper.pickUp(droppedRef)
        end
        if amountAdded >= 1 then
            tes3.messageBox("Added %s %s to stew.", amountAdded, droppedRef.object.name)
        else
            tes3.messageBox("You cannot add any more %s.", foodConfig.getFoodTypeResolveMeat(droppedRef.object):lower())
        end
        tes3.playSound{ reference = tes3.player, sound = "ashfall_water" }
    end
}

