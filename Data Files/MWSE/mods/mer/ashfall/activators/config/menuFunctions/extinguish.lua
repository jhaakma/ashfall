local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("extinguish")
local LiquidContainer = require "mer.ashfall.liquid.LiquidContainer"
local function filterWaterContainer(e)
    ---@type Ashfall.LiquidContainer
    local liquidContainer = LiquidContainer.createFromInventory(e.item, e.itemData)
    return liquidContainer ~= nil
        and liquidContainer:hasWater()
        and (liquidContainer:isWater() or liquidContainer:isTea())
end

return {
    text = "Extinguish",
    showRequirements = function(reference)
        if not reference.supportsLuaData then return false end
        return reference.data.isLit and not reference.data.isStatic
    end,
    tooltip = function()
        return common.helper.showHint("You can extinguish the fire by dropping a water-filled container directly onto it.")
    end,
    callback = function(reference)
        timer.delayOneFrame(function()
            logger:debug("Opening Inventory Select Menu")
            common.helper.showInventorySelectMenu{
                title = "Select Water",
                noResultsText = "You do not have any water to douse the fire.",
                filter = filterWaterContainer,
                callback = function(e)
                    if e.item then
                        local liquidContainer = LiquidContainer.createFromInventory(e.item, e.itemData)
                        if liquidContainer then
                            logger:debug("showInventorySelectMenu Callback")
                            event.trigger("Ashfall:fuelConsumer_Extinguish", {fuelConsumer = reference, playSound = true})
                            liquidContainer:reduce(10)
                            tes3.playSound{ reference = tes3.player, sound = "ashfall_water" }
                        end
                    end

                end,
            }
        end)
    end,


}