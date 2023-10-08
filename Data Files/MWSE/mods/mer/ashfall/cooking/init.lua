local common = require ("mer.ashfall.common.common")
local skillsConfig = require("mer.ashfall.config.skillConfigs")
local logger = common.createLogger("cooking")
local LiquidContainer = require("mer.ashfall.liquid.LiquidContainer")
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")
local HeatUtil = require("mer.ashfall.heat.HeatUtil")
local foodConfig = common.staticConfigs.foodConfig
local hungerController = require("mer.ashfall.needs.hungerController")
local patinaController = require("mer.ashfall.camping.patinaController")
local ReferenceController = require("mer.ashfall.referenceController")
----------------------------
--Grilling
-----------------------------


--How much fuel level affects grill cook speed
local function calculateCookMultiplier(heatLevel)
    return 350 * math.min(math.remap(heatLevel, 0, 10, 0, 2.5), 2.5)
end

--How much ingredient weight affects grill cook speed
local function calculateCookWeightModifier(ingredObject)
    return math.clamp(math.remap(ingredObject.weight, 1, 2, 1, 0.5), 0.25, 4.0)
end

local function resetCookingTime(ingredRef)
    if not common.helper.isStack(ingredRef) and ingredRef.data then
        ingredRef.data.lastCookUpdated = nil
    end
end



local function addGrillPatina(campfire,interval)
    if campfire.sceneNode and campfire.data.grillId then

        local grillNode = campfire.sceneNode:getObjectByName("ATTACH_STAND")
            or campfire.sceneNode:getObjectByName("ATTACH_GRILL")
        local patinaAmount = campfire.data.grillPatinaAmount or 0
        local newAmount = math.clamp(patinaAmount+ interval * 100, 0, 100)
        local didAddPatina = patinaController.addPatina(grillNode, newAmount)
        if didAddPatina then
            campfire.data.grillPatinaAmount = newAmount
            logger:trace("Added patina to %s node, new amount: %s",grillNode, campfire.data.grillPatinaAmount)
        else
            logger:trace("Mesh incompatible with patina mechanic, did not apply")
        end
    end
end

--Check whether the player burns the food based on survival skill and whether campfire has grill
local function checkIfBurned(campfire)
    local burnChance = 1
    local survivalSkill = common.skills.survival.current
    --Lower survival skill increases burn chance
    local survivalEffect = math.remap(survivalSkill, 0, 100, 1.0, 0.5)
    --Chance to burn doubles if campfire has a grill
    local grillEffect = campfire.data.hasGrill and 0.25 or 1.0
    --but wooden grills aren't as good
    local grillId = campfire.data.grillId
    if grillId then
        logger:debug("grillId: %s", grillId)
        local grillData = common.staticConfigs.grills[grillId:lower()]
        if grillData and grillData.materials then
            logger:debug("Using bushcrafted grill")
            grillEffect = 0.5
        end
    end
    --Roll for burn chance
    local roll = math.random()
    local burnChance = burnChance * survivalEffect * grillEffect
    logger:debug("survivalEffect: %s", survivalEffect)
    logger:debug("grillEffect: %s", grillEffect)
    logger:debug("Burn chance: %s", burnChance)
    logger:debug("Roll: %s", roll)
    if roll < burnChance then
        logger:debug("Burned")
        return true
    else
        logger:debug("Did not burn")
        return false
    end
end


---@param ingredReference tes3reference
---@param difference number
local function doCook(ingredReference, difference)
    ingredReference.data.grillState = "cooked"
    tes3.playSound{ sound = "potion fail", pitch = 0.7, reference = ingredReference }
    common.skills.survival:exercise(skillsConfig.survival.grill.skillGain)
    event.trigger("Ashfall:ingredCooked", { reference = ingredReference})
    local justChangedCell = difference > 0.01
    if not justChangedCell then
        tes3.messageBox("%s is fully cooked.", ingredReference.object.name)
    end
end

---@param ingredReference tes3reference
---@param difference number
local function doBurn(ingredReference, difference)
    ingredReference.data.grillState = "burnt"
    tes3.playSound{ sound = "potion fail", pitch = 0.9, reference = ingredReference }
    event.trigger("Ashfall:ingredCooked", { reference = ingredReference})
    local justChangedCell = difference > 0.01
    if not justChangedCell then
        tes3.messageBox("%s has become burnt.", ingredReference.object.name)
    end
