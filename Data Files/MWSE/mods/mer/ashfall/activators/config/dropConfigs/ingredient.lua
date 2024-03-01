local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("ingredient")
local foodConfig = require("mer.ashfall.config.foodConfig")
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")
local LiquidContainer = require("mer.ashfall.liquid.LiquidContainer")

return {
    dropText = function(campfire, item, itemData)
        return string.format("Add %s", item.name)
    end,
    canDrop = function(targetRef, item, itemData)
        local isStewIngred = foodConfig.getStewBuffForId(item)
        if not isStewIngred then
            return false
        end

        local liquidContainer = LiquidContainer.createFromReference(targetRef)
        if not liquidContainer then
            return false
        end

        if not liquidContainer.holdsStew then
            return false
        end

        if liquidContainer.waterAmount <= 0 then
            return false
        end

        local liquidType = liquidContainer:getLiquidType()
        if liquidType == "dirty" then
            return false, "Water is dirty."
        end

        if liquidType == "tea" then
            return false
        end

        if not liquidContainer.ladle then
            return false, "Needs a ladle."
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

