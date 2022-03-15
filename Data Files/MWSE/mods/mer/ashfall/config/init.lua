

local this = {}
this.configPath = "ashfall"
this.defaultConfig = require ("mer.ashfall.MCM.defaultConfig")
local inMemConfig = mwse.loadConfig(this.configPath, this.defaultConfig)

this.config = setmetatable({
    save = function()
        mwse.saveConfig(this.configPath, inMemConfig)
    end
}, {
    __index = function(_, key)
        return inMemConfig[key]
    end,
    __newindex = function(_, key, value)
        inMemConfig[key] = value
    end,
})

return this