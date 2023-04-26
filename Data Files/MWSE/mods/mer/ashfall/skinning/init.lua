local skinningConfig = require("mer.ashfall.skinning.config")
local HarvestService = require("mer.ashfall.harvest.service")
local SkinningService = require("mer.ashfall.skinning.service")
local CraftingFramework = include("CraftingFramework")
local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config").config
local interop = require("mer.ashfall.interop")
local logger = common.createLogger("skinningController")

--Register extraSkinnables
for ingredId, skinnableConfig in pairs(skinningConfig.extraSkinnables) do
    if skinnableConfig.foodType then
        interop.registerFoods{
            [ingredId] = skinnableConfig.foodType
        }
    end
    if CraftingFramework then
        if skinnableConfig.materialType then
            logger:debug("Registering %s as %s Material", ingredId, skinnableConfig.materialType)
            CraftingFramework.Material:registerMaterials{
                {
                    id = skinnableConfig.materialType,
                    ids = { ingredId }
                }
            }
        end
    else
        logger:warn("CraftingFramework not installed")
    end
end

---@param e deathEventData
event.register(tes3.event.death, function(e)
    if not config.enableSkinning then return end
    logger:debug("removeSkinnableIngredientsOnDeath()")
    local ingredients = SkinningService.calculateSkinnableIngredients(e.reference)
    if ingredients and table.size(ingredients) > 0 then
        logger:debug("Found ingredients, removing from corpse")
        SkinningService.removeIngredientsFromCorpse(e.reference, ingredients)
        logger:debug("Adding ingred list to data")
        e.reference.data.ashfall_skinnable_ingredients = ingredients
    end
end)

---@param e attackHitEventData
event.register("attackHit", function(e)
    if not config.enableSkinning then return end
    logger:debug("skinOnAttack ENTRY")

    do -- player checks
        --Check reference
        if e.reference ~= tes3.player then
            logger:debug("Not player")
            return
        end

        --skip if in combat
        if tes3.mobilePlayer.inCombat then
            logger:debug("In combat")
            return
        end

    end


    local target = tes3.getPlayerTarget()

    do --target checks
        if not target then
            logger:debug("No target")
            return
        end

        --Check ref is dead
        if not target.mobile then
            logger:debug("No target mobile")
            return
        end
        if not target.mobile.isDead then
            logger:debug("Target not dead")
            return
        end
    end

    if HarvestService.checkHarvested(target) then
        logger:debug("Already harvested")
        return
    end

    --has weapon Weapon
    local weapon = tes3.player.mobile.readiedWeapon
    if not weapon then
        logger:debug("Harvest: No weapon")
        return
    end


    --Get skinnable ingredients
    local ingredients = SkinningService.getSkinnableIngredients(target)
    if (not ingredients) then
        logger:debug("No a valid skinnable reference")
        return
    elseif table.size(ingredients) == 0 then
        logger:debug("No skinnable ingredients")
        return
    end

    if weapon.object.type ~= tes3.weaponType["shortBladeOneHand"] then
        logger:debug("Not a short blade")
        tes3.messageBox("Requires Knife.")
        return
    end

    logger:debug("Checks passed, is skinnable, has ingredients, doing harvest attempt")

    tes3.playSound{reference = tes3.player, sound = "corpDRAG"}

    --Degrade weapon and exit if it breaks1
    local weaponBroke = HarvestService.degradeWeapon(weapon, 1, 1)
    if weaponBroke then return end

    logger:debug("Swings needed: %s, current swings: %s",
    skinningConfig.SWINGS_NEEDED, HarvestService.getCurrentSwings(target))

    --Accumulate swings and check if it's enough to harvest

    local didHarvest = HarvestService.attemptSwing(1, target, skinningConfig.SWINGS_NEEDED)

    if not didHarvest then return end
    logger:debug("Harvesting")
    SkinningService.harvest(target, ingredients)

    local destructionLimit = HarvestService.getDestructionLimit(target)
    if not destructionLimit then
        destructionLimit = SkinningService.calculateDestructionLimit(target)
        logger:debug("initialising destructionLimit to %s", destructionLimit)
        HarvestService.setDestructionLimit(target, destructionLimit)
    end

    if HarvestService.isExhausted(target, destructionLimit) then
        logger:debug("Exhausted, deleting ref")
        HarvestService.demolish{
            reference = target,
            harvestableHeight = HarvestService.getRefHeight(target),
            fallSpeed = 1,
            callback = function(reference)
                logger:debug("Deleting ref")
                --Grab everything in its inventory
                ---@param stack tes3itemStack
                for _, stack in pairs(reference.object.inventory) do
                    --Add it to the player's inventory
                    tes3.addItem{
                        reference = tes3.player,
                        item = stack.object,
                        itemData = stack.variables,
                        count = stack.count,
                        showMessage = true
                    }
                end
                reference:delete()
            end
        }
    end
end)

---@param e uiObjectTooltipEventData
event.register(tes3.event.uiObjectTooltip, function(e)
    if not config.enableSkinning then return end
    if SkinningService.getSkinnableIngredients(e.reference) then
        e.tooltip:createLabel{ text = "Skinnable" }
    end
end)