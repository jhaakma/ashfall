local common = require("mer.ashfall.common.common")
local logger = common.createLogger("Glow")
---Class for attaching and updating the glow material for pottery
---@class Ashfall.Clay.Glow
local Glow = {
    GLOW_MAT_MESH = "ashfall/anim/glow_mat.nif",
    --The id of the trishape owning the glow material controller  in the glow material mesh
    GLOW_PARENT_ID = "GLOW_MATERIAL",
    MAX_STRENGTH = 0.50,
}

---@return niKeyframeController|nil --actually a niMaterialColorController but we don't have a type for that
function Glow.getGlowController()
    logger:debug("Getting base glow material controller")
    local glowMatMesh = tes3.loadMesh(Glow.GLOW_MAT_MESH, false)
    if not glowMatMesh then
        logger:error("Could not load glow material mesh: %s", Glow.GLOW_MAT_MESH)
        return nil
    end
    return glowMatMesh:getObjectByName(Glow.GLOW_PARENT_ID).materialProperty:clone().controller:clone()
end


---Attach the glow material to the given pottery sceneNode
---@param potteryNode niNode
function Glow.attachToNode(potteryNode)
    logger:debug("Attaching glow material to pottery node")
    local glowController = Glow.getGlowController()
    if not glowController then
        logger:error("Could not get glow material controller")
        return
    end

    ---@param node niNode
    for node in table.traverse{ potteryNode } do
        if node:isInstanceOfType(tes3.niType.NiTriShape) then
            ---@cast node niTriShape
            node.materialProperty:prependController(glowController)
            glowController:setTarget(node.materialProperty)
            logger:debug("Attached glow material to node")
            node:update{ controllers = true, time = 0 }
        end
    end
end

---Set the glow strength on the given pottery sceneNode
function Glow.setStrength(sceneNode, strength)
    logger:debug("Setting glow strength to %.2f", strength)
    ---@param child niNode
    for child in table.traverse{ sceneNode } do
        if child:isInstanceOfType(tes3.niType.NiTriShape) then
            ---@cast child niTriShape
            local controller = child.materialProperty.controller
            if controller then
                local time = math.remap(strength, 0, 1, 0, Glow.MAX_STRENGTH)
                child:update{ controllers = true, time = time}
            end
        end
    end
end

return Glow