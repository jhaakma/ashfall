
-- --[[
--     Skills
-- ]]
-- local skillModule = include("OtherSkills.skillModule")
-- local logger = require("mer.ashfall.common.logger")
-- local skills = {}
-- --INITIALISE SKILLS--
-- skills.skillStartValue = 10
-- local function onSkillsReady()
--     if not skillModule then
--         timer.start({
--             callback = function()
--                 tes3.messageBox({message = "Please install Skills Module", buttons = {"Okay"} })
--             end,
--             type = timer.simulate,
--             duration = 1.0
--         })

--     end

--     if ( skillModule.version == nil ) or ( skillModule.version < 1.4 ) then
--         timer.start({
--             callback = function()
--                 tes3.messageBox({message = string.format("Please update Skills Module"), buttons = {"Okay"} })
--             end,
--             type = timer.simulate,
--             duration = 1.0
--         })
--     end

--     skillModule.registerSkill(
--         "Ashfall:Survival", 
--         {    
--             name = "Survival", 
--             icon = "Icons/ashfall/survival.dds",
--             value = skills.skillStartValue,
--             attribute = tes3.attribute.endurance,
--             description = "The Survival skill determines your ability to deal with harsh weather conditions and perform actions such as chopping wood and creating campfires effectively. A higher survival skill also reduces the chance of getting food poisoning or dysentery from drinking dirty water.",
--             specialization = tes3.specialization.stealth
--         }
--     )

--     skillModule.registerSkill(
--         "Ashfall:Cooking", 
--         {    
--             name = "Cooking", 
--             icon = "Icons/ashfall/cooking.dds",
--             value = skills.skillStartValue,
--             attribute = tes3.attribute.intelligence,
--             description = "The cooking skill determines your effectiveness at cooking meals. The higher your cooking skill, the higher the nutritional value of cooked meats and vegetables, and the stronger the buffs given by stews. A higher cooking skill also increases the time before food will burn on a grill.",
--             specialization = tes3.specialization.magic
--         }
--     )

--     skills.survival = skillModule.getSkill("Ashfall:Survival")
--     --skills.cooking = skillModule.getSkill("Ashfall:Cooking")

--     logger.info("Ashfall skills registered")
-- end
-- event.register("OtherSkills:Ready", onSkillsReady)

-- return skills