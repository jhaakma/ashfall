local common = require ("mer.ashfall.common.common")
local foodConfig = common.staticConfigs.foodConfig
local hungerController = require("mer.ashfall.needs.hungerController")
local thirstController = require("mer.ashfall.needs.thirstController")
return {
    text = "Eat Stew",
    requirements = function(campfire)
        return (
            campfire.data.stewLevels and 
            campfire.data.stewProgress and
            campfire.data.stewProgress == 100 and
            common.staticConfigs.conditionConfig.hunger:getValue() > 0.01
        )
    end,
    callback = function(campfire)
        local stewBuffs = foodConfig.getStewBuffList()
        --remove old sbuffs
        for foodType, buff in pairs(stewBuffs) do
            if campfire.data.stewLevels[foodType] == nil then
                mwscript.removeSpell{ reference = tes3.player, spell = buff.id }
            end
        end

        --Add buffs and set duration
        for foodType, ingredLevel in pairs(campfire.data.stewLevels) do
            --add spell
            local stewBuff = stewBuffs[foodType]
            local effectStrength = common.helper.calculateStewBuffStrength(math.min(ingredLevel, 100), stewBuff.min, stewBuff.max)
            timer.delayOneFrame(function()
                local spell = tes3.getObject(stewBuff.id)
                local effect = spell.effects[1]
                effect.min = effectStrength
                effect.max = effectStrength
                mwscript.addSpell{ reference = tes3.player, spell = spell }
                tes3.player.data.stewBuffTimeLeft = common.helper.calculateStewBuffDuration()
                event.trigger("Ashfall:registerReference", { reference = tes3.player})
            end)
        end

        --add up ingredients, mulitplying nutrition by % in the pot
        local nutritionLevel = 0
        local maxNutritionLevel = 0
        for foodType, _ in pairs(stewBuffs) do
            local nutrition = foodConfig.getNutritionForFoodType(foodType)
            nutritionLevel = nutritionLevel + ( nutrition * ( campfire.data.stewLevels[foodType] or 0 ) / 100 )
            maxNutritionLevel = nutritionLevel + nutrition
        end
        local foodRatio = nutritionLevel / maxNutritionLevel
        
        local highestNeed = math.max(common.staticConfigs.conditionConfig.hunger:getValue() / foodRatio, common.staticConfigs.conditionConfig.thirst:getValue())
        local maxDrinkAmount = math.min(campfire.data.waterAmount, 50, highestNeed )

        local amountAte = hungerController.eatAmount(maxDrinkAmount * foodRatio)
        local amountDrank = thirstController.drinkAmount(maxDrinkAmount, campfire.data.waterType)
        

        if amountAte >= 1 or amountDrank >= 1 then
            tes3.playSound{ reference = tes3.player, sound = "Swallow" }
            campfire.data.waterAmount = math.max( (campfire.data.waterAmount - amountDrank), 0)
            
            if campfire.data.waterHeat >= common.staticConfigs.hotWaterHeatValue then
                common.data.stewWarmEffect = common.helper.calculateStewWarmthBuff(campfire.data.waterHeat) 
            end

            if campfire.data.waterAmount == 0 then
                event.trigger("Ashfall:Campfire_clear_utensils", { campfire = campfire})
            end
            --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
        else
            tes3.messageBox("You are full.")
        end
        

        
    end
}