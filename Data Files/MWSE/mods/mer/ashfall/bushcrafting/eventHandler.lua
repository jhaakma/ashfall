local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("Material Controller")
local CraftingFramework = include("CraftingFramework")
if not CraftingFramework then
    logger:error("CraftingFramework not found")
end
local config = require("mer.ashfall.config").config
local craftingConfig = require("mer.ashfall.bushcrafting.config")


local function isBushcraftingMaterial(item)
    for _, conf in ipairs(craftingConfig.materials) do
        local material = CraftingFramework.Material.getMaterial(conf.id)
        if material then
            if material:itemIsMaterial(item.id) then
                return true
            end
        end
    end
    return false
end

---@param e equipEventData
local function onActivateMaterial(e)
    if e.reference ~= tes3.player then return end
    if not config.bushcraftingEnabled then
        return
    end
    --must be in menu
    if not tes3.menuMode() then return end
    if isBushcraftingMaterial(e.item) then
        logger:debug("Equipped material, triggering menu")
        event.trigger(craftingConfig.menuEvent)
        return true
    end
end
event.register("equip", onActivateMaterial, { priority = -50 } )

local function createMaterialsTooltip(e)
    if not config.bushcraftingEnabled then return end

    if not e.tooltip then
        return
    end
    if not e.object then
        return
    end

    if isBushcraftingMaterial(e.object) then
        common.helper.addLabelToTooltip(e.tooltip, "Bushcrafting Material", {175/255, 129/255, 184/255})
    end
end
event.register('uiObjectTooltip', createMaterialsTooltip)

--Chisel
---@param e equipEventData
local function onEquipChisel(e)
    if e.reference ~= tes3.player then return end
    --Check if equipped item is registered as a chisel Tool
    if not config.bushcraftingEnabled then
        return
    end
    if not tes3.menuMode() then return end
    local chisel = CraftingFramework.Tool.getTool("chisel")
    if chisel then
        if chisel:itemIsTool(e.item) then
            logger:debug("Equipped chisel, triggering menu")
            event.trigger(craftingConfig.carvingEvent)
            return true
        end
    end
end
event.register("equip", onEquipChisel, { priority = -50 } )

local function customNameTooltip(e)
    local name = e.itemData and e.itemData.data.customName
    if name then
        local label = e.tooltip:findChild(tes3ui.registerID('HelpMenu_name'))
        if label then
            label.text = name
        end
    end
end
event.register("uiObjectTooltip", customNameTooltip)

