local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("hangUtensil")
local CampfireUtil = require ("mer.ashfall.camping.campfire.CampfireUtil")

return {
    dropText = function(campfire, item, itemData)
        return string.format("Attach %s", common.helper.getGenericUtensilName(item))
    end,
    canDrop = function(campfire, item, itemData)
        --This one is basically to stop being able to attach to misc supports
        --(TODO: allow this and handle all the jazz that goes with it)
        local canAttachSupports = CampfireUtil.refCanHangUtensil(campfire)
        if not canAttachSupports then
            return false
        end
        local canBeAttached = CampfireUtil.itemCanBeHanged(item)
        if not canBeAttached then
            return false
        end
        local campfireHasRoom = not campfire.data.utensilId
        if not campfireHasRoom then
            return false, "Campfire already has a utensil."
        end
        return true
    end,
    onDrop = function(campfire, reference)
        local utensilData = common.staticConfigs.utensils[reference.object.id:lower()]
        if utensilData.type == "cookingPot" then
            for ladleId, _ in pairs(common.staticConfigs.ladles) do
                if tes3.getObject(ladleId) then
                    if tes3.getItemCount{ reference = tes3.player, item = ladleId} > 0 then
                        logger:debug("Found a ladle to attach to the cooking pot")
                        tes3.removeItem{ reference = tes3.player, item = ladleId, playSound = false }
                        campfire.data.ladle = ladleId:lower()
                        break
                    end
                end
            end
        end
        campfire.data.utensil = utensilData.type
        campfire.data.utensilId = reference.object.id:lower()
        campfire.data.utensilPatinaAmount = reference.data and reference.data.patinaAmount
        campfire.data.waterCapacity = utensilData.capacity or 100


        --If utensil has water, initialise the campfire with it
        if reference.data then
            campfire.data.waterAmount =  reference.data.waterAmount
            campfire.data.stewLevels =  reference.data.stewLevels
            campfire.data.stewProgress = reference.data.stewProgress
            campfire.data.teaProgress = reference.data.teaProgress
            campfire.data.waterType =  reference.data.waterType
            campfire.data.waterHeat = reference.data.waterHeat or 0
            campfire.data.ladle = reference.data.ladle or campfire.data.ladle
            campfire.data.lastWaterUpdated = nil
            campfire.data.lastBrewUpdated = nil
            campfire.data.lastStewUpdated = nil
            campfire.data.lastWaterHeatUpdated = nil
        end

        local remaining = common.helper.reduceReferenceStack(reference, 1)
        if remaining > 0 then
            common.helper.pickUp(reference)
        end
        tes3.messageBox("Attached %s", common.helper.getGenericUtensilName(reference.object))
        logger:debug("Set water capacity to %s", campfire.data.waterCapacity)
        logger:debug("Set water heat to %s", campfire.data.waterHeat)
        logger:debug("Set lastWaterUpdated to %s", campfire.data.lastWaterUpdated)
        event.trigger("Ashfall:registerReference", { reference = campfire})
        event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire})
    end
}