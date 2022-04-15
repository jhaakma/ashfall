local common = require("mer.ashfall.common.common")
local logger = common.createLogger("WaterFilter")
local LiquidContainer   = require("mer.ashfall.objects.LiquidContainer")

local function onActivateWaterFilter(_)
    --local ref = e.reference
    timer.delayOneFrame(function()
        tes3ui.showInventorySelectMenu{
            title = "Select Water Container",
            noResultsText = "You have no dirty water to filter.",
            filter = function(e)
                local waterContainer = LiquidContainer.createFromInventory(e.item, e.itemData)
                if waterContainer then
                    local hasWater = waterContainer.waterAmount
                    local waterIsDirty = waterContainer:getLiquidType() == "dirty"
                    if hasWater and waterIsDirty then return true end
                end
                return false
            end,
            callback = function(e)
                if e.item and e.itemData then
                    local waterContainer = LiquidContainer.createFromInventory(e.item, e.itemData)
                    waterContainer.data.waterType = nil
                    tes3.playSound{ sound = "Swim Right"}
                    tes3.messageBox("You filter the water from %s.", e.item.name)
                end
            end
        }
    end)

end

event.register("Ashfall:ActivateWaterFilter", onActivateWaterFilter)