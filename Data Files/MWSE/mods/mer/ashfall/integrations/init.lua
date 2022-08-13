local common = require("mer.ashfall.common.common")
local logger = common.createLogger("Integrations")

local function isLuaFile(file) return file:sub(-4, -1) == ".lua" end
local function isInitFile(file) return file == "init.lua" end

for file in lfs.dir("Data Files/MWSE/mods/mer/ashfall/integrations/") do
    if isLuaFile(file) and not isInitFile(file) then
        logger:debug("Executing integrations file: %s", file)
        dofile("Data Files/MWSE/mods/mer/ashfall/integrations/" .. file)
    end
end