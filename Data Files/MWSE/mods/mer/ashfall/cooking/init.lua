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

---For fire spells, mages with a high destruction skill
--- Can reduce the chance of burning food.
local function getDestructionBurnChanceMultiplier()
    local destructionSkill = math.clamp(tes3.mobilePlayer.skills[tes3.skill.destruction + 1].current, 0, 80)
    local destructionEffect = math.remap(destructionSkill, 0, 80, 1.5, 0.3)
    return destructionEffect
end

--Get the burn chance multiplier from a campfire
---@param campfire tes3reference
---@return number
local function getGrillBurnChanceMultiplier(campfire)
    --Chance to burn lower if campfire has a grill
    local grillEffect = campfire.data.hasGrill and 0.25 or 1
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
    return grillEffect
end

---@return number survivalEffect The effect of survival skill on burn chance
local function getSurvivalBurnChanceMultiplier()
    local survivalSkill = common.skills.survival.current
    --Lower survival skill increases burn chance
    local survivalEffect = math.remap(survivalSkill, 0, 100, 1.0, 0.5)
    return survivalEffect
end

--Check whether the player burns the food based on survival skill and whether campfire has grill
---@param burnChanceMultiplier number
local function checkIfBurned(burnChanceMultiplier)
    local burnChance = 1
    --Roll for burn chance
    local roll = math.random()
    local burnChance = burnChance * burnChanceMultiplier
    logger:debug("burnChanceMultiplier: %s", burnChanceMultiplier)
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


---@param ingredReference tes3reference # The ingredient reference to cook
---@param showMessage boolean #Whether to show the "is fully cooked" message
local function doCook(ingredReference, showMessage)
    ingredReference.data.grillState = "cooked"
    ingredReference.data.cookedAmount = 100
    tes3.playSound{ sound = "potion fail", pitch = 0.7, reference = ingredReference }
    common.skills.survival:exercise(skillsConfig.survival.grill.skillGain)
    event.trigger("Ashfall:ingredCooked", { reference = ingredReference})
    if showMessage then
        tes3.messageBox("%s is fully cooked.", ingredReference.object.name)
    end
end

---@param ingredReference tes3reference # The ingredient reference to burn
---@param showMessage boolean #Whether to show the "has become burnt" message
local function doBurn(ingredReference, showMessage)
    ingredReference.data.grillState = "burnt"
    ingredReference.data.cookedAmount = 100
    tes3.playSound{ sound = "potion fail", pitch = 0.9, reference = ingredReference }
    event.trigger("Ashfall:ingredCooked", { reference = ingredReference})
    if showMessage then
        tes3.messageBox("%s has become burnt.", ingredReference.object.name)
    end
end


---@param e { reference: tes3reference, burnChanceMultiplier: number, showMessage: boolean }
local function attemptCook(e)
    local burnChanceMultiplier = e.burnChanceMultiplier or 1
    local showMessage = e.showMessage or true
    if checkIfBurned(burnChanceMultiplier) then
        doBurn(e.reference, showMessage)
    else
        doCook(e.reference, showMessage)
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
    ---@type tes3reference|nil|false
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

            local justChangedCell = difference > 0.01
            local showMessage = not justChangedCell
            if justCooked then
                local burnChanceMulti = getGrillBurnChanceMultiplier(campfire)
                    * getSurvivalBurnChanceMultiplier()
                attemptCook{
                    reference = ingredReference,
                    burnChanceMultiplier = burnChanceMulti,
                    showMessage = showMessage
                }
            elseif justBurnt then
                doBurn(ingredReference, showMessage)
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
        -- local utensilData = CampfireUtil.getDataFromUtensilOrCampfire{
        --     dataHolder = campfire,
        --     object = campfire.object
        -- }
        -- local hasWater = campfire.data.waterAmount and campfire.data.waterAmount > 0
        -- local hasLadle = not not campfire.data.ladle
        -- --ingredient placed on a cooking pot with water in it
        -- if hasWater and utensilData and utensilData.holdsStew then
        --     if not hasLadle then
        --         tes3.messageBox("Requires ladle.")
        --     else
        --         doAddingredToStew(campfire, ingredReference)
        --     end
        -- end
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


local function doFireVfx(ingredRef)
    tes3.createVisualEffect {
        position = ingredRef.position,
        object = "VFX_DestructHit",
        lifespan = 1,
        scale = 0.1,
        verticalOffset = -80
    }
end

---Cook food by casting an on-touch fire spell at it
---@param e magicCastedEventData
local function onMagicCasted(e)
    if e.caster ~= tes3.player then return end
    local isFireTouch
    for _, effect in ipairs(e.source.effects) do
        if effect.rangeType == tes3.effectRange.touch then
            if effect.id == tes3.effect.fireDamage then
                isFireTouch = true
                break
            end
        end
    end
    if not isFireTouch  then return end

    logger:debug("%s", isFireTouch and "Cast fire" or "Cast frost")
    local target = tes3.getPlayerTarget()
    local isGrillable = target
        and common.staticConfigs.foodConfig.getGrillValues(target.object)
        and not common.helper.isStack(target)
        and target.data
        and target.data.grillState ~= "burnt"
        and target.data.grillState ~= "cooked"

    if target and isGrillable then
        local burnChanceMulti = getDestructionBurnChanceMultiplier()
        attemptCook{
            reference = target,
            burnChanceMultiplier = burnChanceMulti,
            showMessage = true
        }
        doFireVfx(target)
    end
end
event.register("magicCasted", onMagicCasted)


---Cook food by shooting fire at it
---@param e projectileExpireEventData
event.register("projectileExpire", function(e)
    if not (e.mobile.reference and e.mobile.spellInstance) then return end
    local isFireSpell
    local rangeFeet = 1
    for _, effect in ipairs(e.mobile.spellInstance.source.effects) do
        if effect.rangeType == tes3.effectRange.target then
            rangeFeet = effect.radius
            if effect.id == tes3.effect.fireDamage then
                isFireSpell = true
                break
            end
        end
    end
    if not isFireSpell then return end
    logger:debug("on target %s spell expired", isFireSpell and "fire" or "frost")
    local spellRef = e.mobile.reference
    ---@param ingredReference tes3reference
    ReferenceController.iterateReferences("grillableFood", function(ingredReference)
        local uncooked = ingredReference.sceneNode
            and ingredReference.data
            and ingredReference.data.grillState ~= "burnt"
            and ingredReference.data.grillState ~= "cooked"

        if uncooked and not common.helper.isStack(ingredReference) then
            local distance = ingredReference.position:distance(spellRef.position)
            -- Convert feet to units
            -- 64 units = 1 yard = 3 feet
            local rangeYards = rangeFeet / 3
            local rangeUnits = rangeYards * 64
            logger:debug("Distance: %s, spell range: %s", distance, rangeUnits)
            if distance < rangeUnits then
                local burnChanceMulti = getDestructionBurnChanceMultiplier()
                attemptCook{
                    reference = ingredReference,
                    burnChanceMultiplier = burnChanceMulti,
                    showMessage = true
                }
                doFireVfx(ingredReference)
            end
        end
    end)
end)