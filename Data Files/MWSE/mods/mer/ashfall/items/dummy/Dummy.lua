local dummyConfig = require("mer.ashfall.items.dummy.config")
local common = require("mer.ashfall.common.common")
local logger = common.createLogger("Dummy")

---@class Ashfall.Dummy
local Dummy = {}

--Register an object ID as a dummy
--Hitting a dummy with a melee weapon will exercise the appropriate skill
---@param e { id: string }
function Dummy.registerDummy(e)
    logger:assert(type(e.id) == "string", "Dummy id must be a string")
    logger:debug("Registering dummy id: %s", e.id)
    dummyConfig.dummyIds[e.id:lower()] = true
end

--Register an object ID as a target
--Hitting a target with a projectile will exercise the marksman skill
---@param e { id: string }
function Dummy.registerTarget(e)
    logger:assert(type(e.id) == "string", "Target id must be a string")
    logger:debug("Registering target id: %s", e.id)
    dummyConfig.targetIds[e.id:lower()] = true
end

--Register a sound to play when a dummy is hit with a melee weapon
---@param e { soundPath: string }
function Dummy.registerDummySound(e)
    logger:assert(type(e.soundPath) == "string", "Sound path must be a string")
    logger:debug("Registering dummy sound: %s", e.soundPath)
    table.insert(dummyConfig.sounds.dummyHits, e.soundPath)
end

--Register a sound to play when a target is hit with a projectile
---@param e { soundPath: string }
function Dummy.registerArrowSound(e)
    logger:assert(type(e.soundPath) == "string", "Sound path must be a string")
    logger:debug("Registering arrow sound: %s", e.soundPath)
    table.insert(dummyConfig.sounds.arrowHits, e.soundPath)
end

--Check if a reference is a dummy
---@param reference tes3reference
function Dummy.isDummy(reference)
    local id = reference.baseObject.id
    if dummyConfig.dummyIds[string.lower(id)] then
        logger:trace("Is dummy: %s", id)
        return true
    end
end

--Check if a reference is a target
---@param reference tes3reference
function Dummy.isTarget(reference)
    local id = reference.baseObject.id
    if dummyConfig.targetIds[string.lower(id)] then
        logger:trace("Is target: %s", id)
        return true
    end
end

--Check if the player is currently looking at a dummy
function Dummy.isPlayerLookingAtDummy()
    local result = tes3.rayTest({
        position = tes3.getPlayerEyePosition(),
        direction = tes3.getPlayerEyeVector(),
        ignore = { tes3.player },
        accurateSkinned = true
    })
    if result and result.reference then
        local lookingAtDummy = Dummy.isDummy(result.reference)
        logger:trace("Looking at dummy: %s", lookingAtDummy)
        return lookingAtDummy
    end
    return false
end

--Get the current melee skill based on the player's readied weapon
---@return tes3skill?
function Dummy.getCurrentMeleeSkill()
    local skillIndex
    local weapon = tes3.mobilePlayer.readiedWeapon
    if not weapon then
        skillIndex = tes3.skill.handToHand
    else
        skillIndex = dummyConfig.weaponToSkillMapping[weapon.object.type]
    end

    if skillIndex then
        local skill = tes3.getSkill(skillIndex)
        logger:debug("Current melee skill: %s", skill.name)
        return skill
    end
end

--Roll for a successful hit
---@param skill tes3skill
---@return boolean didHit - whether the hit was successful
function Dummy.getHitSuccess(skill)
    --fatigue term
    local fFatigueBase = tes3.findGMST(tes3.gmst.fFatigueBase).value
    local fFatigueMult = tes3.findGMST(tes3.gmst.fFatigueMult).value
    local playerFatigue = tes3.mobilePlayer.fatigue
    local normalisedFatigue = playerFatigue.current / playerFatigue.base
    local fatigueTerm = fFatigueBase - fFatigueMult*(1 - normalisedFatigue)
    --attack term
    local agility = tes3.mobilePlayer.agility.current
    local luck = tes3.mobilePlayer.luck.current
    local attackTerm =(
         tes3.mobilePlayer.skills[skill.id + 1].current +
        0.2 * agility +
        0.1 * luck
    ) * fatigueTerm
    attackTerm = attackTerm + tes3.mobilePlayer.attackBonus
    attackTerm = attackTerm - tes3.mobilePlayer.blind

    --Be nice because its a stationary dummy
    attackTerm = 50 + attackTerm / 2

    --roll for hit
    local rand = math.random(100)
    local didHit = ( attackTerm > 0 and rand < attackTerm )
    logger:debug("Hit success for %s: %s", skill.name, didHit)
    return didHit
end

--Get the experience bonus for a skill
---@param thisSkill tes3skill
---@return number skillBonus
function Dummy.getSkillExperienceBonus(thisSkill)
    local function getGmstForSkill()
        local skillGroupToGmstBonus = {
            majorSkills = "fMajorSkillBonus",
            minorSkills = "fMinorSkillBonus",
        }
        --find gmst based on whether skill is Major, Minor or Misc
        for skillGroup, gmstName in pairs(skillGroupToGmstBonus) do
            for _, skill in ipairs(tes3.player.object.class[skillGroup]) do
                if skill == thisSkill.id then
                    return tes3.findGMST(tes3.gmst[gmstName])
                end
            end
        end
        return tes3.findGMST(tes3.gmst.fMiscSkillBonus)
    end
    local gmst = getGmstForSkill()
    return gmst and gmst.value or 1.0
end

--Exercise a weapon skill
---@param skill tes3skill
function Dummy.exerciseWeaponSkill(skill)
    local baseExperience = skill.actions[1]
    local skillBonus = Dummy.getSkillExperienceBonus(skill)
    local experience = baseExperience * skillBonus
    logger:debug("Exercising skill '%s' with %s experience", skill.name, experience)
    tes3.mobilePlayer:exerciseSkill(skill.id, experience)
end


return Dummy