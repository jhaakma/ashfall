--[[
    This script handles when campfires/cooking stations are first
    placed in the world. This includes replacing vanilla campfires and 
    player-placed campfires.

    - Add random supports/kettle/stew etc to vanilla replaced campfires
    - Initialise ref.data
    - Initialise Campfire visuals
    - Register Campfire for referenceController
]]

local common = require ("mer.ashfall.common.common")

local campfireConfig = common.staticConfigs.campfireConfig
local activatorConfig = common.staticConfigs.activatorConfig

local function registerDataValues(campfire)
    common.log:debug("registerDataValues %s", campfire.object.id)
    campfire.data.fuelLevel = campfire.data.fuelLevel or 1
    campfire.data.grillMinHeight = campfire.data.grillMinHeight or 21
    campfire.data.grillMaxHeight = campfire.data.grillMaxHeight or 50
    campfire.data.grillDistance = campfire.data.grillDistance or 40

    event.trigger("Ashfall:registerReference", { reference = campfire})
end

local function registerCampfire(e)
    if e.reference.disabled then return end
    local dynamicConfig = campfireConfig.getConfig(e.reference.object.id)
    local isActivator = activatorConfig.list.campfire:isActivator(e.reference.object.id)
    local initialised = e.reference.data and e.reference.data.campfireInitialised
    if dynamicConfig and isActivator and not initialised then  
        local campfire = e.reference
        common.log:debug("registerCampfire %s", campfire.object.id)

        campfire.data.campfireInitialised = true
        campfire.data.dynamicConfig = dynamicConfig

        local safeRef = tes3.makeSafeObjectHandle(campfire)
        event.register("simulate", function()
            if not safeRef:valid() then return end
            registerDataValues(campfire)
            event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
            event.trigger("Ashfall:registerReference", { reference = campfire})
        end,{ doOnce = true })
    end
end
event.register("referenceSceneNodeCreated", registerCampfire)