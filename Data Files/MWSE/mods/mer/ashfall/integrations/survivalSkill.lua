local common = require("mer.ashfall.common.common")
local logger = common.createLogger("Skills")

--INITIALISE SKILLS--
local SkillsModule = include("SkillsModule")
if not SkillsModule then
    common.log:error("Skills Module not found. Ashfall will not work correctly.")
    return
end

local skills = {
    survival = {
        id = "Ashfall:Survival",
        name = "Survival",
        icon = "Icons/ashfall/survival.dds",
        value = 10,
        attribute = tes3.attribute.endurance,
        description = "The Survival skill determines your ability to deal with harsh weather conditions and perform actions such as creating campfires effectively and cooking food with them. A higher survival skill also reduces the chance of getting food poisoning or dysentery from drinking dirty water.",
        specialization = tes3.specialization.stealth
    },
    bushcrafting = {
        id = "Bushcrafting",
        name = "Bushcrafting",
        icon = "Icons/ashfall/bushcrafting.dds",
        value = 10,
        attribute = tes3.attribute.intelligence,
        description = "The Bushcrafting skill determines your ability to craft items from materials gathered in the wilderness. A higher bushcrafting skill unlocks more crafting recipes.",
        specialization = tes3.specialization.combat
    }
}
for skill, data in pairs(skills) do
    logger:debug("Registering %s skill", skill)
    SkillsModule.registerSkill(data)
    common.skills[skill] = SkillsModule.getSkill(data.id)
end

--INITIALISE SKILL MODIFIERS--
local classModifiers = {
    ["Acrobat"] = 5,
    ["Barbarian"] = 5,
    ["Pilgrim"] = 5,
    ["Scout"] = 10,
}
for class, amount in pairs(classModifiers) do
        SkillsModule.registerClassModifier{
            class = class,
            skill = "Ashfall:Survival",
            amount = amount
        }
end

logger:info("Ashfall skills registered")
