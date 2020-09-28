local common = require("mer.ashfall.common.common")
local foodConfig = common.staticConfigs.foodConfig
--check that the creature is diseased
local function getDiseaseFromCreature(creatureRef)
    for spell in tes3.iterate(creatureRef.spells.iterator) do
        common.log:debug("Spell: %s", spell.id)
        if spell.castType == tes3.spellType.disease or spell.castType == tes3.spellType.blight then
            return spell
        end
    end
end

local function addDiseaseToMeat(reference, disease)
    local obj = reference.object
    for stack in tes3.iterate(obj.inventory.iterator) do
        if foodConfig.getFoodType(stack.object.id) == foodConfig.TYPE.meat then
            common.log:trace("Found %s, adding disease", stack.object.id)
            local count = stack.count
            --First itemData items
            if stack.variables then
                for _, variable in ipairs(stack.variables) do
                    variable.data.mer_disease = { id = disease.id, spellType = disease.castType }
                    count = count - variable.count
                end
            end
            --Then add to items without itemData
            if count > 0 then
                for i= 1, count do
                    local itemData = tes3.addItemData{
                        to = reference,
                        item = stack.object,
                        updateGUI = true
                    }
                    itemData.data.mer_disease = { id = disease.id, spellType = disease.castType }
                end
            end
        end
    end
end


local function addDiseaseOnDeath(e)
    if common.config.getConfig().enableDiseasedMeat then
        local baseObj = e.reference.baseObject or e.reference.object
        if baseObj.objectType == tes3.objectType.creature then
            
            local disease = getDiseaseFromCreature(e.reference.object)
            if disease then
                common.log:debug("Creature %s has %s", baseObj.name, disease.name)
                addDiseaseToMeat(e.reference, disease)
            end
        end
    end
end
event.register("death", addDiseaseOnDeath)