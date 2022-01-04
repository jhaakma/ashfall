local common = require ("mer.ashfall.common.common")

return {
    text = "Pick Up",
    showRequirements = function(campfire)
        return (
            not campfire.data.grillId and
            not campfire.data.utensilId and
            not campfire.data.supportsId and
            not campfire.data.bellowsId and
            campfire.data.ashfallCookerMiscId
        )
    end,
    --only enable if the campfire is not lit
    enableRequirements = function (campfire)
        return not campfire.data.isLit
    end,
    tooltipDisabled = function(campfire)
        return {
            text = "Must be extinguished before picking up."
        }
    end,
    callback = function(campfire)
        campfire.data.destroyed = true
        local recoveredFuel =  math.floor(campfire.data.fuelLevel / 2)
        if not campfire.data.isLit and recoveredFuel >= 1 then
            mwscript.addItem{
                reference = tes3.player,
                item = common.staticConfigs.objectIds.firewood,
                count = recoveredFuel
            }
            tes3.messageBox(tes3.findGMST(tes3.gmst.sNotifyMessage61).value, recoveredFuel, tes3.getObject(common.staticConfigs.objectIds.firewood).name)
        end
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
        event.trigger("Ashfall:fuelConsumer_Extinguish", {fuelConsumer = campfire})
        mwscript.addItem{
            reference = tes3.player,
            item = campfire.data.ashfallCookerMiscId,
            count = 1
        }
        tes3.messageBox(tes3.findGMST(tes3.gmst.sNotifyMessage61).value, 1, tes3.getObject(campfire.data.ashfallCookerMiscId).name)
        common.helper.yeet(campfire)
    end
}