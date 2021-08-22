
--Tooltips
local common = require("mer.ashfall.common.common")
local tooltipsComplete = include("Tooltips Complete.interop")
local objectIds = common.staticConfigs.objectIds
local tooltipData = {
    { id = objectIds.firewood, description = "Fuel used at a campfire." },
    { id = objectIds.bedroll, description = "A portable bedroll for sleeping out in the wilderness. Provides decent warmth but it won't shelter you from the rain."},
    { id = objectIds.bedroll_ashl, description = "A portable bedroll for sleeping out in the wilderness. Provides decent warmth but it won't shelter you from the rain."},
    { id = objectIds.canvasTent, description = "A canvas tent with red patterned tarpoline."},
    { id = objectIds.ashlanderTent, description = "A leather tent styled after the Ashlander tribes, complete with windchimes."},
    { id = objectIds.coveredBedroll, description = "A portable bedroll with a rain cover. This will keep you warm and shelter you from the rain when sleeping outdoors."},
    { id = objectIds.woodaxe, description = "An axe made for chopping wood. The hefty axehead is highly durable and can harvest firewood much faster than an axe made for combat." },

    --kettles
    { id = "ashfall_kettle", description = "A large and heavy iron kettle. Use at a campfire to brew tea." },
    { id = "ashfall_kettle_01", description = "A large steel kettle. Use at a campfire to brew tea." },
    { id = "ashfall_kettle_02", description = "A small, beautiful ceramic kettle. Use at a campfire to brew tea." },
    { id = "ashfall_kettle_03", description = "A blue kettle with Ashlander markings. Use at a campfire to brew tea." },
    { id = "ashfall_kettle_04", description = "A red kettle with Ashlander markings. Use at a campfire to brew tea." },
    { id = "ashfall_kettle_05", description = "A rare kettle of unknown make and origin. Use at a campfire to brew tea." },
    { id = "ashfall_kettle_06", description = "A small kettle of simple construction. Use at a campfire to brew tea." },

    --grills
    { id = "ashfall_grill", description = "A cheap but heavy iron grill. Use at a campfire to cook meat and vegetables." },
    { id = "ashfall_grill_steel", description = "A light steel grill. Use at a campfire to cook meat and vegetables." },
    { id = "ashfall_fry_pan", description = "A small iron frying pan. Use at a campfire to cook meat and vegetables." },

    --cooking pots
    { id = "ashfall_cooking_pot", description = "This cooking pot is made of heavy copper. Use at a campfire to boil water and cook stews." },
    { id = "ashfall_cooking_pot_steel", description = "This cooking pot is made of a lightweight steel. Use at a campfire to boil water and cook stews." },
    { id = "ashfall_cooking_pot_iron", description = "A large iron cooking pot. Use at a campfire to boil water and cook stews." },


    --backpacks
    { id = objectIds.pack_b, description = "A brown fur backpack of Nordic design." },
    { id = objectIds.pack_w, description = "A white fur backpack of Nordic design." },
    { id = objectIds.pack_n, description = "A backpack made of netch leather." },

    --crab pot
    { id = "ashfall_crabpot_01_m", description = "Place underwater and wait to catch crabs and harvest their meat. Catch crabs faster by placing it deep underwater, in an area populated by mudcrabs."}

}

for _, data in ipairs(tooltipData) do
    if tooltipsComplete then
        if tes3.getObject(data.id) then
            tooltipsComplete.addTooltip(data.id, data.description, data.itemType)
        end
    end
end