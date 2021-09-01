local common = require ("mer.ashfall.common.common")
local CampfireUtil = require("mer.ashfall.camping.campfire.CampfireUtil")
local foodConfig = common.staticConfigs.foodConfig
local hungerController = require("mer.ashfall.needs.hungerController")
local skillSurvivalGrillingIncrement = 5
local patinaController = require("mer.ashfall.camping.patinaController")

----------------------------
--Grilling
-----------------------------


--How much fuel level affects grill cook speed
local function calculateCookMultiplier(heatLevel)
    return 350 * math.min(math.remap(heatLevel, 0, 10, 0.5, 2.5), 2.5)
end

--How much ingredient weight affects grill cook speed
local function calculateCookWeightModifier(ingredObject)
    return math.clamp(math.remap(ingredObject.weight, 1, 2, 1, 0.5), 0.25, 4.0)
end

--Checks if the ingredient has been placed on a campfire
local function findGriller(ingredient)

    local campfire
    local function checkDistance(ref)
        local maxHeight = ref.data.grillMaxHeight or 0
        local distance = ref.data.grillDistance or 0

            if common.helper.getCloseEnough{
                ref1 = ref, ref2 = ingredient,
                distVertical = maxHeight,
                distHorizontal = distance
            } then
                campfire = ref
            end
    end
    common.helper.iterateRefType("campfire", checkDistance)
    return campfire
end



local function resetCookingTime(ingredient)
    if not common.helper.isStack(ingredient) and ingredient.data then
        ingredient.data.lastCookUpdated = nil
    end
end

local function startCookingIngredient(ingredient, timestamp)

    --If you placed a stack, return all but one to the player
    if common.helper.isStack(ingredient) then
        local count = ingredient.attachments.variables.count
        mwscript.addItem{ reference = tes3.player, item = ingredient.object, count = (count - 1) }
        ingredient.attachments.variables.count = 1
    else
        --only check data for non-stack I guess?
        if ingredient.data.grillState == "burnt" then
            common.log:trace("Already burnt")
            return
        end
    end
    timestamp = timestamp or tes3.getSimulationTimestamp()
    ingredient.data.lastCookUpdated = timestamp
    tes3.messageBox("%s begins to cook.", ingredient.object.name)
    tes3.playSound{ sound = "potion fail", pitch = 0.8, reference = ingredient }

    -- local smoke = tes3.loadMesh("ashfall\\cookingSmoke.nif"):clone()
    -- ingredient.sceneNode:attachChild(smoke, true)
    -- ingredient.sceneNode:update()
    -- ingredient.sceneNode:updateNodeEffects()
end


local function addGrillPatina(campfire,interval)
    if campfire.sceneNode and campfire.data.grillId then

        local grillNode = campfire.sceneNode:getObjectByName("ATTACH_STAND")
            or campfire.sceneNode:getObjectByName("ATTACH_GRILL")
            or campfire.sceneNode:getObjectByName("SWITCH_GRILL")
        local patinaAmount = campfire.data.grillPatinaAmount or 0
        local newAmount = math.clamp(patinaAmount+ interval * 100, 0, 100)
        local didAddPatina = patinaController.addPatina(grillNode, newAmount)
        if didAddPatina then
            campfire.data.grillPatinaAmount = newAmount
            common.log:debug("Added patina to %s node, new amount: %s",grillNode, campfire.data.grillPatinaAmount)
        else
            common.log:debug("Mesh incompatible with patina mechanic, did not apply")
        end
    end
end

