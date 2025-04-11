local common = require("mer.ashfall.common.common")

local shader

---@return mgeShaderHandle | { temperature: number }
local function getShader()
    shader = mgeShadersConfig.load{ name = "ashfall"}
    return shader
end

event.register("load", function()
    local shader = getShader()
    shader.enabled = true
end)

event.register("Ashfall:UpdateHUD", function()
    local shader = getShader()
    shader.temperature = common.data.temp
end)