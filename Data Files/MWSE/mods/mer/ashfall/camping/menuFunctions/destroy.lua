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

        if not campfire.data.isLit  then
            local recoveredFuel =  math.floor(campfire.data.fuelLevel * 0.5)
            if recoveredFuel >= 1 then
                local woodId = "ashfall_firewood"
                tes3.addItem{
                    reference = tes3.player,
                    item = woodId,
                    count = recoveredFuel,
                    playSound = false,
                }
                tes3.messageBox(tes3.findGMST(tes3.gmst.sNotifyMessage61).value, recoveredFuel, tes3.getObject(woodId).name)
            end

            local charcoal = campfire.data.charcoalLevel or 0
            local recoveredCoal = math.floor(charcoal * 0.75)
            recoveredCoal = math.clamp(recoveredCoal, 0, common.staticConfigs.maxWoodInFire)
            if recoveredCoal > 1 then
                local coalId = "ashfall_ingred_coal_01"
                tes3.addItem{
                    reference = tes3.player,
                    item = coalId,
                    count = recoveredCoal,
                    playSound = false,
                }
                tes3.messageBox(tes3.findGMST(tes3.gmst.sNotifyMessage61).value, recoveredCoal, tes3.getObject(coalId).name)
            end
        end
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
        event.trigger("Ashfall:fuelConsumer_Extinguish", {fuelConsumer = campfire})
        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
        common.helper.yeet(campfire)
    end
}