local common = require ("mer.ashfall.common.common")

return {
    text = "Pick Up",
    showRequirements = function(reference)
        return (not reference.data.grillId)
            and (not reference.data.utensilId)
            and (not reference.data.supportsId)
            and (not reference.data.bellowsId)
            and (reference.data.ashfallCookerMiscId ~= nil)
    end,
    --only enable if the reference is not lit
    enableRequirements = function (reference)
        return not reference.data.isLit
    end,
    tooltipDisabled = function(_)
        return {
            text = "Must be extinguished before picking up."
        }
    end,
    callback = function(reference)
        reference.data.destroyed = true
        local recoveredFuel =  math.floor(reference.data.fuelLevel / 2)
        if not reference.data.isLit and recoveredFuel >= 1 then
            tes3.addItem{
                reference = tes3.player,
                item = common.staticConfigs.objectIds.firewood,
                count = recoveredFuel,
                showMessage = true,
            }
        end
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
        event.trigger("Ashfall:fuelConsumer_Extinguish", {fuelConsumer = reference})
        tes3.addItem{
            reference = tes3.player,
            item = reference.data.ashfallCookerMiscId,
            count = 1,
            showMessage = true,
        }
        common.helper.yeet(reference)
    end
}