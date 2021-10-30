local common = require ("mer.ashfall.common.common")
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")
local teaConfig = common.staticConfigs.teaConfig
local skillSurvivalTeaBrewIncrement = 5
return {
    text = "Brew Tea",
    showRequirements = function(campfire)
        return (
            campfire.data.utensil == "kettle" and
            campfire.data.waterAmount and
            campfire.data.waterAmount > 0 and
            campfire.data.waterType == nil
        )
    end,
    callback = function(campfire)
        timer.delayOneFrame(function()
            common.data.inventorySelectTeaBrew = true
            tes3ui.showInventorySelectMenu{
                title = "Brew Tea:",
                noResultsText = "You have no suitable ingredients.",
                filter = function(e)
                    return teaConfig.teaTypes[e.item.id:lower()] ~= nil
                end,
                callback = function(e)
                    common.data.inventorySelectTeaBrew = nil
                    if e.item then
                        campfire.data.waterType = e.item.id:lower()
                        campfire.data.teaProgress = 0
                        local currentHeat = campfire.data.waterHeat or 0
                        local newHeat = currentHeat + math.max(0, (campfire.data.waterHeat - 10))
                        CampfireUtil.setHeat(campfire.data, newHeat, campfire)

                        common.skills.survival:progressSkill(skillSurvivalTeaBrewIncrement)

                        tes3.player.object.inventory:removeItem{
                            mobile = tes3.mobilePlayer,
                            item = e.item,
                            itemData = e.itemData
                        }
                        tes3ui.forcePlayerInventoryUpdate()
                        tes3.playSound{ reference = tes3.player, sound = "Swim Left" }
                        event.trigger("Ashfall:UpdateAttachNodes", { campfire = campfire})
                    end
                end
            }
            timer.delayOneFrame(function()
                common.data.inventorySelectTeaBrew = nil
            end)
        end)
    end
}