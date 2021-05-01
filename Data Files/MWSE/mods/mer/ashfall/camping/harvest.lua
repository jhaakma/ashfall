
local activatorController = require("mer.ashfall.activators.activatorController")
local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config.config").config
local activatorConfig = common.staticConfigs.activatorConfig
local lastRef


--How many swings required to collect wood. Randomised again after each harvest
local swingsNeeded
local swings = 0

local activatorMapping = {
    [activatorConfig.types.woodSource] = {
        name = "firewood",
        item = "ashfall_firewood",
        sound = "ashfall\\chopshort.wav",
        swingsNeeded = 4
    },
    [activatorConfig.types.vegetation] = {
        name = "plant fibre",
        item = "ashfall_plant_fibre",
        sound ="ashfall\\chopveg.wav",
        swingsNeeded = 2
    },
}

local function harvest(activator, weapon)
    local activatorConf = activatorMapping[activator]
    local swingStrength = tes3.mobilePlayer.actionData.attackSwing
    --More chop damage == more wood collected. Maxes out at chopCeiling. Range 0.0-1.0
    local chopCeiling = 50
    local axeDamageMultiplier = math.min(weapon.object.chopMax, chopCeiling) / chopCeiling

    local woodAxeMulti = 0.0
    local woodAxeConditionMulti = 1.0
    if common.staticConfigs.woodAxes[weapon.object.id:lower()] then
        common.log:debug("Using a woodaxe, reducing condition damage and swings needed")
        woodAxeMulti = 0.5
        woodAxeConditionMulti = 0.1
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
        --Weapon degradation, unequip if below 0
        weapon.variables.condition = weapon.variables.condition - (20 * swingStrength * woodAxeConditionMulti)
        if weapon.variables.condition <= 0 then
            weapon.variables.condition = 0
            tes3.mobilePlayer:unequip{ type = tes3.objectType.weapon }
            --mwscript.playSound({reference=playerRef, sound="Item Misc Down"})
            return
        end

        local function getSwingsNeeded()
            return math.random(activatorConf.swingsNeeded, activatorConf.swingsNeeded + 2)
        end
        
        if not swingsNeeded then
            swingsNeeded = getSwingsNeeded()
        end
        
        --wait until chopped enough times
        if swings >= swingsNeeded then 
            --wood collected based on strength of previous swings
            --Between 0.5 and 1.0 (at chop == 50)

            --if skills are implemented, use Survival Skill                
            local survivalSkill = common.skills.survival.value or 30
            --cap at 100
            survivalSkill = ( survivalSkill < 100 ) and survivalSkill or 100
            --Between 0.5 and 1.0 (at 100 Survival)
            local survivalMultiplier = 1 + ( survivalSkill / 50 )
            local numHarvested =  math.floor( ( 1 + math.random() * 2 )  * survivalMultiplier )
            --Max 8
            numHarvested = ( numHarvested < 100 ) and numHarvested or 8
            --minimum 1 wood collected
            if numHarvested == 1 then
                tes3.messageBox("You have harvested 1 piece of %s.", activatorConf.name)
            else
                tes3.messageBox("You have harvested %d pieces of %s.", numHarvested, activatorConf.name)
            end
            
            tes3.playSound({reference=tes3.player, sound="Item Misc Up"})
            mwscript.addItem{reference=tes3.player, item= activatorConf.item, count=numHarvested}
            event.trigger("Ashfall:triggerPackUpdate")
            common.skills.survival:progressSkill(swingsNeeded*2)
            --reset swings
            swings = 0
            swingsNeeded = getSwingsNeeded()
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
