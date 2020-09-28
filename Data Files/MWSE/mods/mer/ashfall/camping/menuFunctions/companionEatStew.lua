local common = require ("mer.ashfall.common.common")
local foodConfig = common.staticConfigs.foodConfig
local nearbyCompanions
local function getNearbyCompanions()
    nearbyCompanions = {}
    for companion in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
        if tes3.getCurrentAIPackageId(companion) == tes3.aiPackage.follow then
            table.insert(nearbyCompanions, companion)
        end
    end
end


return {
    text = "Feed Companions",
    requirements = function(campfire)
        getNearbyCompanions()
        return (
            campfire.data.stewLevels and 
            campfire.data.stewProgress and
            campfire.data.stewProgress == 100 and
           #(nearbyCompanions) > 0
        )
    end,
    callback = function(campfire)

        local maxAvailable = math.min(campfire.data.waterAmount, 25 * #nearbyCompanions)
        local stewPerCompanion = maxAvailable / #nearbyCompanions

        local stewBuffs = foodConfig.getStewBuffList()
        for _, companion in ipairs(nearbyCompanions) do
            --remove old sbuffs
            for name, buff in pairs(stewBuffs) do
                if campfire.data.stewLevels[name] == nil then
                    mwscript.removeSpell{ reference = companion, spell = buff.id }
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
                    mwscript.addSpell{ reference = companion, spell = spell }
                    companion.reference.data.stewBuffTimeLeft = common.helper.calculateStewBuffDuration()
                    event.trigger("Ashfall:registerReference", { reference = companion})
                end)
            end
            tes3.playSound{ reference = companion, sound = "Swallow" }
            event.trigger("Ashfall:Eat", { reference = companion.reference, amount = stewPerCompanion})
        end

        tes3.messageBox("Your companions eat the stew.")
        
        campfire.data.waterAmount = campfire.data.waterAmount - maxAvailable

        if campfire.data.waterAmount == 0 then
            event.trigger("Ashfall:Campfire_clear_utensils", { campfire = campfire})
        end
        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})

    end
}