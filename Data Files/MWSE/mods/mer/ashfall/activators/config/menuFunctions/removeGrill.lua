local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("removeGrill")
return {
    text = function(campfire)
        local grillId = campfire.data.grillId
        local grill = tes3.getObject(grillId)
        return string.format("Remove %s", common.helper.getGenericUtensilName(grill) or "Utensil")
    end,
    showRequirements = function(reference)

        if not reference.supportsLuaData then return false end
        return (
            reference.data.grillId
            and (not reference.data.dynamicConfig) or
            reference.data.dynamicConfig.grill == "dynamic"
        )
    end,
    tooltip = function()
        return common.helper.showHint(string.format(
            "You can pick this up directly by holding %s and activating.",
            common.helper.getModifierKeyString()
        ))
    end,
    callback = function(reference)
        local grillId = reference.data.grillId
        local grillData = common.staticConfigs.grills[grillId:lower()]
        if grillData and grillData.materials then
            logger:debug("Grill was crafted, adding back .5 materials")
            for id, count in pairs(grillData.materials) do
                count = math.floor(count / 2)
                if count > 0 then
                    tes3.addItem{
                        reference = tes3.player,
                        item = id, count =
                        count,
                        playSound = false,
                        showMessage = true,
                    }
                end
                common.helper.playDeconstructionSound()
            end
        else
            --add grill
            tes3.addItem{
                reference = tes3.player,
                item = grillId,
                count = 1,
                playSound = false
            }
        end

        --add patina data
        if reference.data.grillPatinaAmount then
            local itemData = tes3.addItemData{
                to = tes3.player,
                item = reference.data.grillId,
            }
            itemData.data.patinaAmount = reference.data.grillPatinaAmount
        end
        --clear data and trigger updates
        reference.data.grillId = nil
        reference.data.hasGrill = nil
        reference.data.grillPatinaAmount = nil
        event.trigger("Ashfall:UpdateAttachNodes", { reference = reference,})
        --drop any cooking ingredients
        logger:debug("Finding ingredients to drop")
        for _, cell in pairs( tes3.getActiveCells() ) do
            for ingredient in cell:iterateReferences(tes3.objectType.ingredient) do
                logger:debug("ingredient: %s", ingredient.object.id)
                if common.helper.getCloseEnough{
                    --TODO: Implement using grill position
                    ref1 = reference, ref2 = ingredient,
                    distVertical = 300,
                    distHorizontal = 50
                } then
                    logger:debug("Dropping %s to ground", ingredient.object.id)
                    common.helper.orientRefToGround{ ref = ingredient}
                end
            end
        end
    end
    ,
}