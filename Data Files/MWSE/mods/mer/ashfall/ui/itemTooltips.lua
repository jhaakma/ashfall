
--Tooltips
local common = require("mer.ashfall.common.common")
local tooltipsComplete = include("Tooltips Complete.interop")
local objectIds = common.staticConfigs.objectIds
local tooltipData = {
    { id = objectIds.firewood, description = "Fuel used at a campfire." },
    { id = objectIds.kettle, description = "Use at a campfire to brew tea." },
    { id = objectIds.grill, description = "Use at a campfire to cook meat and vegetables." },
    { id = objectIds.cookingPot, description = "Use at a campfire to boil water and cook stews." },
    { id = objectIds.bedroll, description = "A portable bedroll for sleeping out in the wilderness. Provides decent warmth but it won't shelter you from the rain."},
    { id = objectIds.bedroll_ashl, description = "A portable bedroll for sleeping out in the wilderness. Provides decent warmth but it won't shelter you from the rain."},
    { id = objectIds.canvasTent, description = "A canvas tent with red patterned tarpoline."},
    { id = objectIds.ashlanderTent, description = "A leather tent styled after the Ashlander tribes, complete with windchimes."},
    { id = objectIds.coveredBedroll, description = "A portable bedroll with a rain cover. This will keep you warm and shelter you from the rain when sleeping outdoors."},
    { id = objectIds.woodaxe, description = "An axe made for chopping wood. The hefty axehead is highly durable and can harvest firewood much faster than an axe made for combat." },
    { id = objectIds.pack_b, description = "A brown fur backpack of Nordic design." },
    { id = objectIds.pack_w, description = "A white fur backpack of Nordic design." },
    { id = objectIds.pack_n, description = "A backpack made of netch leather." }
}

for _, data in ipairs(tooltipData) do
    if tooltipsComplete then
        if tes3.getObject(data.id) then
            tooltipsComplete.addTooltip(data.id, data.description, data.itemType)
        end
    end
end