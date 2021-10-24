local common = require ("mer.ashfall.common.common")
local LiquidContainer = require("mer.ashfall.objects.LiquidContainer")
local teaConfig       = require("mer.ashfall.config.teaConfig")

return {
    dropText = function(campfire, item, itemData)
        --Tea
        local teaData = teaConfig.teaTypes[item.id:lower()]
        return string.format("Brew %s", teaData.teaName)
    end,
    --onDrop for Stew handled separately, this only does tea
    canDrop = function(campfire, item, itemData)
        local hasWater = campfire.data.waterAmount and campfire.data.waterAmount > 0
        local hasKettle = campfire.data.utensil == "kettle"
        local waterClean = not campfire.data.waterType
        local isTeaLeaf = teaConfig.teaTypes[item.id:lower()]
        return hasWater and hasKettle and waterClean and isTeaLeaf
    end,
    onDrop = function(campfire, reference)
        campfire.data.waterType = reference.object.id:lower()
        campfire.data.teaProgress = 0
        local currentHeat = campfire.data.waterHeat or 0
        local newHeat = currentHeat + math.max(0, (campfire.data.waterHeat - 10))
        --CampfireUtil.setHeat(campfire.data, newHeat, campfire)
        campfire.data.waterHeat = newHeat
        local skillSurvivalTeaBrewIncrement = 5
        common.skills.survival:progressSkill(skillSurvivalTeaBrewIncrement)
        local remaining = common.helper.reduceReferenceStack(reference, 1)
        if remaining > 0 then
            common.helper.pickUp(reference)
        end
        tes3.messageBox("Added %s", reference.object.name)
        tes3.playSound{ reference = tes3.player, sound = "Swim Left" }
    end
}