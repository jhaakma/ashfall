local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("AddFirewoodMenu")
local Material = require("CraftingFramework").Material
local Firewood = require("mer.ashfall.camping.Firewood")
--Calculate how much fuel is added per piece of firewood based on Survival skill



local function getDisabledText(reference)
    return {
        text = Firewood.canAddFireWoodToCampfire(reference) and "You have no Firewood." or "Max fuel level reached."
    }
end

return {
    text = "Add Firewood",
    showRequirements = function(reference)
        return reference.supportsLuaData
    end,
    enableRequirements = function(reference)
        return reference.supportsLuaData
        and Firewood.getFirewoodCount() > 0
        and Firewood.canAddFireWoodToCampfire(reference)
    end,
    tooltip = function()
        return common.helper.showHint(
            "You can add firewood by dropping it directly onto the fire."
        )
    end,
    tooltipDisabled = getDisabledText,
    callback = function(reference)

        local capacity = Firewood.getFirewoodCapacity(reference)

        local safeRef = tes3.makeSafeObjectHandle(reference)
        local eventData = {count = 1}
        common.helper.createSliderPopup{
            label = "How many?",
            min = 1,
            max = capacity,
            jump = 1,
            table = eventData,
            varId = "count",
            okayCallback = function()
                if not safeRef:valid() then
                    logger:warn("Add Firewood menu callback called but reference is no longer valid")
                    return
                end
                logger:info("Adding %s firewood to campfire", eventData.count)
                reference = safeRef:getObject()
                tes3.playSound{
                    reference = tes3.player,
                    sound = "ashfall_add_wood",
                    loop = false
                }
                reference.data.fuelLevel = (reference.data.fuelLevel or 0) + Firewood.getWoodFuel() * eventData.count
                reference.data.burned = reference.data.isLit == true
                local firewoodMaterial = Material.getMaterial("wood")
                firewoodMaterial:use(eventData.count)
                event.trigger("Ashfall:UpdateAttachNodes", { reference = reference})
            end
        }
    end,
}