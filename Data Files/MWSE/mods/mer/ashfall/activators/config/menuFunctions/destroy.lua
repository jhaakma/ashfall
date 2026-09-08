local common = require ("mer.ashfall.common.common")
local Campfire = require("mer.ashfall.camping.campfire.Campfire")

local function doDestroy(campfire, doHarvest)
    campfire.data.destroyed = true

    if doHarvest then
        for _, id in pairs{ "ashfall_ingred_woodash_01", "ashfall_ingred_coal_01" } do
            local charcoal = campfire.data.charcoalLevel or 0
            local recoveredAmount = math.floor(charcoal * 0.5) * math.random(0.5, 1.5) --Recover 25% of charcoal as either ash or charcoal, with some variance
            local maxFuel = Campfire.getMaxFuel(campfire.object.id)
            recoveredAmount = math.clamp(recoveredAmount, 0, maxFuel)
            if recoveredAmount > 1 then
                tes3.addItem{
                    reference = tes3.player,
                    item = id,
                    count = math.floor(recoveredAmount),
                    playSound = false,
                    showMessage = true
                }
            end
        end
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
        common.helper.fadeTimeOut(0.1, 1, function() end)
    end
    tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
    event.trigger("Ashfall:fuelConsumer_Extinguish", {fuelConsumer = campfire})
    common.helper.yeet(campfire)
end


return {
    text = "Destroy Campfire",
    showRequirements = function(reference)
        if not reference.supportsLuaData then return false end
        return (
            not reference.data.grillId and
            not reference.data.utensilId and
            not reference.data.isLit and
            not reference.data.supportsId and
            not reference.data.bellowsId and
            not (reference.data.dynamicConfig and reference.data.dynamicConfig.campfire == "static")
        )
    end,
    callback = function(campfire)
        timer.delayOneFrame(function()
            tes3ui.showMessageMenu{
                message = "Destroy Campfire",
                buttons = {
                    {
                        text = "Harvest",
                        callback = function()
                            doDestroy(campfire, true)
                        end,
                    },
                    {
                        text = "Destroy",
                        callback = function()
                            doDestroy(campfire)
                        end,
                    }
                },
                cancels = true
            }
        end)
    end
}