local common = require ("mer.ashfall.common.common")
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
    callback = function(campfire)
        --add grill
        tes3.addItem{
            reference = tes3.player,
            item = campfire.data.grillId,
            count = 1,
        }
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
        common.log:debug("Finding ingredients to drop")
        for _, cell in pairs( tes3.getActiveCells() ) do
            for ingredient in cell:iterateReferences(tes3.objectType.ingredient) do
                common.log:debug("ingredient: %s", ingredient.object.id)
                if common.helper.getCloseEnough{
                    --TODO: Implement using grill position
                    ref1 = campfire, ref2 = ingredient,
                    distVertical = 300,
                    distHorizontal = 50
                } then
                    common.log:debug("Dropping %s to ground", ingredient.object.id)
                    common.helper.orientRefToGround{ ref = ingredient}
                end
            end
        end
    end
    ,
}