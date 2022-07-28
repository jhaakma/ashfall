local common = require ("mer.ashfall.common.common")
return {
    text = "Empty",
    showRequirements = function(reference)
        local isBottle = common.staticConfigs.bottleList[reference.object.id:lower()]
        return isBottle
            and reference.data.waterAmount
            and reference.data.waterAmount > 0
    end,
    callback = function(reference)
        tes3ui.showMessageMenu{
            message = string.format("Empty %s?",  common.helper.getGenericUtensilName(reference.object)),
            buttons = {
                {
                    text = "Yes",
                    callback = function()
                        event.trigger("Ashfall:Campfire_clear_utensils", { campfire = reference})
                        tes3.playSound{ reference = tes3.player, pitch = 0.8, sound = "ashfall_water" }
                        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
                    end
                }
            },
            cancels = true,
        }
    end
}