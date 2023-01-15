local common = require("mer.ashfall.common.common")
local logger = common.createLogger("DepdendencyController")
local dependencies = require("mer.ashfall.config.dependencies")

local function dependencyFailMessage(dependency, currentVersion)
    timer.delayOneFrame(function()
        local message = string.format("Ashfall requires %s to be installed.", dependency.name)
        if dependency.version then
            message = string.format("Ashfall requires %s %s to be installed.", dependency.name, dependency.version)
        end
        if currentVersion then
            message = string.format("Ashfall requires %s %s to be installed. Current version: %s", dependency.name, dependency.version, currentVersion)
        end
        tes3ui.showMessageMenu{
            message = message,
            buttons = {
                {
                    text = "Okay",
                    callback = function()
                        tes3ui.leaveMenuMode()
                    end,
                    showRequirements = function()
                        return dependency.url == nil
                    end
                },
                {
                    text = string.format("Download %s", dependency.name),
                    callback = function()
                        os.execute("start " .. dependency.url)
                        os.exit()
                    end,
                    showRequirements = function()
                        return dependency.url ~= nil
                    end
                },
                {
                    text = "Cancel",
                    callback = function()
                        tes3ui.leaveMenuMode()
                    end,
                    showRequirements = function()
                        return dependency.url ~= nil
                    end
                }
            }
        }
    end)
end

local operators = {
    [">"] = {
        major = function(major, targetMajor) return major >= targetMajor end,
        minor = function(minor, targetMinor) return minor >= targetMinor end,
        patch = function(patch, targetPatch) return patch > targetPatch end
    },
    [">="] = {
        major = function(major, targetMajor) return major >= targetMajor end,
        minor = function(minor, targetMinor) return minor >= targetMinor end,
        patch = function(patch, targetPatch) return patch >= targetPatch end
    },
    ["="] = {
        major = function(major, targetMajor) return major == targetMajor end,
        minor = function(minor, targetMinor) return minor == targetMinor end,
        patch = function(patch, targetPatch) return patch == targetPatch end
    }
}

local function onLoaded()
    for _, dependency in ipairs(dependencies) do
        logger:debug("Checking dependency: %s", dependency.name)
        if dependency.luaFile then
            if include(dependency.luaFile) == nil then
                logger:error("Could not find dependency file: %s", dependency.luaFile)
                return dependencyFailMessage(dependency)
            end
        elseif dependency.versionFile then
            local path = string.format("Data Files/MWSE/mods/%s", dependency.versionFile)
            local versionFile = io.open(path, "r")
            if not versionFile then
                logger:error("Could not find dependency version file: %s", path)
                return dependencyFailMessage(dependency)
            else
                local version = ""
                for line in versionFile:lines() do -- Loops over all the lines in an open text file
                    version = line
                end
                if version == "" then
                    logger:error("Could not find version in dependency version file: %s", path)
                    return
                end

                local major, minor, patch = string.match(version, "(%d+)%.(%d+)%.(%d+)")
                logger:debug("Found version: Major: %s, Minor: %s, Patch: %s", major, minor, patch)
                local targetMajor, targetMinor, targetPatch = string.match(dependency.version, "(%d+)%.(%d+)%.(%d+)")

                local operator
                --find one of possible operators at start of string
                for operatorPattern, _ in pairs(operators) do
                    if string.startswith(dependency.version, operatorPattern) then
                        operator = operatorPattern
                        break
                    end
                end
                if not operator then
                    logger:error("Could not find operator in version string: %s", dependency.version)
                    return
                end

                logger:debug("Operator: %s, Target: Major: %s, Minor: %s, Patch: %s", operator, targetMajor, targetMinor, targetPatch)

                local majorCheck = operators[operator].major(tonumber(major), tonumber(targetMajor))
                local minorCheck = operators[operator].minor(tonumber(minor), tonumber(targetMinor))
                local patchCheck = operators[operator].patch(tonumber(patch), tonumber(targetPatch))
                if not majorCheck or not minorCheck or not patchCheck then
                    logger:error("Dependency version check failed")
                    return dependencyFailMessage(dependency, version)
                end
            end
        end
    end
    logger:debug("All dependencies met")
end

event.register("loaded", onLoaded)