end

local function startCookingIngredient(ingredient, timestamp)
    if ingredient.data.grillState == "burnt" then
        logger:trace("Already burnt")
        return
    end
    if ingredient.data.preventBurning then
        logger:trace("Prevent burning")
        return
    end
    timestamp = timestamp or tes3.getSimulationTimestamp()
    ingredient.data.lastCookUpdated = timestamp

    local difference = timestamp - ingredient.data.lastCookUpdated
    --only show message if enough time has passed
    local justChangedCell = difference > 0.01
    if not justChangedCell then
        local message = string.format("%s begins to cook.", ingredient.object.name)
        tes3.messageBox{ message = message }
    end
    tes3.playSound{ sound = "potion fail", pitch = 0.8, reference = ingredient }
end


---@param ingredReference tes3reference
local function updateGrillFoodHeatSource(ingredReference)
    local campfire = common.helper.getHeatFromBelow(ingredReference, "strong")
    if campfire and campfire.data.isLit then
        --If you placed a stack, return all but one to the player
        if common.helper.isStack(ingredReference) then
            logger:debug("Returning grill food stack to player")
            local count = ingredReference.attachments.variables.count
            ---@diagnostic disable-next-line
            mwscript.addItem{ reference = tes3.player, item = ingredReference.object, count = (count - 1) }
            ingredReference.attachments.variables.count = 1
            event.trigger("Ashfall:registerReference", { reference = ingredReference})
            tes3ui.forcePlayerInventoryUpdate()
        end
        if ingredReference.tempData.ashfallHeatSource ~= campfire then
            logger:debug("Setting grill food heat source to %s", campfire)
            ingredReference.tempData.ashfallHeatSource = campfire
            startCookingIngredient(ingredReference)
        end
    else
        --clear heat source
        local hasHeatSourrce = ingredReference.supportsLuaData
            and ingredReference.tempData
            and ingredReference.tempData.ashfallHeatSource
        if hasHeatSourrce then
            ingredReference.tempData.ashfallHeatSource = nil
        end
    end
end

---@param ingredReference tes3reference
local function grillFoodItem(ingredReference)
    local timestamp = tes3.getSimulationTimestamp()
    local campfire = ingredReference.supportsLuaData
        and ingredReference.tempData.ashfallHeatSource
    if campfire then
        if campfire.data.isLit then
            if ingredReference.data.lastCookUpdated == nil then
                startCookingIngredient(ingredReference)
                return
            end

            ingredReference.data.lastCookUpdated = ingredReference.data.lastCookUpdated or timestamp
            ingredReference.data.cookedAmount = ingredReference.data.cookedAmount or 0

            local difference = timestamp - ingredReference.data.lastCookUpdated

            addGrillPatina(campfire, difference)
            ingredReference.data.lastCookUpdated = timestamp

            local heat = math.max(0, HeatUtil.getHeat(campfire))
            logger:trace("Cooking heat: %s", heat)
            local thisCookMulti = calculateCookMultiplier(heat)
            logger:trace("Cooking multiplier: %s", thisCookMulti)
            local weightMulti = calculateCookWeightModifier(ingredReference.object)
            local thisCookedAmount = difference * thisCookMulti * weightMulti
            logger:trace("Cooked amount: %s", thisCookedAmount)
            ingredReference.data.cookedAmount = ingredReference.data.cookedAmount + thisCookedAmount
            local cookedAmount = ingredReference.data.cookedAmount

            local burnLimit = hungerController.getBurnLimit()
            --- Just cooked - reached 100 cooked but still doesn't have a cooked grill state
            local justCooked = cookedAmount > 100
                and cookedAmount < burnLimit
                and ingredReference.data.grillState ~= "cooked"
                and ingredReference.data.grillState ~= "burnt"

            local justBurnt = cookedAmount >= burnLimit
                and ingredReference.data.grillState ~= "burnt"


            if justCooked then
                --Check if food burned immediately
                if checkIfBurned(campfire) then
                    doBurn(ingredReference, difference)
                else
                    doCook(ingredReference, difference)
                end
            elseif justBurnt then
                doBurn(ingredReference, difference)
            end
            tes3ui.refreshTooltip()

        else
            --reset grill time if campfire is unlit
            resetCookingTime(ingredReference)
        end
    else
        --reset grill time if not placed on a campfire
        resetCookingTime(ingredReference)
    end
