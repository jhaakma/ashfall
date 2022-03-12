local dummyIds = {
    ["ashfall_dummy_01"] = true
}
local targetIds = {
    ["ashfall_target_01"] = true
}
local sounds = {
    dummyHits = {
        "ashfall\\dummy\\hit1.wav",
        "ashfall\\dummy\\hit2.wav",
        "ashfall\\dummy\\hit3.wav",
        "ashfall\\dummy\\hit4.wav",
        "ashfall\\dummy\\hit5.wav",
    },
    arrowHits = {
        "ashfall\\dummy\\arrow1.wav",
        "ashfall\\dummy\\arrow2.wav",
        "ashfall\\dummy\\arrow3.wav",
    }
}

local weaponToSkillMapping = {
    [tes3.weaponType.shortBladeOneHand] = tes3.skill.shortBlade,
    [tes3.weaponType.longBladeOneHand] = tes3.skill.longBlade,
    [tes3.weaponType.longBladeTwoClose] = tes3.skill.longBlade,
    [tes3.weaponType.bluntOneHand] = tes3.skill.blunt,
    [tes3.weaponType.bluntTwoClose] = tes3.skill.blunt,
    [tes3.weaponType.bluntTwoWide] = tes3.skill.blunt,
    [tes3.weaponType.spearTwoWide] = tes3.skill.spear,
    [tes3.weaponType.axeOneHand] = tes3.skill.axe,
    [tes3.weaponType.axeTwoHand] = tes3.skill.axe,
}

local function isDummy(reference)
    local id = reference.baseObject.id
    if dummyIds[string.lower(id)] then
        return true
    end
end

local function isTarget(reference)
    local id = reference.baseObject.id
    if targetIds[string.lower(id)] then
        return true
    end
end

local function isPlayerLookingAtDummy()
    local result = tes3.rayTest({
        position = tes3.getPlayerEyePosition(),
        direction = tes3.getPlayerEyeVector(),
        ignore = { tes3.player },
    })
    if result and result.reference then
        return isDummy(result.reference)
    end
    return false
end

local function getCurrentMeleeSkill()
    local skillIndex
    local weapon = tes3.mobilePlayer.readiedWeapon
    if not weapon then
        skillIndex = tes3.skill.handToHand
    else
        skillIndex = weaponToSkillMapping[weapon.object.type]
    end
    if skillIndex then
        return tes3.getSkill(skillIndex)
    end
    --false for marksman
    return false
end

local function getHitSuccess(skill)
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
    return didHit
end

local function getSkillExperienceBonus(thisSkill)
    local function getGmstForSkill()
        local skillGroupToGmstBonus = {
            majorSkills = "fMajorSkillBonus",
            minorSkills = "fMinorSkillBonus",
        }
        --find gmst based on whether skill is Major, Minor or Misc
        for skillGroup, gmstName in pairs(skillGroupToGmstBonus) do
            for _, skill in ipairs(tes3.player.object.class[skillGroup]) do
                if skill == thisSkill.index then
                    return tes3.findGMST(tes3.gmst[gmstName])
                end
            end
        end
        return tes3.findGMST(tes3.gmst.fMiscSkillBonus)
    end
    local gmst = getGmstForSkill()
    return gmst and gmst.value or 1.0
end

---@param skill tes3skill
local function exerciseWeaponSkill(skill)
    local baseExperience = skill.actions[1]
    local skillBonus = getSkillExperienceBonus(skill)
    local experience = baseExperience * skillBonus
    tes3.mobilePlayer:exerciseSkill(skill.id, experience)
end


--Melee Attacks
---@param e attackEventData
local function onAttack(e)
    if e.reference == tes3.player then
        if isPlayerLookingAtDummy() then
            local meleeSkill = getCurrentMeleeSkill()
            if meleeSkill then
                if getHitSuccess(meleeSkill) then
                    exerciseWeaponSkill(meleeSkill)
                    local sound = table.choice(sounds.dummyHits)
                    tes3.playSound{ soundPath = sound, reference = e.targetReference }
                else
                    tes3.playSound{ sound = "miss"}
                end
            end
        end
    end
end
event.register("attack", onAttack )

--Projectiles
local function onProjectileHitObject(e)
    if e.firingReference == tes3.player then
        if isTarget(e.target) then
            local skill = tes3.getSkill(tes3.skill.marksman)
            if getHitSuccess(skill) then
                exerciseWeaponSkill(skill)
                local sound = table.choice(sounds.arrowHits)
                tes3.playSound{ soundPath = sound }
            end
        end
    end
end
event.register("projectileHitObject", onProjectileHitObject)