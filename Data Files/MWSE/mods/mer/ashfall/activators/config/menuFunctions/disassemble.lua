local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("DisassembleMenuFunction")
local Campfire = require("mer.ashfall.camping.campfire.Campfire")
local CraftingFramework = require("CraftingFramework")

--Destroy and recover all materials from placed craftable
return {
    text = "Disassemble",
    ---@param reference tes3reference
    showRequirements = function(reference)
        return Campfire.canDisassemble(reference)
            and reference.supportsLuaData
            and not reference.data.isLit
    end,
    ---@param reference tes3reference
    callback = function(reference)
        logger:debug("Disassembling reference: %s", reference.id)
        local craftable = CraftingFramework.Craftable.getPlacedCraftable(reference.baseObject.id)
        craftable.materialRecovery = 100
        craftable:destroy(reference)
    end
}