end

event.register("loaded", function()
    timer.start{
        duration = common.helper.getUpdateIntervalInSeconds(),
        iterations = -1,
        callback = function()
            ReferenceController.iterateReferences("grillableFood", function(ref)
                updateGrillFoodHeatSource(ref)
            end)
        end
    }
    ReferenceController.iterateReferences("grillableFood", function(ref)
        updateGrillFoodHeatSource(ref)
    end)

    timer.start{
        duration = 0.05,
        iterations = -1,
        callback = function()
            ReferenceController.iterateReferences("grillableFood", function(ref)
                grillFoodItem(ref)
            end)
        end
    }
end)


local function doAddingredToStew(campfire, reference)
    if not foodConfig.getStewBuffForId(reference.object) then
        tes3.messageBox("%s can not be added to a stew.", reference.object.name)
        common.helper.pickUp(reference)
        return
    end

    local amount = common.helper.getStackCount(reference)
    local amountAdded = CampfireUtil.addIngredToStew{
        campfire = campfire,
        count = amount,
        item = reference.object
    }

    logger:debug("amountAdded: %s", amountAdded)
    if amountAdded < amount then
        reference.attachments.variables.count = reference.attachments.variables.count - amountAdded

        if amountAdded >= 1 then
            tes3.messageBox("Added %s %s to stew.", amountAdded, reference.object.name)
        else
            tes3.messageBox("You cannot add any more %s.", foodConfig.getFoodTypeResolveMeat(reference.object):lower())
        end
        common.helper.pickUp(reference)
    else
        tes3.messageBox("Added %s %s to stew.", amountAdded, reference.object.name)
        reference:delete()
    end
end

local function doPlaced(ingredReference)
    --place in pot
    local campfire = CampfireUtil.getPlacedOnContainer()
    if campfire then
        local utensilData = CampfireUtil.getDataFromUtensilOrCampfire{
            dataHolder = campfire,
            object = campfire.object
        }
        local hasWater = campfire.data.waterAmount and campfire.data.waterAmount > 0
        local hasLadle = not not campfire.data.ladle
        --ingredient placed on a cooking pot with water in it
        if hasWater and utensilData and utensilData.holdsStew then
            if not hasLadle then
                tes3.messageBox("Requires ladle.")
            else
                doAddingredToStew(campfire, ingredReference)
            end
        end
    elseif foodConfig.getGrillValues(ingredReference.object) then
        if ingredReference.supportsLuaData then
            --Reset grill time for meat and veges
            ingredReference.data.preventBurning = nil
            resetCookingTime(ingredReference)
        end
        updateGrillFoodHeatSource(ingredReference)
        grillFoodItem(ingredReference)
    end
end

--Place food on a grill or into a pot
local function foodPlaced(e)
    if e.reference and e.reference.object then
        local isIngredient = e.reference.object.objectType == tes3.objectType.ingredient
        if not isIngredient then return end
        local safeRef = tes3.makeSafeObjectHandle(e.reference)
        timer.frame.delayOneFrame(function()
            if safeRef and safeRef:valid() then
                doPlaced(safeRef:getObject())
            end
        end)
    end
end
event.register("referenceSceneNodeCreated" , foodPlaced)


local function clearUtensilData(e)
    e.utensil = nil
    e.ladle = nil
    e.utensilId = nil
    e.utensilData = nil
    e.utensilPatinaAmount = nil
end

--Empty a cooking pot or kettle, reseting all data
local function clearCampfireUtensilData(e)

    logger:debug("Clearing Utensil Data")
    local campfire = e.campfire
    LiquidContainer.createFromReference(campfire):empty()

    if e.removeUtensil then
        clearUtensilData(campfire.data)
    end
    event.trigger("Ashfall:UpdateAttachNodes", { reference = campfire})
end
event.register("Ashfall:Campfire_clear_utensils", clearCampfireUtensilData)