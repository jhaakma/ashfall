local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("tea")
local teaConfig       = require("mer.ashfall.config.teaConfig")
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")
return {
    dropText = function(campfire, item, itemData)
        local teaData = teaConfig.teaTypes[item.id:lower()]
        return string.format("Brew %s", teaData.teaName)
    end,
    canDrop = function(campfire, item, itemData)
        local isTeaLeaf = teaConfig.teaTypes[item.id:lower()]
        if not isTeaLeaf then
            return false
        end

        local hasWater = campfire.data.waterAmount and campfire.data.waterAmount > 0
        if not hasWater then
            return false, "No water in campfire."
        end

        local hasKettle = campfire.data.utensil == "kettle"
            or common.staticConfigs.kettles[campfire.object.id:lower()]
        if not hasKettle then
            return false
        end

        local waterClean = not campfire.data.waterType
        if not waterClean then
            return false, "Clean water required to make tea."
        end

        return true
    end,
    onDrop = function(campfire, reference)
        campfire.data.waterType = reference.object.id:lower()
        campfire.data.teaProgress = 0

        local currentHeat = campfire.data.waterHeat or 0
        logger:debug("currentHeat: %s", currentHeat)
        local newHeat = math.max(0, (campfire.data.waterHeat - 10))
        logger:debug("newHeat: %s", newHeat)
        CampfireUtil.setHeat(campfire.data, newHeat, campfire)
        logger:debug("campfire.data.waterHeat: %s", campfire.data.waterHeat)

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