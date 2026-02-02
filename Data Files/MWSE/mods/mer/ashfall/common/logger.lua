local ansicolors = require("logging.colors")

---@alias AshfallLoggerLogLevel
---|  "TRACE"
---|  "DEBUG"
---|> "INFO" # The default log level
---|  "WARN"
---|  "ERROR"
---|  "NONE"

---@class AshfallLoggerInputData
---@field name string Name of the mod, also counts as unique id of the logger
---@field outputFile string? Optional. If set, logs will be sent to a file of this name
---@field logLevel AshfallLoggerLogLevel? Set the log level. Options are: TRACE, DEBUG, INFO, WARN, ERROR and NONE
---@field logToConsole boolean? Default: `false`. If set to `true`, all the logged messages will also be logged to console
---@field includeTimestamp boolean? Default: `false`. If set to `true`, all the logged messages will include a timestamp

--[[
	A logger class that can be registered by multiple mods.
	Each registered logger can set its own log level, and choose
	to write to mwse.log or a custom log file.

	Author: Merlord
]]
---@class AshfallLogger : AshfallLoggerInputData
---@field info fun(self: AshfallLogger, message: string, ...: any): nil
---@field debug fun(self: AshfallLogger, message: string, ...: any): nil
---@field trace fun(self: AshfallLogger, message: string, ...: any): nil
---@field warn fun(self: AshfallLogger, message: string, ...: any): nil
---@field error fun(self: AshfallLogger, message: string, ...: any): nil
local Logger = {}
local registeredLoggers = {}
local defaults = {
	logLevel = "INFO",
}

local logLevels = {
	TRACE = { level = 1, color = "bright white" },
	DEBUG = { level = 2, color = "bright green" },
	INFO = { level = 3, color = "white" },
	WARN = { level = 4, color = "bright yellow" },
	ERROR = { level = 5, color = "bright red" },
	NONE = { level = 6, color = "white" },
}

--- Check log level to determine if log should be written out
---@param logLevel AshfallLoggerLogLevel Log level to check against
function Logger:doLog(logLevel)
	local currentLogLevel = self.logLevel or defaults.logLevel
	return logLevels[currentLogLevel].level <= logLevels[logLevel].level
end

--- Creates a new instance of a logger.
---@param data AshfallLoggerInputData
---
--- `name`: string — Name of mod, also counts as unique id of logger
---
--- `outputFile`: string? *Optional*. If set, logs will be sent to a file of this name
---
--- `logLevel`: AshfallLoggerLogLevel? Set the log level. Options are: TRACE, DEBUG, INFO, WARN, ERROR and NONE
---
--- `logToConsole` boolean? Default: `false`. If set to `true`, all the messages will be logged to console
---
--- `includeTimestamp` boolean? Default: `false`. If set to `true`, all the messages will include a timestamp
---@return AshfallLogger
function Logger.new(data)
    if type(data.logLevel) == "number" then
        data.logLevel = "INFO"
    end

	local newLogger = table.copy(data) --[[@as AshfallLogger]]
	if not newLogger or type(newLogger) ~= "table" then
		error("[Logger] No Logger constructor table provided.")
	elseif type(newLogger) == "table" then
		assert(type(newLogger.name) == "string", "[Logger] No name provided.")
	end
	for k, v in pairs(defaults) do
		if newLogger[k] == nil then
			newLogger[k] = v
		end
	end

	setmetatable(newLogger, Logger)
	Logger.__index = Logger
	registeredLoggers[data.name] = newLogger
	newLogger:setOutputFile(data.outputFile)
	return newLogger
end

--- Get a registered logger by name
---@param name string Name of logger to get
---@return AshfallLogger|false logger
function Logger.getLogger(name)
	local logger = registeredLoggers[name]
	if logger then
		return logger
	else
		return false
	end
end

--- Set the log level for a logger
---@param newLogLevel AshfallLoggerLogLevel Log level to set. Available options are: TRACE, DEBUG, INFO, WARN, ERROR and NONE
function Logger:setLogLevel(newLogLevel)
	local errMsg = "[%s ERROR] Logger:setLogLevel() - Not a valid log level (valid log levels: TRACE, DEBUG, INFO, WARN, ERROR, NONE)"
	assert(logLevels[newLogLevel], string.format(errMsg, self.name))
	self.logLevel = newLogLevel
end

--- Sets the name of the file to be written to.
---@param outputFile string Name of file to write to
function Logger:setOutputFile(outputFile)
	if outputFile == nil or string.lower(outputFile) == "mwse.log" then
		self.outputFile = nil
	else
		local errMsg = "[%s ERROR] Logger:setOutputFile() - Not a valid outputFile (must be a string)"
		assert(type(outputFile) == "string", string.format(errMsg, self.name))
		self.outputFile = io.open(outputFile, "w")
	end
end

local function addColor(message, color)
	return ansicolors('%' .. string.format('{%s}%s', color, message))
end

--- Formats and colors the log message, and writes it to the configured log file. This is typically not called directly.
---@param logLevel AshfallLoggerLogLevel
---@param color string
---@param message string
---@param ...  any?
function Logger:write(logLevel, color, message, ...)
	local output = string.format("[%s: %s] %s", self.name, logLevel, tostring(message):format(...))
    if self.includeTimestamp then
        local socket = require("socket")
        local timestamp = socket.gettime()
        local milliseconds = math.floor((timestamp % 1) * 1000)
        timestamp = math.floor(timestamp)

        -- convert timestamp to a table containing time components
        local timeTable = os.date("*t", timestamp)

        -- format time components into H:M:S:MS string
        local formattedTime = string.format("%02d:%02d:%02d.%03d", timeTable.hour, timeTable.min, timeTable.sec, milliseconds)
        output = string.format("[%s] %s", formattedTime, output)
    end

	-- Add log colors if enabled
	if mwse.getConfig("EnableLogColors") then
		output = addColor(output, color)
	end

	if self.logToConsole then
		tes3ui.log(output)
	end

	-- Prints to custom file if defined
	if self.outputFile then
		self.outputFile:write(output .. "\n")
		self.outputFile:flush()
	else
		-- otherwise straight to mwse.log
		print(output)
	end
end

-- Generate log functions (:info, :debug etc) from logLevels table
for logLevel, levelConfig in pairs(logLevels) do
	Logger[string.lower(logLevel)] = function(self, message, ...)
		if type(self) == "string" then
			mwse.log(debug.traceback("ERROR: Called logger method with a . instead of a :"))
			return
		end
		if self:doLog(logLevel) then
			self:write(logLevel, levelConfig.color, message, ...)
		end
	end
end

--- Assert a condition and log an error if it fails
---@param condition boolean Condition to assert
---@param message string Message to log if condition fails
---@param ... any?
function Logger:assert(condition, message, ...)
	if not condition then
		message = tostring(message):format(...)
		self:error(message)
		assert(condition, message)
	end
end

return Logger