--[[
    A logger class that can be registered by multiple mods. 
    Each registered logger can set its own log level, and choose 
    to write to mwse.log or a custom log file.

    Author: Merlord
]]

local Logger = {}
local registeredLoggers = {}
local defaultLogLevel = "INFO"
local logLevels = {
    TRACE = 1,
    DEBUG = 2,
    INFO = 3,
    WARN = 4,
    ERROR = 5,
    NONE = 6
}
Logger.logLevel = {
    TRACE = "TRACE",
    DEBUG = "DEBUG",
    INFO = "INFO",
    WARN = "WARN",
    ERROR = "ERROR",
    NONE ="NONE",
}
--Check log level to determine if log should be written out
function Logger:doLog(logLevel)
    local currentLogLevel = self.logLevel or defaultLogLevel
    return logLevels[currentLogLevel] <= logLevels[logLevel]
end

--[[
    Creates a new logger. Can pass just a name or a table of options:
    @string name: 
        Name of mod, also counts as unique id of logger
    @string outputFile: 
        Optional. If set, logs will be sent to a file of this name 
        instead of mwse.log
    @string logLevel: 
        Optional. Set the log level. Options are: TRACE, DEBUG, INFO, WARN and ERROR. 
        Defaults to INFO.
]]
function Logger.new(nameOrData)
    local data
    if not nameOrData then
        error("[Logger] No string or table provided.")
    elseif type(nameOrData) == "string" then
        data = { name = nameOrData }
    elseif type(nameOrData) == "table" then
        assert(type(nameOrData.name) == "string", "[Logger] No name provided." )
        data = nameOrData
    else
        error("[Logger] must provide mod name.")
    end

    data.logLevel = data.logLevel or defaultLogLevel

    setmetatable(data, Logger)
    Logger.__index = Logger
    registeredLoggers[data.name] = data
    data:setOutputFile(data.outputFile)
    return data
end


function Logger.getLogger(name)
    local logger = registeredLoggers[name]
    if logger then 
        return logger
    else
        return false
    end
end

function Logger:setLogLevel(newLogLevel)
    local errMsg = "[%s ERROR] Logger:setLogLevel() - Not a valid log level (valid logs levels: TRACE, DEBUG, INFO, WARN, ERROR"
    assert( logLevels[newLogLevel], string.format(errMsg, self.name) )
    self.logLevel = newLogLevel
end

--[[
    Sets the name of the file to be written to. 
    @string outputFile
        MWSE.log or nil: reverts back to writing to MWSE.log
        Otherwise, creates a new file to start writing to
]]
function Logger:setOutputFile(outputFile)
    if outputFile == nil or string.lower(outputFile) == "mwse.log" then
        self.outputFile = nil
    else
        local errMsg = "[%s ERROR] Logger:setLogLevel() - Not a valid outputFile (must be a string)"
        assert( type(outputFile) == "string", string.format(errMsg, self.name) )

        self.outputFile = io.open(self.outputFile, "w")
    end
end

--[[
    Generic write method, used by specific log functions
    Formats the log message, and decides whether to write to 
    a file or to mwse.log.
]]
function Logger:write(logLevel, message, ...)
    local output = string.format("[%s: %s] %s", self.name, logLevel, tostring(message):format(...) )

    --Prints to custom file if defined
    if self.outputFile then
        self.outputFile:write(output .. "\n")
        self.outputFile:flush()
    else
        --otherwise straight to mwse.log
        print(output)
    end
end


--Setup log functions, logger:info, logger:error() etc
for logLevel, _ in pairs(logLevels) do
    Logger[string.lower(logLevel)] = function(self, message, ...)
        if self:doLog(logLevel) then
            self:write(logLevel, message, ...)
        end
    end
end


return Logger