---@class Ashfall.Dummy.config
local dummyConfig = {}

dummyConfig.dummyIds = {}

dummyConfig.targetIds = {}

dummyConfig.sounds = {
    dummyHits = {},
    arrowHits = {}
}

dummyConfig.weaponToSkillMapping = {
    [tes3.weaponType.shortBladeOneHand] = tes3.skill.shortBlade,
    [tes3.weaponType.longBladeOneHand] = tes3.skill.longBlade,
    [tes3.weaponType.longBladeTwoClose] = tes3.skill.longBlade,
    [tes3.weaponType.bluntOneHand] = tes3.skill.bluntWeapon,
    [tes3.weaponType.bluntTwoClose] = tes3.skill.bluntWeapon,
    [tes3.weaponType.bluntTwoWide] = tes3.skill.bluntWeapon,
    [tes3.weaponType.spearTwoWide] = tes3.skill.spear,
    [tes3.weaponType.axeOneHand] = tes3.skill.axe,
    [tes3.weaponType.axeTwoHand] = tes3.skill.axe,
}

return dummyConfig