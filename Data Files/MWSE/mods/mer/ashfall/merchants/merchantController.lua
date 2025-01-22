local gearId = 'ashfall_crate_rnd'
local hasGearId = "ashfallGearAdded_v"
local gearVersion = 20220430 --set to the date you added new gear
local function hasGearAdded(reference)
    return reference.data[hasGearId .. gearVersion] == true
end
local function setGearAdedd(reference)
    reference.data[hasGearId .. gearVersion] = true
end

local common = require("mer.ashfall.common.common")
local logger = common.createLogger("merchantController")
local config = require("mer.ashfall.config").config
local TagManager = include("CraftingFramework.components.TagManager")
--Place an invisible, appCulled container at the feet of a merchant and assign ownership
--This is how we add stock to merchants without editing the cell in the CS


local function removeOldContainers(ref)
    local oldContainers = {
        ashfall_crate_camping = true,
        ashfall_crate_rnd = true,
        ashfall_gear_base = true,
        ashfall_gear_qual = true,
        ashfall_gear_dunmer = true,
        ashfall_gear_imperial = true,
        ashfall_gear_nord = true
    }
    for container in ref.cell:iterateReferences(tes3.objectType.container) do
        if oldContainers[container.baseObject.id:lower()] then
            local owner = tes3.getOwner(container)
            if owner and owner.id:lower() == ref.baseObject.id:lower() then
                logger:debug("Found old container %s, removing", container.object.id)
                common.helper.yeet(container)
            else
                logger:debug("Owner check failed")
            end
        end
    end
end

local function placeContainer(merchant, containerId)
    logger:debug("Adding container %s to %s", containerId, merchant.object.name)
    local container = tes3.createReference{
        object = containerId,
        position = merchant.position:copy(),
        orientation = merchant.orientation:copy(),
        cell = merchant.cell
    }
    tes3.setOwner{ reference = container, owner = merchant}
end

---@param reference tes3reference a merchant reference
---@return table<number, string> containers a list of container ids to add
local function determineMerchantContainers(reference)
    local containers = {}

    --Add base container
    table.insert(containers, "ashfall_gear_base")

    --Add racial extras
    local isDunmer = reference.baseObject.race and reference.baseObject.race.id == "Dark Elf"
    local isNord = reference.baseObject.race and reference.baseObject.race.id == "Nord"
    local isImperial = reference.baseObject.race and reference.baseObject.race.id == "Imperial"
    if isDunmer then
        table.insert(containers, "ashfall_gear_dunmer")
    elseif isImperial then
        table.insert(containers, "ashfall_gear_imperial")
    elseif isNord then
        table.insert(containers, "ashfall_gear_nord")
    end

    --Add other extras
    local isRich = reference.baseObject.barterGold > 600
    if isRich then
        table.insert(containers, "ashfall_gear_qual")
    end

    return containers
end


local function onMobileActivated(e)
    local obj = e.reference.baseObject or e.reference.object
    local id = obj.id:lower()
    --Check MCM-added merchants
    local isMerchant = config.campingMerchants[ id ] == true
    --Check for tags
    if TagManager and not isMerchant then
        isMerchant = TagManager.hasId{tag = "generalTrader", id = id}
    end

    if isMerchant then
        if not hasGearAdded(e.reference) then
            setGearAdedd(e.reference)
            removeOldContainers(e.reference)
            local containersToAdd = determineMerchantContainers(e.reference)
            for _, containerId in ipairs(containersToAdd) do
                placeContainer(e.reference, containerId)
            end
        end
    end

    --Publicans get food
    if common.helper.isInnkeeper(e.reference) then
        local hasFoodAlready = e.reference.data.ashfallFoodAdded == true
        if not hasFoodAlready then
            e.reference.data.ashfallFoodAdded = true
            placeContainer(e.reference, common.staticConfigs.crateIds.food)
        end
    end

end
event.register("mobileActivated", onMobileActivated )


