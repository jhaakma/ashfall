local common = require("mer.ashfall.common.common")
local logger = common.createLogger("main")
local Interop = require("mer.ashfall.interop")
local versionController = require("mer.ashfall.versionController")
--[[
    Plugin: Ashfall.esp
--]]
local function initialized()
    if tes3.isModActive("Ashfall.esp") then
        versionController.checkForUpdates()

        -- This has to go first so events trigger properly
        require("mer.ashfall.referenceController")

        require("mer.ashfall.survival")

        require("mer.ashfall.intro")
        require("mer.ashfall.scriptTimer")
        -- needs
        require("mer.ashfall.needs.waterController")
        require("mer.ashfall.ui.needsTooltips")
        require("mer.ashfall.needs.extremeEffects")
        require("mer.ashfall.needs.diseasedMeat")

        require("mer.ashfall.camping")
        require("mer.ashfall.items")
        require("mer.ashfall.effects.frostbreath")
        require("mer.ashfall.effects.keybinds")
        require("mer.ashfall.ui.hud")
        require("mer.ashfall.ui.tooltipsCompleteInterop")
        require("mer.ashfall.tempEffects.ratings.ratingEffects")

        require("mer.ashfall.quickKeys")
        require("mer.ashfall.activators.activationEvent")

        require("mer.ashfall.merchants.merchantController")
        require("mer.ashfall.merchants.priceController")
        require("mer.ashfall.merchants.waterMerchant")
        require("mer.ashfall.merchants.stewMerchant")
        require("mer.ashfall.branch.branches")

        require("mer.ashfall.bushcrafting")
        require("mer.ashfall.gearPlacement")
        require('mer.ashfall.harvest.harvestController')
        require("mer.ashfall.cooking")
        require("mer.ashfall.ui.sephInterop")
        event.trigger("Ashfall:Interop", Interop)
        logger:info("%s Initialised", versionController.getVersion())
    end
end

event.register("UIEXP:sandboxConsole", function(e)
    e.sandbox.ashfall = table.copy(Interop)
    e.sandbox.ashfall.data = common.data
end)

-- Need to initialise immediately
require("mer.ashfall.effects.faderController")


event.register("initialized", initialized)

require("mer.ashfall.MCM.mcm")

