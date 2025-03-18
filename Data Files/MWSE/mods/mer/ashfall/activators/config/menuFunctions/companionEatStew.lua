local common = require ("mer.ashfall.common.common")
local foodConfig = common.staticConfigs.foodConfig

---@return tes3reference[]
local function getNearbyCompanions()
    ---@type tes3reference[]
    local nearbyCompanions = {}
    ---@param companion tes3mobileActor
    for companion in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
        if tes3.getCurrentAIPackageId{reference = companion} == tes3.aiPackage.follow then
            table.insert(nearbyCompanions, companion.reference)
        end
    end
    return nearbyCompanions
end


return {
    text = "Feed Companions",
    showRequirements = function(reference)

        if not reference.supportsLuaData then return false end
        local nearbyCompanions = getNearbyCompanions()
        return (
            reference.data.stewLevels and
            reference.data.stewProgress and
            reference.data.stewProgress == 100 and
           #(nearbyCompanions) > 0
        )
    end,
    callback = function(reference)
        local nearbyCompanions = getNearbyCompanions()
        if #nearbyCompanions == 0 then return end
        local maxAvailable = math.min(reference.data.waterAmount, 25 * #nearbyCompanions)
        local stewPerCompanion = maxAvailable / #nearbyCompanions

        local stewBuffs = foodConfig.getStewBuffList()
        for _, companion in ipairs(nearbyCompanions) do
            --remove old sbuffs
            for name, buff in pairs(stewBuffs) do
                if reference.data.stewLevels[name] == nil then
                    tes3.removeSpell{ reference = companion, spell = buff.id }
                end
            end

            --Add buffs and set duration
            for foodType, ingredLevel in pairs(reference.data.stewLevels) do
                --add spell
                local stewBuff = stewBuffs[foodType]
                local effectStrength = common.helper.calculateStewBuffStrength(math.min(ingredLevel, 100), stewBuff.min, stewBuff.max)

                local safeRef = tes3.makeSafeObjectHandle(companion)
                timer.delayOneFrame(function()
                    if not (safeRef and safeRef:valid()) then return end
                    local spell = tes3.getObject(stewBuff.id)
                    local effect = spell.effects[1]
                    effect.min = effectStrength
                    effect.max = effectStrength
                    tes3.addSpell{ reference = companion, spell = spell }
                    companion.data.stewBuffTimeLeft = common.helper.calculateStewBuffDuration(reference.data.waterHeat)
                    event.trigger("Ashfall:registerReference", { reference = companion})
                end)
            end
            tes3.playSound{ reference = companion, sound = "Swallow" }
            event.trigger("Ashfall:Eat", { reference = companion, amount = stewPerCompanion})
        end
        local stewName = foodConfig.isStewNotSoup(reference.data.stewLevels) and "stew" or "soup"
        tes3.messageBox("Your companions eat the %s.", stewName)

        reference.data.waterAmount = reference.data.waterAmount - maxAvailable

        if reference.data.waterAmount < 1 then
            event.trigger("Ashfall:Campfire_clear_utensils", { campfire = reference})
        end

    end
}