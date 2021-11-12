local common = require("mer.ashfall.common.common")
local tentConfig = require("mer.ashfall.camping.tents.tentConfig")

event.trigger("Ashfall:RegisterReferenceController", {
    id = "trinket",
    requirements = function(_, ref)
        return ref.data and ref.data.trinket
    end
})


local function enableTrinketEffect(trinket)
        if common.data.trinketEffects[trinket.id] then return end
        if trinket.spell then
        local spellId = trinket.spell.id
        local spell = tes3.getObject(spellId)
        if not spell then
            spell = tes3spell.create(spellId, trinket.spell.name)
            spell.castType = tes3.spellType.ability
            for i=1, #trinket.spell.effects do
                local effect = spell.effects[i]
                local newEffect = trinket.spell.effects[i]

                effect.id = newEffect.id
                effect.attribute = newEffect.attribute
                effect.skill = newEffect.skill
                effect.rangeType = tes3.effectRange.self
                effect.min = newEffect.amount or 0
                effect.max = newEffect.amount or 0
                effect.radius = newEffect.radius
            end
        end
        mwscript.addSpell{ reference = tes3.player, spell = spell }
    end
    if trinket.onCallback then
        trinket.onCallback()
    end
    if trinket.message then
        tes3.messageBox(trinket.message)
    end
    common.data.trinketEffects[trinket.id] = true
    common.log:debug("Enabled trinket effect for %s", trinket.id)
end

local function disableTrinketEffect(trinket)
    if common.data.trinketEffects[trinket.id] == nil then return end
    if trinket.spell then
        common.helper.restoreFatigue()
        mwscript.removeSpell({ reference = tes3.player, spell = trinket.spell.id})
    elseif trinket.offCallback then
        trinket.offCallback()
    end
    common.data.trinketEffects[trinket.id] = nil
    common.log:debug("Disabled trinket effect for %s", trinket.id)
end
event.register("Ashfall:DisableTrinketEffect", disableTrinketEffect)

local function updateTrinketEffects(e)
    local function doUpdate(ref)
        local trinket = tentConfig.getTrinketData(ref.data.trinket)
        if not trinket then return end
        local distance = trinket.effectDistance or tentConfig.defaultTrinketDistance
        if ref.position:distance(tes3.player.position) < distance then
            enableTrinketEffect(trinket)
        else
            disableTrinketEffect(trinket)
        end
    end
    common.helper.iterateRefType("trinket", doUpdate)
end
event.register("simulate", updateTrinketEffects)

event.register("cellChanged", function()
    for _, trinket in pairs(tentConfig.trinkets) do
        disableTrinketEffect(trinket)
    end
end)

local function trinketTooltip(e)
    local trinket =  tentConfig.getTrinketData(e.object.id)
    if trinket then
        local block = e.tooltip:createBlock{}
        block.minWidth = 1
        block.maxWidth = 310
        block.autoWidth = true
        block.autoHeight = true
        block.paddingAllSides = 6
        local label= block:createLabel{ id = tes3ui.registerID("Tooltips_Complete_Keys"), text = trinket.description }
        label.wrapText = true
    end
end

event.register("uiObjectTooltip", trinketTooltip, { priority = -101})