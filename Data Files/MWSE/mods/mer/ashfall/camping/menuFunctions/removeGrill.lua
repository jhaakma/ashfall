return {
    text = "Remove Grill",
    requirements = function(campfire)
        return ( 
            campfire.data.hasGrill and
            campfire.data.dynamicConfig and
            campfire.data.dynamicConfig.grill == "dynamic"
        )
    end,
    callback = function(campfire)
        mwscript.addItem{
            reference = tes3.player, 
            item = "ashfall_grill",
            count = 1
        }
        campfire.data.hasGrill = false
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
    end
    ,
}