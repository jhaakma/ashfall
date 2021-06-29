local gearId = 'ashfall_crate_rnd'
local hasGearId = "ashfallGearAdded_v"
local gearVersion = 20210629 --set to the date you added new gear
local function hasGearAdded(reference)
    return reference.data[hasGearId .. gearVersion] == true
end
local function setGearAdedd(reference)
    reference.data[hasGearId .. gearVersion] = true
end

local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
--Place an invisible, appCulled container at the feet of a merchant and assign ownership
--This is how we add stock to merchants without editing the cell in the CS
local function placeContainer(merchant, containerId)
    common.log:debug("Adding container %s to %s", containerId, merchant.object.name)
    local container = tes3.createReference{
        object = containerId,
        position = merchant.position:copy(),
        orientation = merchant.orientation:copy(),
        cell = merchant.cell
    }
    tes3.setOwner{ reference = container, owner = merchant}
end

local function removeOldContainers(ref)
    for ref in ref.cell:iterateReferences(tes3.objectType.container) do
        if ref.baseObject.id:lower() == gearId
        or ref.baseObject.id:lower() == 'ashfall_crate_camping' 
        then
            common.log:debug("Found old container %s, removing", ref.object.id)
            common.helper.yeet(ref)
        end
    end
end

local function onMobileActivated(e)
    local config = config
    local obj = e.reference.baseObject or e.reference.object

    --Selected outfitters and traders get camping gear
    local isMerchant = config.campingMerchants[ obj.id:lower() ] == true
    if isMerchant then
        if not hasGearAdded(e.reference) then
            setGearAdedd(e.reference)
            removeOldContainers(e.reference, gearId)
            placeContainer(e.reference, gearId)
        end
    end
    --Publicans get food
    if common.isInnkeeper(e.reference) then
        local hasFoodAlready = e.reference.data.ashfallFoodAdded == true
        if not hasFoodAlready then
            e.reference.data.ashfallFoodAdded = true
            placeContainer(e.reference, common.staticConfigs.crateIds.food)
        end
    end

end
event.register("mobileActivated", onMobileActivated )


