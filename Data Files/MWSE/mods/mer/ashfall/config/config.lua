local this = {}
local configPath = "ashfall"
local inMemConfig
this.defaultValues = require ("mer.ashfall.MCM.defaultConfig")
function this.getConfig()
    inMemConfig = inMemConfig or mwse.loadConfig(configPath, this.defaultValues)
    return inMemConfig
end
function this.saveConfig(newConfig)
    inMemConfig = newConfig
    mwse.saveConfig(configPath, newConfig)
end

function this.saveConfigValue(key, val)
    local config = this.getConfig()
    if config then
        config[key] = val
        mwse.saveConfig(configPath, config)
    end
end


--Returns if an object is blocked by the MCM
function this.getIsBlocked(obj)
    local config = this.getConfig()
    local mod = obj.sourceMod and obj.sourceMod:lower()
    return (
        config.blocked[obj.id] or
        config.blocked[mod]
    )
end

return this