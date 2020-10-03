local common = require ("mer.ashfall.common.common")
local teaConfig = common.staticConfigs.teaConfig
return {
    text = "Add water",
    requirements = function(campfire)
        local needsWater = (
            not campfire.data.waterAmount or
            campfire.data.waterAmount < common.staticConfigs.capacities[campfire.data.utensil]
        )
        local hasUtensil = (
            campfire.data.utensil == "kettle" or 
            campfire.data.utensil == "cookingPot"
        )
        local isTea = teaConfig.teaTypes[campfire.data.waterType] ~= nil
        return needsWater and hasUtensil and not isTea
    end,
    callback = function(campfire)
        timer.delayOneFrame(function()
            tes3ui.showInventorySelectMenu{
                title = "Select Water Container:",
                noResultsText = "You do not have any water.",
                filter = function(e)
                    if not e.itemData then return false end
                    local hasWater = (
                        e.itemData.data.waterAmount and 
                        e.itemData.data.waterAmount > 0
                    )
                    local hasStew = e.itemData.data.stewLevels
                    local hasTea = e.itemData.data.waterType and e.itemData.data.waterType ~= "dirty"
                    return (hasWater and (not hasStew) and (not hasTea)) == true
                end,
                callback = function(e)
                    if e.item then
                        local maxAmount = math.min(
                            ( e.itemData.data.waterAmount or 0 ),
                            ( common.staticConfigs.capacities[campfire.data.utensil] - ( campfire.data.waterAmount or 0 ))
                        )
                        local t = { amount = math.min(maxAmount, 50)}
                        local function transferWater()
                            --transfer water
                            campfire.data.waterAmount = campfire.data.waterAmount or 0
                            local waterBefore = campfire.data.waterAmount
                            local waterTransferred = t.amount
                            e.itemData.data.waterAmount = e.itemData.data.waterAmount - waterTransferred

                            campfire.data.waterAmount = campfire.data.waterAmount + waterTransferred
                            local waterAfter = campfire.data.waterAmount
                            tes3ui.updateInventoryTiles()

                            --If dirty
                            if e.itemData.data.waterType == "dirty" then
                                campfire.data.waterType = "dirty"
                            end
                            --clear contents if empty
                            if e.itemData.data.waterAmount == 0 then
                                e.itemData.data.waterType = nil
                            end

                            local ratio = waterBefore / waterAfter
                            --reduce ingredient levels
                            if campfire.data.stewLevels then
                                for name, stewLevel in pairs( campfire.data.stewLevels) do
                                    campfire.data.stewLevels[name] = stewLevel * ratio
                                end
                            end

                            --Cool down stew
                            campfire.data.waterHeat = campfire.data.waterHeat or 0
                            local before = campfire.data.waterHeat
                            campfire.data.waterHeat = math.max(( campfire.data.waterHeat - common.staticConfigs.stewWaterCooldownAmount * ratio ), 0)
                            local after = campfire.data.waterHeat
                            if before > common.staticConfigs.hotWaterHeatValue and after < common.staticConfigs.hotWaterHeatValue then
                                tes3.removeSound{
                                    reference = campfire, 
                                    sound = "ashfall_boil"
                                }
                            end

                            tes3.playSound{ reference = tes3.player, sound = "Swim Right" }
                            event.trigger("Ashfall:registerReference", { reference = campfire})
                            --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
                        end
                        common.helper.createSliderPopup{
                            label = "Add water",
                            min = 0,
                            max = maxAmount,
                            varId = "amount",
                            table = t,
                            okayCallback = transferWater
                        }

                    end
                end
            }
        end)

    end
}