local common = require ("mer.ashfall.common.common")
local Material = require("CraftingFramework").Material
--Calculate how much fuel is added per piece of firewood based on Survival skill

local function getWoodFuel()
    local survivalEffect = common.helper.clampmap(common.skills.survival.current, 0, 100, 1, 1.5)
    return common.staticConfigs.firewoodFuelMulti * survivalEffect
end

local function getFirewoodCount()
    -- local firewood = tes3.getObject(common.staticConfigs.objectIds.firewood)
    -- return common.helper.getItemCount{ reference = tes3.player, item = firewood }
    local firewoodMaterial = Material.getMaterial("wood")
    return firewoodMaterial:getCount()
end

local function canAddFireWoodToCampfire(reference)
    local fuelLevel = reference.data.fuelLevel or 0
    return fuelLevel < common.staticConfigs.maxWoodInFire
end

local function getDisabledText(reference)
    return {
        text = canAddFireWoodToCampfire(reference) and "You have no Firewood." or "Max fuel level reached."
    }
end

return {
    text = "Add Firewood",
    showRequirements = function(reference)
        return reference.supportsLuaData
    end,
    enableRequirements = function(reference)
        return reference.supportsLuaData
        and getFirewoodCount() > 0
        and canAddFireWoodToCampfire(reference)
    end,
    tooltip = function()
        return common.helper.showHint(
            "You can add firewood by dropping it directly onto the fire."
        )
    end,
    tooltipDisabled = getDisabledText,
    callback = function(reference)
        tes3.playSound{
            reference = tes3.player,
            sound = "ashfall_add_wood",
            loop = false
        }
        reference.data.fuelLevel = (reference.data.fuelLevel or 0) + getWoodFuel()
        reference.data.burned = reference.data.isLit == true
        --common.helper.removeItem{ reference = tes3.player, item = common.staticConfigs.objectIds.firewood, playSound = false }
        local firewoodMaterial = Material.getMaterial("wood")
        firewoodMaterial:use(1)

        event.trigger("Ashfall:UpdateAttachNodes", { reference = reference})
    end,
}