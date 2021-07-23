--[[
    Plugin: Ashfall.esp
--]]

if not mwse.loadConfig("ashfall") then
    mwse.saveConfig("ashfall", {})
end

local function getVersion()
    local versionFile = io.open("Data Files/MWSE/mods/mer/ashfall/version.txt", "r")
    local version = ""
    for line in versionFile:lines() do -- Loops over all the lines in an open text file
        version = line
    end
    return version
end

local common = require ("mer.ashfall.common.common")
local Interop = require ("mer.ashfall.interop")

local function initialized()
    if tes3.isModActive("Ashfall.esp") then
        
        require("mer.ashfall.survival")
        -- load modules
        require("mer.ashfall.referenceController")
        
        require("mer.ashfall.intro")
        require ("mer.ashfall.scriptTimer")
        --needs
        require("mer.ashfall.needs.waterController")
        require("mer.ashfall.needs.needsTooltips")
        require("mer.ashfall.needs.extremeEffects")
        require("mer.ashfall.needs.diseasedMeat")

        require("mer.ashfall.camping.camping")
        require("mer.ashfall.items.items")
        require("mer.ashfall.effects.frostbreath")
        require("mer.ashfall.effects.keybinds")
        require("mer.ashfall.ui.hud")
        require("mer.ashfall.ui.itemTooltips")
        require("mer.ashfall.tempEffects.ratings.ratingEffects")

        require("mer.ashfall.quickKeys")
        require("mer.ashfall.activators.activationEvent")
        
        require("mer.ashfall.bedrollController")        
        require("mer.ashfall.backpackController")
        require("mer.ashfall.merchants.merchantController")
        require("mer.ashfall.merchants.priceController")
        require("mer.ashfall.merchants.waterMerchant")
        require("mer.ashfall.merchants.stewMerchant")
        require("mer.ashfall.branch.branches")

        require("mer.ashfall.crafting.controllers")
        
        event.trigger("Ashfall:Interop", Interop)
        common.log:info("%s Initialised", getVersion())

        
    end
end

event.register("UIEXP:sandboxConsole", function(e)
    e.sandbox.ashfall = table.copy(Interop)
    e.sandbox.ashfall.data = common.data
end)

--Need to initialise immediately
require ("mer.ashfall.effects.faderController")

event.register("initialized", initialized)

require("mer.ashfall.MCM.mcm")




