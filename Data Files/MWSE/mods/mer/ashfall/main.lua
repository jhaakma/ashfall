local common = require("mer.ashfall.common.common")
local logger = common.createLogger("main")
local Interop = require("mer.ashfall.interop")
local versionController = require("mer.ashfall.common.versionController")
--[[
    Plugin: Ashfall.esp
--]]
local function initialized()
    if tes3.isModActive("Ashfall.esp") then
        versionController.checkForUpdates()

        -- This has to go first so events trigger properly
        require("mer.ashfall.referenceController")

        --interops/integrations
        --This has to run before some other scripts to ensure the lists are up to date
        require("mer.ashfall.ui.sephInterop")
        require("mer.ashfall.integrations")

        require("mer.ashfall.activators.activatorController")
        require("mer.ashfall.activators")
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
        require("mer.ashfall.tempEffects.globalModifiers")

        require("mer.ashfall.quickKeys")
        require("mer.ashfall.activators.activationEvent")

        require("mer.ashfall.merchants.merchantController")
        require("mer.ashfall.merchants.priceController")
        require("mer.ashfall.merchants.waterMerchant")
        require("mer.ashfall.merchants.stewMerchant")
        require("mer.ashfall.branch.branches")

        require("mer.ashfall.bushcrafting")
        require("mer.ashfall.gearPlacement")
        require('mer.ashfall.harvest')
        require('mer.ashfall.skinning')
        require("mer.ashfall.cooking")
        require("mer.ashfall.liquid")

        require("mer.ashfall.effects.shader")
        --Enable Verticalisation
        include("CraftingFramework.components.Verticaliser")

        event.trigger("Ashfall:Interop", Interop)

        logger:info("Initialized v%s", versionController.getVersion())
    else
        logger:warn("Ashfall.esp is not active")
    end
end

event.register("UIEXP:sandboxConsole", function(e)
    e.sandbox.ashfall = table.copy(Interop)
    e.sandbox.ashfall.data = common.data
    e.sandbox.ashfall.common = common
end)

-- Need to initialise immediately
require("mer.ashfall.effects.faderController")

event.register(tes3.event.dialogueEnvironmentCreated, function(e)
    ---@class mwseDialogueEnvironment
    local env = e.environment
    env.Ashfall = Interop
end)

event.register("initialized", initialized, { priority = -50})

require("mer.ashfall.MCM.mcm")

