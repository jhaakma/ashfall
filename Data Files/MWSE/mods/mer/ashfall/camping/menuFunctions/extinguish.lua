return {
    text = "Extinguish",
    requirements = function(campfire)
        return campfire.data.isLit and not campfire.data.isStatic
    end,
    callback = function(campfire)
        event.trigger("Ashfall:fuelConsumer_Extinguish", {fuelConsumer = campfire, playSound = true})
        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
    end,
}