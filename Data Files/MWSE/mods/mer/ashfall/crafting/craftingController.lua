local craftingConfig = require("mer.ashfall.crafting.craftingConfig")
local craftingMenu = require("mer.ashfall.crafting.craftingMenu")
local common = require ("mer.ashfall.common.common")
local config = require("mer.ashfall.config").config

local function isMaterial(item)
    return craftingConfig.ingredMaterials[item.id:lower()]
end

local function onActivateMaterial(e)
    if not config.enableBushcrafting then return end
    --must be in menu
    if not tes3.menuMode() then return end
    if isMaterial(e.item) then
        craftingMenu.openMenu(craftingConfig.recipes)
        return true
    end
end
event.register("equip", onActivateMaterial, { filter = tes3.player, priority = -50 } )



local function createMaterialsTooltip(e)
    if not config.enableBushcrafting then return end

    if not e.tooltip then
        return
    end
    if not e.object then
        return
    end

    if isMaterial(e.object) then
        common.helper.addLabelToTooltip(e.tooltip, "Crafting Material", {175/255, 129/255, 184/255})
    end
end

event.register('uiObjectTooltip', createMaterialsTooltip)