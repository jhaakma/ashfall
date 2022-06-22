local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("removeGrill")
return {
    text = function(campfire)
        local grillId = campfire.data.grillId
        local grill = tes3.getObject(grillId)
        return string.format("Remove %s", common.helper.getGenericUtensilName(grill) or "Utensil")
    end,
    showRequirements = function(campfire)
        return (
            campfire.data.grillId
            and (not campfire.data.dynamicConfig) or
            campfire.data.dynamicConfig.grill == "dynamic"
        )
    end,
    tooltip = function()
        return common.helper.showHint(string.format(
            "You can pick this up directly by holding %s and activating.",
            common.helper.getModifierKeyString()
        ))
    end,
    callback = function(campfire)
        local grillId = campfire.data.grillId
        local grillData = common.staticConfigs.grills[grillId:lower()]
        if grillData and grillData.materials then
            logger:debug("Grill was crafted, adding back .5 materials")
            for id, count in pairs(grillData.materials ) do
                local item = tes3.getObject(id)
                count = math.floor(count / 2)
                if count > 0 then
                    tes3.addItem{ reference = tes3.player, item = item, count = count, playSound = false}
                    tes3.messageBox(tes3.findGMST(tes3.gmst.sNotifyMessage61).value, count, item.name)
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
        if campfire.data.grillPatinaAmount then
            local itemData = tes3.addItemData{
                to = tes3.player,
                item = campfire.data.grillId,
            }
            itemData.data.patinaAmount = campfire.data.grillPatinaAmount
        end
        --clear data and trigger updates
        campfire.data.grillId = nil
        campfire.data.hasGrill = nil
        campfire.data.grillPatinaAmount = nil
        event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire,})
        --drop any cooking ingredients
        logger:debug("Finding ingredients to drop")
        for _, cell in pairs( tes3.getActiveCells() ) do
            for ingredient in cell:iterateReferences(tes3.objectType.ingredient) do
                logger:debug("ingredient: %s", ingredient.object.id)
                if common.helper.getCloseEnough{
                    --TODO: Implement using grill position
                    ref1 = campfire, ref2 = ingredient,
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