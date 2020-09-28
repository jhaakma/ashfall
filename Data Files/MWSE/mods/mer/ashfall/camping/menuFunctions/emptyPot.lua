local common = require ("mer.ashfall.common.common")
return {
    text = "Empty Pot",
    requirements = function(campfire)
        return (
            campfire.data.utensil == "cookingPot" and
            ( campfire.data.waterAmount and
            campfire.data.waterAmount > 0 )
        )
    end,
    callback = function(campfire)
        common.helper.messageBox{
            message = "Empty Cooking Pot?",
            buttons = {
                { 
                    text = "Yes",
                    callback = function()
                        event.trigger("Ashfall:Campfire_clear_utensils", { campfire = campfire})
                        tes3.playSound{ reference = tes3.player, pitch = 0.8, sound = "Swim Left" }
                        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
                    end
                },
                {
                    text = "Cancel"
                }
            }
        }
    end
}