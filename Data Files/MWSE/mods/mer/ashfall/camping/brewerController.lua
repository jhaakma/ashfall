--[[
    Iterates over objects that  and updates their fuel level
]]
local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("brewerController")
local teaConfig = common.staticConfigs.teaConfig
local LiquidContainer = require("mer.ashfall.objects.LiquidContainer")
--Tea resist
local temperatureController = require("mer.ashfall.temperatureController")
temperatureController.registerBaseTempMultiplier({ id = "firePetalTeaEffect", coldOnly = true })
temperatureController.registerBaseTempMultiplier({ id = "hollyTeaEffect", coldOnly = true })
local brewRate = 160
local BREWER_UPDATE_INTERVAL = 0.001


local function removeTeaEffect(teaData)
    logger:debug("onDrinkTea: removing previous effect")
    if teaData.spell then
        --DelayThreeFrames, to give the spell plenty of time to initialise if drinking multiple teas from inventory
        timer.delayOneFrame(function()timer.delayOneFrame(function()timer.delayOneFrame(function()
            common.helper.restoreFatigue()
            mwscript.removeSpell({ reference = tes3.player, spell = teaData.spell.id})
        end)end)end)
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
    logger:debug("onDrinkTea")
    local teaType = e.teaType
    local teaData = teaConfig.teaTypes[teaType]
    local amount = e.amountDrank
    tes3.messageBox("Drank %s.", teaData.teaName)
    --remove previous tea, but not if same tea
    if common.data.teaDrank  and common.data.teaDrank ~= teaType then
        local previousTeaData = teaConfig.teaTypes[common.data.teaDrank]
        removeTeaEffect(previousTeaData)
    end

    if teaData.duration then
        local durationEffect = common.helper.calculateTeaBuffDuration(teaData.duration,  e.heat)
        --Effect maxes out at 10 units, then divide remaining 10 by 10 to get normalised effect
        local amountEffect = math.min(10, amount/10)
        --give at least half an hour when drinking a small amount
        local timeLeft = math.max(0.5, amountEffect * durationEffect)
        common.data.teaBuffTimeLeft = timeLeft
        common.data.teaDrank = teaType
        logger:debug("onDrinkTea: setting duration to %s", timeLeft)
    end

    if teaData.spell then

        local teaSpell = tes3.getObject(teaData.spell.id)
        if not teaSpell then
            logger:debug("onDrinkTea: Creating new spell")
            teaSpell = tes3spell.create(teaData.spell.id, teaData.teaName)
        end
        teaSpell.castType = teaData.spell.spellType or tes3.spellType.ability
        for i=1, #teaData.spell.effects do
            local effect = teaSpell.effects[i]
            local newEffect = teaData.spell.effects[i]
            effect.duration = newEffect.duration
            effect.id = newEffect.id
            effect.attribute = newEffect.attribute
            effect.skill = newEffect.skill
            effect.rangeType = tes3.effectRange.self
            effect.min = newEffect.amount or 0
            effect.max = newEffect.amount or 0
            effect.radius = newEffect.radius
        end

        logger:debug("onDrinkTea: has spell: adding %s", teaData.spell.id)

        --delay 3 frames to let the previous tea spell wear off
        if teaSpell.castType == tes3.spellType.ability then
            logger:debug("Applying tea effect as ability")
            mwscript.addSpell{ reference = tes3.player, spell = teaSpell }
        else
            logger:debug("Applying tea spell as magic source")
            tes3.applyMagicSource{
                reference = tes3.player,
                source = teaSpell,
                castChance = 100,
                bypassResistances = true,
            }
        end
    elseif teaData.onCallback then
        logger:debug("onDrinkTea: callback")
        teaData.onCallback()
    end


end
event.register("Ashfall:DrinkTea", onDrinkTea)

local function updateBrewers(e)
    local function doUpdate(brewerRef_)
        ---@type AshfallLiquidContainer
        local liquidContainer = LiquidContainer.createFromReference(brewerRef_)
        liquidContainer.data.lastBrewUpdated = liquidContainer.data.lastBrewUpdated or e.timestamp
        local difference = e.timestamp - liquidContainer.data.lastBrewUpdated

        if difference < 0 then
            logger:error("BREWER liquidContainer.data.lastBrewUpdated(%.4f) is ahead of e.timestamp(%.4f).",
                liquidContainer.data.lastBrewUpdated, e.timestamp)
            --something fucky happened
            liquidContainer.data.lastBrewUpdated = e.timestamp
        end

        if difference > BREWER_UPDATE_INTERVAL then
            liquidContainer.lastBrewUpdated = e.timestamp
            local hasWater = liquidContainer.waterAmount and liquidContainer.waterAmount > 0
            if hasWater then
                liquidContainer.waterHeat =  liquidContainer.waterHeat  or 0
                local waterIsBoiling = liquidContainer.waterHeat >= common.staticConfigs.hotWaterHeatValue
                local hasTea = liquidContainer:getLiquidType() == "tea"
                if waterIsBoiling and hasTea then
                    --Brew the Tea
                    local waterHeatEffect = common.helper.calculateWaterHeatEffect(liquidContainer.waterHeat)
                    liquidContainer.teaProgress = math.clamp((liquidContainer.teaProgress + ( difference * brewRate * waterHeatEffect )), 0, 100)
                else
                    liquidContainer.data.lastBrewUpdated = nil
                end
            end
        end
    end
    common.helper.iterateRefType("brewer", doUpdate)
end

 event.register("simulate", updateBrewers)
