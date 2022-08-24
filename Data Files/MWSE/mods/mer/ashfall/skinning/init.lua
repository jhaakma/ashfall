local skinningConfig = require("mer.ashfall.skinning.config")
local common = require("mer.ashfall.common.common")
local logger = common.createLogger("skinningController")

--When a creature dies, remove all ingredients from its inventory


--When attacked with a knife, harvest ingredients from leveled inventory
---@param e attackHitEventData
local function skinOnAttack(e)
end
event.register("attackHit", skinOnAttack)