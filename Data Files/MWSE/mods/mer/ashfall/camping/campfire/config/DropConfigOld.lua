local common = require ("mer.ashfall.common.common")
local LiquidContainer = require("mer.ashfall.objects.LiquidContainer")
local placeUtensil     = require("mer.ashfall.camping.menuFunctions.placeUtensil")
local hangUtensil       = require("mer.ashfall.camping.menuFunctions.hangUtensil")
local teaConfig          = require("mer.ashfall.config.teaConfig")


local DropConfig = {
    DROP_GROUND_UTENSIL = {
        ---@param campfire tes3reference
        ---@param item tes3item
        ---@param itemData tes3itemData
        dropText = function(campfire, item, itemData)
            local id = item.id:lower()
            -- ---Utensil
            -- if placeUtensil.showRequirements(campfire) and placeUtensil.enableRequirements(campfire) then
            --     if common.staticConfigs.groundUtensils[id] then
            --         return string.format("Attach %s", common.helper.getGenericUtensilName(item))
            --     end
            -- end

            -- ---firewood
            -- if id == common.staticConfigs.objectIds.firewood then
            --     if campfire.data.fuelLevel < common.staticConfigs.maxWoodInFire then
            --         return "Add firewood"
            --     end
            -- end

            --Supports
            -- if common.staticConfigs.supports[id] then
            --     if not campfire.data.supportsId then
            --         return string.format("Attach %s", common.helper.getGenericUtensilName(item))
            --     end
            -- end

            --Water for dousing
            --Liquids
            local fireLit = campfire.data.isLit
            if fireLit then
                -- local liquidContainer = LiquidContainer.createFromInventory(item, itemData)
                -- if liquidContainer then
                --     local hasWater = liquidContainer.waterAmount > 0
                --     local isStew = liquidContainer.waterType == "stew"
                --     if hasWater and not isStew then
                --         return string.format("Extinguish")
                --     end
                -- end
            else
                -- --Lights for lighting
                -- if item.objectType == tes3.objectType.light then
                --     local duration = itemData and itemData.timeLeft
                --     if duration and duration > 10 then
                --         return "Light Fire"
                --     end
                -- end
                -- --Firestarters for lighting
                -- if common.staticConfigs.firestarters[id] then
                --     return "Light Fire"
                -- end
            end
        end,
        canDrop = function(campfire, reference)
            common.log:debug("checking can drop")
            local id = reference.object.id:lower()
            -- --utensils
            -- if not campfire.data.grillId then
            --     if common.staticConfigs.grills[id] then
            --         return true
            --     end
            -- end
            -- if not campfire.data.bellowsId then
            --     if common.staticConfigs.bellows[id] then
            --         return true
            --     end
            -- end
            -- --firewood
            -- local isFirewood = id == common.staticConfigs.objectIds.firewood
            -- local hasRoom = campfire.data.fuelLevel < common.staticConfigs.maxWoodInFire
            -- if isFirewood and hasRoom then return true end

            -- --Supports
            -- local isSupports = common.staticConfigs.supports[id]
            -- local hasSupports = campfire.data.supportsId
            -- if isSupports and not hasSupports then return true end


            local fireLit = campfire.data.isLit
            if fireLit then
                -- --Water for dousing
                -- local liquidContainer = LiquidContainer.createFromReference(reference)
                -- if liquidContainer then
                --     local hasWater = liquidContainer and liquidContainer.waterAmount > 0
                --     local isStew = liquidContainer.waterType == "stew"
                --     if hasWater and not isStew then
                --         return true
                --     end
                -- end
            else
                -- --Torch for lighting fire
                -- if reference.baseObject.objectType == tes3.objectType.light then
                --     local duration = reference.attachments.variables.timeLeft
                --     if duration and duration > 10 then
                --         return true
                --     end
                -- end
                -- --Flint and Steel
                -- if common.staticConfigs.firestarters[id] then
                --     return true
                -- end
            end
            return false
        end,
        onDrop = function(campfire, reference)
            common.log:debug("Doing on drop")
            local id = reference.object.id:lower()
            local liquidContainer = LiquidContainer.createFromReference(reference)
            if liquidContainer then
                -- event.trigger("Ashfall:fuelConsumer_Extinguish", {fuelConsumer = campfire, playSound = true})
                -- liquidContainer:transferLiquid(LiquidContainer.createInfiniteWaterSource(), 10)
                -- tes3.playSound{ reference = tes3.player, sound = "Swim Left" }
                -- common.helper.pickUp(reference)
            elseif reference.object.objectType == tes3.objectType.light then
            --     common.log:debug("Lighting fire")
            --     reference.attachments.variables.timeLeft = reference.attachments.variables.timeLeft - 10
            --     event.trigger("Ashfall:fuelConsumer_Alight", { fuelConsumer = campfire})
            --     common.helper.pickUp(reference)
            -- elseif common.staticConfigs.firestarters[id] then
            --     common.log:debug("Lighting fire with firestarter")
            --     event.trigger("Ashfall:fuelConsumer_Alight", { fuelConsumer = campfire})
            --     common.helper.pickUp(reference)
            elseif common.staticConfigs.groundUtensils[id] then
                -- --Utensil
                -- if common.staticConfigs.grills[id] then
                --     --local grillData = common.staticConfigs.grills[item.id:lower()]
                --     campfire.data.hasGrill = true
                --     campfire.data.grillId = id
                --     campfire.data.grillPatinaAmount = reference.data.patinaAmount
                -- elseif common.staticConfigs.bellows[id] then
                --     campfire.data.bellowsId = id
                -- end
                -- local remaining = common.helper.reduceReferenceStack(reference, 1)
                -- if remaining > 0 then
                --     common.helper.pickUp(reference)
                -- end
                -- tes3.messageBox("Attached %s", common.helper.getGenericUtensilName(reference.object))
                -- event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire})
            elseif id == common.staticConfigs.objectIds.firewood then
                -- --Firewood
                -- local function getWoodFuel()
                --     local survivalEffect = math.min( math.remap(common.skills.survival.value, 0, 100, 1, 1.5), 1.5)
                --     return common.staticConfigs.firewoodFuelMulti * survivalEffect
                -- end
                -- local stackCount = common.helper.getStackCount(reference)


                -- campfire.data.fuelLevel = campfire.data.fuelLevel + getWoodFuel()
                -- if stackCount == 1 then
                --     tes3.messageBox("Added firewood.")
                --     common.helper.yeet(reference)
                --     tes3.playSound{ reference = tes3.player, sound = "ashfall_add_wood"  }
                -- else
                --     reference.attachments.variables.count = reference.attachments.variables.count - 1
                --     common.helper.pickUp(reference)
                --     tes3.messageBox("Added firewood.")
                --     tes3.playSound{ reference = tes3.player, sound = "ashfall_add_wood"  }
                -- end

                -- campfire.data.burned = false
                -- event.trigger("Ashfall:UpdateAttachNodes", { campfire = campfire})
            elseif common.staticConfigs.supports[id] then
                -- --attach supports
                -- campfire.data.supportsId = id
                -- local remaining = common.helper.reduceReferenceStack(reference, 1)
                -- if remaining > 0 then
                --     common.helper.pickUp(reference)
                -- end
                -- tes3.messageBox("Added %s", common.helper.getGenericUtensilName(reference.object))
                -- event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire})
            end
        end
    },
    DROP_HANG_UTENSIL = {
        dropText = function(campfire, item, itemData)
            if hangUtensil.showRequirements(campfire) then
                return string.format("Attach %s", common.helper.getGenericUtensilName(item))
            end
        end,
        canDrop = function(campfire, reference)
            common.log:debug("reference: %s", reference)
            local isUtensil = common.staticConfigs.utensils[reference.object.id:lower()]
            local campfireHasRoom = not campfire.data.utensilId
            common.log:debug("isUtensil: %s", isUtensil)
            common.log:debug("campfireHasRoom: %s", campfireHasRoom)
            return isUtensil and campfireHasRoom
        end,
        onDrop = function(campfire, reference)
            local utensilData = common.staticConfigs.utensils[reference.object.id:lower()]
            if utensilData.type == "cookingPot" then
                if tes3.getItemCount{ reference = tes3.player, item = "misc_com_iron_ladle"} > 0 then
                    tes3.removeItem{ reference = tes3.player, item = "misc_com_iron_ladle" }
                    campfire.data.ladle = true
                end
            end
            campfire.data.utensil = utensilData.type
            campfire.data.utensilId = reference.object.id:lower()
            campfire.data.utensilPatinaAmount = reference.data and reference.data.patinaAmount
            campfire.data.waterCapacity = utensilData.capacity or 100


            --If utensil has water, initialise the campfire with it
            if reference.data and reference.data.waterAmount then
                campfire.data.waterAmount =  reference.data.waterAmount
                campfire.data.stewLevels =  reference.data.stewLevels
                campfire.data.stewProgress = reference.data.stewProgress
                campfire.data.teaProgress = reference.data.teaProgress
                campfire.data.waterType =  reference.data.waterType
                campfire.data.waterHeat = reference.data.waterHeat or 0
                campfire.data.lastWaterUpdated = nil
            end

            local remaining = common.helper.reduceReferenceStack(reference, 1)
            if remaining > 0 then
                common.helper.pickUp(reference)
            end
            tes3.messageBox("Attached %s", common.helper.getGenericUtensilName(reference.object))

            common.log:debug("Set water capacity to %s", campfire.data.waterCapacity)
            common.log:debug("Set water heat to %s", campfire.data.waterHeat)
            common.log:debug("Set lastWaterUpdated to %s", campfire.data.lastWaterUpdated)
            event.trigger("Ashfall:registerReference", { reference = campfire})
            event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire})
        end
    },

    HANG_UTENSIL = {
        dropText = function(campfire, item, itemData)
            --Liquids
            local liquidContainer = LiquidContainer.createFromInventory(item, itemData)
            if liquidContainer and liquidContainer.waterAmount > 0 then
                return string.format("Add %s", liquidContainer:getLiquidName())
            end

            --Tea
            local teaData = teaConfig.teaTypes[item.id:lower()]
            if teaData then
                if not campfire.data.waterType then
                    return string.format("Brew %s", teaData.teaName)
                end
            end
        end,
        --onDrop for Stew handled separately, this only does tea
        canDrop = function(campfire, reference)
            local hasWater = campfire.data.waterAmount > 0
            local hasKettle = campfire.data.utensil == "kettle"
            local waterClean = not campfire.data.waterType
            local isTeaLeaf = teaConfig.teaTypes[reference.object.id:lower()]
            return hasWater and hasKettle and waterClean and isTeaLeaf
        end,
        onDrop = function(campfire, reference)
            campfire.data.waterType = reference.object.id:lower()
            campfire.data.teaProgress = 0
            local currentHeat = campfire.data.waterHeat or 0
            local newHeat = currentHeat + math.max(0, (campfire.data.waterHeat - 10))
            --CampfireUtil.setHeat(campfire.data, newHeat, campfire)
            campfire.data.waterHeat = newHeat
            local skillSurvivalTeaBrewIncrement = 5
            common.skills.survival:progressSkill(skillSurvivalTeaBrewIncrement)
            local remaining = common.helper.reduceReferenceStack(reference, 1)
            if remaining > 0 then
                common.helper.pickUp(reference)
            end
            tes3.messageBox("Added %s", reference.object.name)
            tes3.playSound{ reference = tes3.player, sound = "Swim Left" }
        end
    }
}

return DropConfig