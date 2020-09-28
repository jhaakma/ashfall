local common = require ("mer.ashfall.common.common")
local foodConfig = common.staticConfigs.foodConfig
local hungerController = require("mer.ashfall.needs.hungerController")
local skillSurvivalGrillingIncrement = 5


----------------------------
--Grilling
-----------------------------


--How much fuel level affects grill cook speed
local function calculateCookMultiplier(fuelLevel)
    return 350 * math.min(math.remap(fuelLevel, 0, 10, 0.5, 1.5), 1.5)
end

--How much ingredient weight affects grill cook speed
local function calculateCookWeightModifier(ingredObject)
    return math.remap(ingredObject.weight, 1, 2, 1, 0.5)
end

--Checks if the ingredient has been placed on a campfire
local function findGriller(ingredient)

    local campfire
    local function checkDistance(ref)
        local minHeight = ref.data.grillMinHeight or 0
        local maxHeight = ref.data.grillMaxHeight or 0
        local distance = ref.data.grillDistance or 0
        --food sitting on grill
        local heightDistance = ingredient.position.z - ref.position.z
        if heightDistance < maxHeight and heightDistance > minHeight then
            
            local thisDistance = ingredient.position:distance(ref.position)
            if thisDistance < distance then
                distance = thisDistance
                campfire = ref
            end
        end
    end
    common.helper.iterateRefType("griller", checkDistance)
    return campfire
end



local function resetCookingTime(ingredient)
    if not common.helper.isStack(ingredient) and ingredient.data then 
        ingredient.data.lastCookUpdated = nil 
    end
end

local function startCookingIngredient(ingredient, timestamp)
    
    if common.helper.isStack(ingredient) then
        local count = ingredient.attachments.variables.count
        mwscript.addItem{ reference = tes3.player, item = ingredient.object, count = (count - 1) }
        ingredient.attachments.variables.count = 1
    else
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


local function grillFoodItem(ingredient, timestamp)
    if ingredient.object.objectType == tes3.objectType.ingredient then
        --Can only grill certain types of food
        if foodConfig.getGrillValues(ingredient.object.id) then
            local campfire = findGriller(ingredient)
            if campfire then
                if campfire.data.hasGrill and campfire.data.isLit then
                    
                    if common.helper.isStack(ingredient) or ingredient.data.lastCookUpdated == nil then 
                        startCookingIngredient(ingredient, timestamp) 
                        return
                    end

                    ingredient.data.lastCookUpdated = ingredient.data.lastCookUpdated or timestamp
                    ingredient.data.cookedAmount = ingredient.data.cookedAmount or 0

                    local difference = timestamp - ingredient.data.lastCookUpdated
                    if difference > 0.008 then
                        ingredient.data.lastCookUpdated = timestamp

                        local thisCookMulti = calculateCookMultiplier(campfire.data.fuelLevel)
                        local weightMulti = calculateCookWeightModifier(ingredient.object)
                        ingredient.data.cookedAmount = ingredient.data.cookedAmount + ( difference * thisCookMulti * weightMulti)
                        local cookedAmount = ingredient.data.cookedAmount

                        local burnLimit = hungerController.getBurnLimit()
                        --Cooked your food
                        local justCooked = (
                            cookedAmount > 100 and 
                            cookedAmount < burnLimit and
                            ingredient.data.grillState ~= "cooked"
                        )
                        if justCooked then
                            ingredient.data.grillState = "cooked"
                            tes3.playSound{ sound = "potion fail", pitch = 0.7, reference = ingredient }
                            common.skills.survival:progressSkill(skillSurvivalGrillingIncrement)
                        
                            event.trigger("Ashfall:ingredCooked", { reference = ingredient})
                        end
                        --burned your food
                        local justBurnt = (
                            cookedAmount > burnLimit and 
                            ingredient.data.grillState ~= "burnt"
                        )
                        if justBurnt then
                            ingredient.data.grillState = "burnt"
                            tes3.playSound{ sound = "potion fail", pitch = 0.9, reference = ingredient }
                            event.trigger("Ashfall:ingredCooked", { reference = ingredient})
                        end

                        --Only play sounds/messages if not transitioning from cell
                        --Check how long has passed as a bit of a hack
                        if difference < 0.01 then
                            if justCooked then
                                tes3.messageBox("%s is fully cooked.", ingredient.object.name)
                            elseif justBurnt then
                                tes3.messageBox("%s has become burnt.", ingredient.object.name)
                            end
                        end
                        
                        local helpMenu = tes3ui.findHelpLayerMenu(tes3ui.registerID("HelpMenu"))
                        if helpMenu and helpMenu.visible == true then
                            tes3ui.refreshTooltip()
                        end
                    end
                else
                    --reset grill time if campfire is unlit
                    resetCookingTime(ingredient)
                end
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
    end
end
event.register("simulate", grillFoodSimulate)



--Reset grill time when item is placed
local function ingredientPlaced(e)
    if e.reference and e.reference.object then
        if foodConfig.getGrillValues(e.reference.object.id) then
            local timestamp = tes3.getSimulationTimestamp()
            local ingredient = e.reference
                --Reset grill time for meat and veges
            timer.frame.delayOneFrame(function()
                resetCookingTime(ingredient, timestamp)
                grillFoodItem(ingredient, timestamp)
            end) 
        end
    end
end
event.register("referenceSceneNodeCreated" , ingredientPlaced)





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
    end
    tes3.removeSound{ 
        reference = campfire, 
        sound = "ashfall_boil"
    }
    --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
end
event.register("Ashfall:Campfire_clear_utensils", clearUtensilData)