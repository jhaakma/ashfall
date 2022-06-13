
local https = require "ssl.https"
local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config").config

local this = {}

function this.getVersion()
    local versionFile = io.open("Data Files/MWSE/mods/mer/ashfall/version.txt", "r")
    if not versionFile then return end
    local version = ""
    for line in versionFile:lines() do -- Loops over all the lines in an open text file
        version = line
    end
    return version
end

local currentVersion, latestVersion
local showConfirmUpdate
local showConfirmDisableNotifications
local function showUpdateMessageBox()
    local msg = string.format('A new version of Ashfall is now available!')
    ---@type AshfallMessageBoxButton[]
    local buttons = {
        {
            text = string.format('Download Ashfall %s', latestVersion),
            callback = showConfirmUpdate
        }, {
            text = "Disable Update Notifications",
            callback = showConfirmDisableNotifications
        }
    }

    tes3ui.showMessageMenu {
        message = msg,
        buttons = buttons,
        cancels = true
    }
end

showConfirmUpdate = function()
    ---@type AshfallMessageBoxButton[]
    local buttons = {
        {
            text = tes3.findGMST(tes3.gmst.sYes).value,
            callback = function()
                os.execute(
                    "start https://github.com/jhaakma/ashfall/releases/latest/download/Ashfall.7z")
                os.execute(
                    "start https://github.com/jhaakma/ashfall/releases/latest")
                os.exit()
            end
        }
    }
    tes3ui.showMessageMenu {
        message = "Exit Morrowind and download latest Ashfall?",
        buttons = buttons,
        cancels = true,
        cancelCallback = showUpdateMessageBox
    }
end

showConfirmDisableNotifications = function()
    local message = "Disable update notifications?"
    ---@type AshfallMessageBoxButton[]
    local buttons = {
        {
            text = tes3.findGMST(tes3.gmst.sYes).value,
            callback = function()
                config.checkForUpdates = false
                config.save()
                tes3ui.showMessageMenu{
                    message = "Update notifications disabled. You can enable them again in the Development Options in the MCM.",
                    buttons = {
                        { text = tes3.findGMST(tes3.gmst.sOK).value}
                    }
                }
            end
        }
    }
    tes3ui.showMessageMenu{ message = message, buttons = buttons, cancels = true, cancelCallback = showUpdateMessageBox }
end

function this.checkForUpdates()
    if config.checkForUpdates then
        currentVersion = this.getVersion()
        local body, code, headers, status = https.request(
            'http://api.github.com/repos/jhaakma/ashfall/tags')

        if code == 200 then
            local body = json.decode(body)
            latestVersion = body and body[1] and body[1].name
            if latestVersion ~= currentVersion then
                timer.frame.delayOneFrame(function()
                    showUpdateMessageBox()
                end)
            end
        end
    end
end

return this