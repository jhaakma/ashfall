local common = require("mer.ashfall.common.common")
local logger = common.createLogger("DampVisuals")
---Class for attaching and updating the glow material for pottery
---@class Ashfall.Clay.DampVisuals
local DampVisuals = {
    DAMP_COLOR = 0.5
}

---Set the glow strength on the given pottery sceneNode
---@param sceneNode niNode
---@param dampness number normalised dampness value between 0 and 1
---@return boolean anyUpdated
function DampVisuals.update(sceneNode, dampness)
    logger:trace("Setting dampness visual strength to %.2f", dampness)
    local anyUpdated = false

    local newColor = niColor.new(
        math.lerp(1.0, DampVisuals.DAMP_COLOR, dampness),
        math.lerp(1.0, DampVisuals.DAMP_COLOR, dampness),
        math.lerp(1.0, DampVisuals.DAMP_COLOR, dampness)
    )

    logger:trace("New dampness color: R=%.2f G=%.2f B=%.2f", newColor.r, newColor.g, newColor.b)

    ---@param child niNode
    for child in table.traverse{ sceneNode } do
        if child:isInstanceOfType(tes3.niType.NiTriShape) then
            ---@cast child niTriShape
            if child.materialProperty then
                child.materialProperty = child.materialProperty:clone()
                child.materialProperty.diffuse = newColor
                child:updateProperties()
                anyUpdated = true
            end
        end
    end

    if not anyUpdated then
        logger:trace("No materials found to update dampness")
    end
    return anyUpdated
end

return DampVisuals