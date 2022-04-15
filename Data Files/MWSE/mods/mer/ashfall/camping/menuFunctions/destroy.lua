local common = require ("mer.ashfall.common.common")

return {
    text = "Destroy Campfire",
    showRequirements = function(campfire)
        return (
            not campfire.data.grillId and
            not campfire.data.utensilId and
            not campfire.data.isLit and
            not campfire.data.supportsId and
            not campfire.data.bellowsId and
            (campfire.data.dynamicConfig and
            campfire.data.dynamicConfig.campfire == "dynamic")
        )
    end,
    callback = function(campfire)
        campfire.data.destroyed = true
        local recoveredFuel =  math.floor(campfire.data.fuelLevel / 2)
        if not campfire.data.isLit and recoveredFuel >= 1 then
            local id = "ashfall_ingred_coal_01"
            tes3.addItem{
                reference = tes3.player,
                item = id,
                count = recoveredFuel
            }

            tes3.messageBox(tes3.findGMST(tes3.gmst.sNotifyMessage61).value, recoveredFuel, tes3.getObject(id).name)
        end
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
        event.trigger("Ashfall:fuelConsumer_Extinguish", {fuelConsumer = campfire})
        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
        common.helper.yeet(campfire)
    end
}