local common = require ("mer.ashfall.common.common")
local HeatUtil = require("mer.ashfall.heat.HeatUtil")
local teaConfig = common.staticConfigs.teaConfig
local skillConfigs = require("mer.ashfall.config.skillConfigs")
return {
    text = "Brew Tea",
    showRequirements = function(ref)
        local isKettle = ref.data.utensil == "kettle"
            or common.staticConfigs.kettles[ref.object.id:lower()]
        local hasWater = ref.data.waterAmount and ref.data.waterAmount > 0
        return isKettle and hasWater and ref.data.waterType == nil
    end,
    tooltip = function()
        return common.helper.showHint(
            "You can brew tea by dragging and dropping a herb directly onto the teapot."
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
                        local newHeat = math.max(0, (campfire.data.waterHeat - 10))
                        HeatUtil.setHeat(campfire.data, newHeat, campfire)

                        common.skills.survival:exercise(skillConfigs.survival.brewTea.skillGain)

                        tes3.player.object.inventory:removeItem{
                            mobile = tes3.mobilePlayer,
                            item = e.item,
                            itemData = e.itemData
                        }
                        tes3ui.forcePlayerInventoryUpdate()
                        tes3.playSound{ reference = tes3.player, sound = "ashfall_water" }
                        event.trigger("Ashfall:UpdateAttachNodes", { reference = campfire})
                    end
                end
            }
            timer.delayOneFrame(function()
                common.data.inventorySelectTeaBrew = nil
            end)
        end)
    end
}