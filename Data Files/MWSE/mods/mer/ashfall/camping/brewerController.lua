--[[
    Iterates over objects that  and updates their fuel level
]]
local common = require ("mer.ashfall.common.common")
local teaConfig = common.staticConfigs.teaConfig
--Tea resist
local temperatureController = require("mer.ashfall.temperatureController")
temperatureController.registerBaseTempMultiplier({ id = "firePetalTeaEffect", coldOnly = true })
temperatureController.registerBaseTempMultiplier({ id = "hollyTeaEffect", coldOnly = true })
local brewRate = 160
local updateInterval = 0.001


local function removeTeaEffect(teaData)
    if teaData.spell then
        common.helper.restoreFatigue()
        mwscript.removeSpell({ reference = tes3.player, spell = teaData.spell.id})
    elseif teaData.offCallback then
        teaData.offCallback()
    end
end

--Update Stew buffs for player and companions
local function updateBuffs(e)
    if common.data.teaDrank and common.data.teaBuffTimeLeft then
        common.data.lastTeaBuffUpdated = common.data.lastTeaBuffUpdated or e.timestamp

        local interval = e.timestamp - common.data.lastTeaBuffUpdated
        common.data.teaBuffTimeLeft = math.max((common.data.teaBuffTimeLeft - interval), 0)
        --time's up, remove spells and heat
        if common.data.teaBuffTimeLeft == 0 then
            local teaData = teaConfig.teaTypes[common.data.teaDrank]
            tes3.messageBox("%s effect has worn off.", teaData.teaName)
            removeTeaEffect(teaData)
            common.data.teaDrank = nil
            common.data.teaBuffTimeLeft = nil
            common.data.lastTeaBuffUpdated = nil
            
        else
            common.data.lastTeaBuffUpdated = e.timestamp
        end
    end

end
event.register("simulate", updateBuffs)


local function onDrinkTea(e)
    local teaType = e.teaType
    local teaData = teaConfig.teaTypes[teaType]
    local amount = e.amountDrank
    tes3.messageBox("Drank %s.", teaData.teaName)
    --remove previous tea
    if common.data.teaDrank then
        local previousTeaData = teaConfig.teaTypes[common.data.teaDrank]
        removeTeaEffect(previousTeaData)
    end

    if teaData.duration then
        common.data.teaBuffTimeLeft = common.helper.calculateTeaBuffDuration(amount,teaData.duration)
        common.data.teaDrank = teaType
    end

    if teaData.spell then
        local teaSpell = tes3.getObject(teaData.spell.id)
        if not teaSpell then 
            teaSpell = tes3spell.create(teaData.spell.id, teaData.teaName)
            teaSpell.castType = tes3.spellType.ability
            for i=1, #teaData.spell.effects do
                local effect = teaSpell.effects[i]
                local newEffect = teaData.spell.effects[i]

                effect.id = newEffect.id
                effect.attribute = newEffect.attribute
                effect.skill = newEffect.skill
                effect.rangeType = tes3.effectRange.self
                effect.min = newEffect.amount or 0
                effect.max = newEffect.amount or 0
                effect.radius = newEffect.radius
            end
        end
        mwscript.addSpell{ reference = tes3.player, spell = teaSpell }
    elseif teaData.onCallback then
        teaData.onCallback()
    end


end
event.register("Ashfall:DrinkTea", onDrinkTea)

local function updateBrewers(e)
    local function doUpdate(brewerRef)
        brewerRef.data.lastBrewUpdated = brewerRef.data.lastBrewUpdated or e.timestamp
        local difference = e.timestamp - brewerRef.data.lastBrewUpdated
        if difference > updateInterval then
            brewerRef.data.waterHeat =  brewerRef.data.waterHeat  or 0
            local hasWater = brewerRef.data.waterAmount and brewerRef.data.waterAmount > 0
            local waterIsBoiling = brewerRef.data.waterHeat >= common.staticConfigs.hotWaterHeatValue
            local hasTea = teaConfig.teaTypes[brewerRef.data.waterType]
            if hasWater and waterIsBoiling and hasTea then
                brewerRef.data.lastBrewUpdated = e.timestamp
                --Brew the Tea
                brewerRef.data.teaProgress = brewerRef.data.teaProgress or 0
                local waterHeatEffect = common.helper.calculateWaterHeatEffect(brewerRef.data.waterHeat)
                brewerRef.data.teaProgress = math.clamp((brewerRef.data.teaProgress + ( difference * brewRate * waterHeatEffect )), 0, 100)
            else
                brewerRef.data.lastBrewUpdated = nil
            end
        end
    end
    common.helper.iterateRefType("brewer", doUpdate) 
end

 event.register("simulate", updateBrewers)
