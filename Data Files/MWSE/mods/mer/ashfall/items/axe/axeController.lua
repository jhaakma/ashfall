
local activatorController = require("mer.ashfall.activators.activatorController")
local common = require("mer.ashfall.common.common")
local woodAxeConfig = require("mer.ashfall.items.axe.config")
local config = require("mer.ashfall.config.config").config
local activatorConfig = common.staticConfigs.activatorConfig
local lastRef


--How many swings required to collect wood. Randomised again after each harvest
local swingsNeeded
local swings = 0

local activatorMapping = {
    [activatorConfig.types.woodSource] = {
        name = "firewood",
        items = {
            { id = "ashfall_firewood", count = 6, chance = 1.0 },
        },
        sound = "ashfall\\chopshort.wav",
        swingsNeeded = 4
    },
    [activatorConfig.types.resinSource] ={
        name = "firewood",
        items = {

            { id = "ashfall_firewood", count = 6, chance = 0.6 },
            { id = "ingred_resin_01", count = 3, chance = 0.4 },
        },
        sound = "ashfall\\chopshort.wav",
        swingsNeeded = 4
    },
    [activatorConfig.types.vegetation] = {
        name = "plant fibre",
        items = {
            { id = "ashfall_plant_fibre", count = 6, chance = 1.4 },
        },
        sound ="ashfall\\chopveg.wav",
        swingsNeeded = 2
    },
}

local function isWoodAxe(ref)
    return woodAxeConfig.woodAxes[ref.object.id:lower()] ~= nil
end

--Returns true if weapon is totally broken
local function degradeWeapon(weaponRef, swingStrength)
    local conditionMulti = isWoodAxe(weaponRef) and 0.1 or 1
    --Weapon degradation
    weaponRef.variables.condition = weaponRef.variables.condition - (20 * swingStrength * conditionMulti)
    --weapon is broken, unequip
    if weaponRef.variables.condition <= 0 then
        weaponRef.variables.condition = 0
        tes3.mobilePlayer:unequip{ type = tes3.objectType.weapon }
        return true
    end
end

local function getSwingsNeeded(activatorConf)
    return math.random(activatorConf.swingsNeeded, activatorConf.swingsNeeded + 2)
end

--determine how many wood is harvested based on survival skill
local function calcNumHarvested(harvestable)
    --if skills are implemented, use Survival Skill
    local survivalSkill = math.clamp(common.skills.survival.value or 30, 0, 100)
    local survivalMulti = math.remap(survivalSkill, 0, 100, 0.5, 1)
    local numHarvested = math.ceil(math.random(1, harvestable.count) * survivalMulti)
    return numHarvested
end

local function showHarvestedMessage(numHarvested, harvestName)
    local message = string.format("You harvest %s %s of %s", numHarvested, numHarvested > 1 and "pieces" or "piece", harvestName)
    tes3.messageBox(message)
end

local function addItems(activatorConfig)
    local roll = math.random()
    common.log:debug("Roll: %s", roll)
    for _, harvestable in ipairs(activatorConfig.items) do
        local chance = harvestable.chance
        common.log:debug("Chance: %s", chance)
        if roll <= chance then
            common.log:debug("Adding %s", harvestable.id)
            tes3.playSound({reference=tes3.player, sound="Item Misc Up"})
            local numHarvested = calcNumHarvested(harvestable)
            tes3.addItem{reference=tes3.player, item= harvestable.id, count=numHarvested}
            showHarvestedMessage(numHarvested, tes3.getObject(harvestable.id).name)
            event.trigger("Ashfall:triggerPackUpdate")
            return
        end
        roll = roll - harvestable.chance
    end
end


local function harvest(activator, weapon)
    local activatorConf = activatorMapping[activator]
    local swingStrength = tes3.mobilePlayer.actionData.attackSwing
    --More chop damage == more wood collected. Maxes out at chopCeiling. Range 0.0-1.0
    local chopCeiling = 50
    local axeDamageMultiplier = math.min(weapon.object.chopMax, chopCeiling) / chopCeiling

    local woodAxeMulti = 0.0
    if woodAxeConfig.woodAxes[weapon.object.id:lower()] then
        common.log:debug("Using a woodaxe, reducing condition damage and swings needed")
        woodAxeMulti = 0.5
    end

    --If attacking the same target, accumulate swings
    local targetRef = activatorController.currentRef
    if lastRef == targetRef then
        swings = swings + swingStrength * ( 1 + axeDamageMultiplier + woodAxeMulti )
    else
        lastRef = targetRef
        swings = 0
    end

    --Check if legal to harvest wood
    local illegalToHarvest = (
        config.illegalHarvest and
        tes3.getPlayerCell().restingIsIllegal
    )
    if illegalToHarvest then
        tes3.messageBox("You must be in the wilderness to harvest %s.", activatorConf.name)
    else
        tes3.playSound({reference=tes3.player, soundPath = activatorConf.sound})
        if degradeWeapon(weapon, swingStrength) then
           return
        end
        swingsNeeded = swingsNeeded or getSwingsNeeded(activatorConf)
        --wait until chopped enough times
        if swings >= swingsNeeded then
            --wood collected based on strength of previous swings
            --Between 0.5 and 1.0 (at chop == 50)
            addItems(activatorConf)
            common.skills.survival:progressSkill(swingsNeeded*2)
            --reset swings
            swings = 0
            swingsNeeded = getSwingsNeeded(activatorConf)
        end
    end
end

local function getIsAxe(weapon)
    local swingType = tes3.mobilePlayer.actionData.attackDirection
    --Chopping with an axe--
    local chop = 2
    local axe1h = 7
    local axe2h = 8
    local isAxe = weapon
    and swingType == chop
    and (weapon.object.type == axe1h or weapon.object.type == axe2h)
    return isAxe
end

local function onAttack(e)
    if e.mobile.reference == tes3.player then
        local weapon = tes3.mobilePlayer.readiedWeapon
        if getIsAxe(weapon) then
            local activatorType = activatorController.getCurrentType()
            local active = activatorType and config[activatorController.getCurrentActivator().mcmSetting] ~= false
            if activatorMapping[activatorType] and active then
                harvest(activatorType, weapon)
            end
        end
    end
end

event.register("attack", onAttack )
