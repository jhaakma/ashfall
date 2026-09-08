local common = require("mer.ashfall.common.common")
local logger = common.createLogger("GlowVisuals")
---Class for attaching and updating the glow material for pottery
---@class Ashfall.Clay.GlowVisuals
local GlowVisuals = {
    MAX_STRENGTH = 0.50,
}

---Set the glow strength on the given pottery sceneNode
---@param sceneNode niNode
---@param strength number
---@return boolean anyUpdated
function GlowVisuals.update(sceneNode, strength)
    logger:trace("Setting glow strength to %.2f", strength)
    local anyUpdated = false

    local redAmount = math.remap(strength, 0, 1, 0, GlowVisuals.MAX_STRENGTH)
    ---@param child niNode
    for child in table.traverse{ sceneNode } do
        if child:isInstanceOfType(tes3.niType.NiTriShape) then
            ---@cast child niTriShape
            if child.materialProperty then
                child.materialProperty = child.materialProperty:clone()
                child.materialProperty.emissive = niColor.new(redAmount, 0, 0)
                child:updateProperties()
                anyUpdated = true
            end
        end
    end

    if not anyUpdated then
        logger:trace("No material controllers found to update glow")
    end
    return anyUpdated
end

return GlowVisuals