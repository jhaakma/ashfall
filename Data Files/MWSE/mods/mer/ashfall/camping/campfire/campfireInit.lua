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
    campfire.data.grillMaxHeight = campfire.data.grillMaxHeight or 70
    campfire.data.grillDistance = campfire.data.grillDistance or 40

    event.trigger("Ashfall:registerReference", { reference = campfire})
end

local function registerCampfire(e)
    if e.reference.disabled then return end

    --Do some stuff to update old campfires
    if e.reference.data then
        if e.reference.data.kettleId then
            common.log:info("Found campfire with kettleId, replacing with utensilId")
            e.reference.data.utensilId = e.reference.data.kettleId
            e.reference.data.kettleId = nil
        end

        if e.reference.data.utensil ~= nil and e.reference.data.utensilId == nil then
            if e.reference.data.utensil == "kettle" then
                e.reference.data.utensilId = "ashfall_kettle"
            else
                e.reference.data.utensilId = table.choice{"misc_com_bucket_metal", "misc_com_bucket_01", "ashfall_cooking_pot"}
            end
            common.log:info("Found campfire with a utensil and no utensilId, setting to %s", 
                e.reference.data.utensilId)
        end

        local missingGrillId = e.reference.data.hasGrill
            and e.reference.data.dynamicConfig  
            and e.reference.data.dynamicConfig.grill == "dynamic"
            and e.reference.data.grillId == nil
        if missingGrillId then
            e.reference.data.grillId = "ashfall_grill"
        end

        if e.reference.data.utensilId ~= nil and e.reference.data.waterCapacity == nil then
            local data = common.staticConfigs.utensils[e.reference.data.utensilId]
            local capacity = data and data.capacity or 100
            e.reference.data.waterCapacity = capacity
            common.log:info("Found campfire with a utensil and no water capacity, setting to %s. utensilID: %s", 
                capacity, e.reference.data.utensilId)
        end
    end
    local dynamicConfig = campfireConfig.getConfig(e.reference.object.id)
    local isActivator = activatorConfig.list.campfire:isActivator(e.reference.object.id)
    local initialised = e.reference.data and e.reference.data.campfireInitialised
    if dynamicConfig and isActivator and not initialised then  
        local campfire = e.reference
        common.log:debug("registerCampfire %s", campfire.object.id)
        campfire.data.campfireInitialised = true
        campfire.data.dynamicConfig = dynamicConfig

        registerDataValues(campfire)
        event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
        event.trigger("Ashfall:registerReference", { reference = campfire})
    end
end
event.register("referenceSceneNodeCreated", registerCampfire)