local function grillFoodItem(ingredient, timestamp)
    --Can only grill certain types of food
    if foodConfig.getGrillValues(ingredient.object) then
        local campfire = findGriller(ingredient)
        if campfire then
            if campfire.data.isLit then
                if common.helper.isStack(ingredient) or ingredient.data.lastCookUpdated == nil then
                    startCookingIngredient(ingredient, timestamp)
                    return
                end

                ingredient.data.lastCookUpdated = ingredient.data.lastCookUpdated or timestamp
                ingredient.data.cookedAmount = ingredient.data.cookedAmount or 0

                local difference = timestamp - ingredient.data.lastCookUpdated
                if difference > 0.008 then

                    addGrillPatina(campfire, difference)
                    ingredient.data.lastCookUpdated = timestamp

                    local thisCookMulti = calculateCookMultiplier(CampfireUtil.getHeat(campfire.data))
                    local weightMulti = calculateCookWeightModifier(ingredient.object)
                    ingredient.data.cookedAmount = ingredient.data.cookedAmount + ( difference * thisCookMulti * weightMulti)
                    local cookedAmount = ingredient.data.cookedAmount

                    local burnLimit = hungerController.getBurnLimit()
                    --Cooked your food
                    local justCooked = cookedAmount > 100
                        and cookedAmount < burnLimit
                        and ingredient.data.grillState ~= "cooked"
                        and ingredient.data.grillState ~= "burnt"

                    --burned your food
                    local justBurnt = cookedAmount > burnLimit
                        and ingredient.data.grillState ~= "burnt"

                    if justCooked then
                        --You need a grill to properly cook food
                        if campfire.data.hasGrill then
                            ingredient.data.grillState = "cooked"
                            tes3.playSound{ sound = "potion fail", pitch = 0.7, reference = ingredient }
                            common.skills.survival:progressSkill(skillSurvivalGrillingIncrement)
                            event.trigger("Ashfall:ingredCooked", { reference = ingredient})
                        else
                            --if no grill attached, then the food always burns
                            justBurnt = true
                        end
                    end

                    if justBurnt then
                        ingredient.data.grillState = "burnt"
                        tes3.playSound{ sound = "potion fail", pitch = 0.9, reference = ingredient }
                        event.trigger("Ashfall:ingredCooked", { reference = ingredient})
                    end

                    --Only play sounds/messages if not transitioning from cell
                    --Check how long has passed as a bit of a hack
                    local justChangedCell = difference > 0.01
                    if not justChangedCell then
                        if justBurnt then
                            tes3.messageBox("%s has become burnt.", ingredient.object.name)
                        elseif justCooked then
                            tes3.messageBox("%s is fully cooked.", ingredient.object.name)
                        end
                    end

                    tes3ui.refreshTooltip()
                end
            else
                --reset grill time if campfire is unlit
                resetCookingTime(ingredient)
            end
        end
    end
end


--update any food that is currently grilling
local function grillFoodSimulate(e)
    for _, cell in pairs( tes3.getActiveCells() ) do
        for ingredient in cell:iterateReferences(tes3.objectType.ingredient) do
            grillFoodItem(ingredient, e.timestamp)
        end
        for ingredient in cell:iterateReferences(tes3.objectType.alchemy) do
            grillFoodItem(ingredient, e.timestamp)
        end
    end
end
event.register("simulate", grillFoodSimulate)



--Reset grill time when item is placed
local function foodPlaced(e)
    if e.reference and e.reference.object then
        if foodConfig.getGrillValues(e.reference.object) then
            local timestamp = tes3.getSimulationTimestamp()
            local ingredient = e.reference
                --Reset grill time for meat and veges
            timer.frame.delayOneFrame(function()
                resetCookingTime(ingredient)
                grillFoodItem(ingredient, timestamp)
            end)
        end
    end
end
event.register("referenceSceneNodeCreated" , foodPlaced)





--Empty a cooking pot or kettle, reseting all data
local function clearUtensilData(e)

    common.log:debug("Clearing Utensil Data")
    local campfire = e.campfire
    campfire.data.stewProgress = nil
    campfire.data.stewLevels = nil
    campfire.data.waterAmount = nil
    campfire.data.waterHeat = nil
    campfire.data.waterType = nil
    campfire.data.teaProgress = nil


    if e.removeUtensil then
        campfire.data.utensil = nil
        campfire.data.ladle = nil
        campfire.data.utensilId = nil
        campfire.data.utensilData = nil
        campfire.data.utensilPatinaAmount = nil
    end
    if not e.isContainer then
        tes3.removeSound{
            reference = campfire,
            sound = "ashfall_boil"
        }
        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
    end
    event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire})
end
event.register("Ashfall:Campfire_clear_utensils", clearUtensilData)