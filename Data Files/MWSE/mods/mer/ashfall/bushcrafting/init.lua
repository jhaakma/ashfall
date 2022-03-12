local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("registerCrafting")
local CraftingFramework = include("CraftingFramework")
if not CraftingFramework then
    logger:error("CraftingFramework not found")
end
local config = require("mer.ashfall.config.config").config
local craftingConfig = require("mer.ashfall.bushcrafting.config")


do -- initialise crafting
    for _, menuActivator in ipairs(craftingConfig.menuActivators) do
        logger:debug("Registering Menu Activator: %s", menuActivator)
        CraftingFramework.MenuActivator:new(menuActivator)
    end
    for _, material in ipairs(craftingConfig.materials) do
        logger:debug("Registering Material: %s", material.name)
        CraftingFramework.Material:new(material)
    end
    event.trigger("Ashfall:Bushcrafting_Initialized")
end

local function isMaterial(item)
    return craftingConfig.ingredMaterials[item.id:lower()]
end


local function onActivateMaterial(e)
    if not config.enableBushcrafting then
        return
    end
    --must be in menu
    if not tes3.menuMode() then return end
    if isMaterial(e.item) then
        logger:debug("Equipped material, triggering menu")
        event.trigger(craftingConfig.menuEvent)
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
