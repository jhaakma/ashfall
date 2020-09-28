
local common = require("mer.ashfall.common.common")

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


local function onMobileActivated(e)
    local config = common.config.getConfig()
    local obj = e.reference.baseObject or e.reference.object

    --Publicans get food
    local isPublican = ( 
        obj.class and obj.class.id == "Publican" or
        config.foodWaterMerchants[obj.id:lower()]
    )
    if isPublican then
        local hasFoodAlready = e.reference.data.ashfallFoodAdded == true
        if not hasFoodAlready then
            e.reference.data.ashfallFoodAdded = true
            placeContainer(e.reference, common.staticConfigs.crateIds.food)
        end
    end

    --Selected outfitters and traders get camping gear
    local isMerchant = config.campingMerchants[ obj.id:lower() ] == true
    if isMerchant then
        local hasGearAlready = e.reference.data.ashfallGearAdded == true
        if not hasGearAlready then
            e.reference.data.ashfallGearAdded = true
            placeContainer(e.reference, common.staticConfigs.crateIds.camping)
        end
    end
end
event.register("mobileActivated", onMobileActivated )


