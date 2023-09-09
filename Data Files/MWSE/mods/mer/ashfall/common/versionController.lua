
local https = require "ssl.https"
local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config").config

local this = {}

function this.getVersion()
    local metadata = toml.loadMetadata("Ashfall") --[[@as MWSE.Metadata]]
    return metadata.package.version
end

local currentVersion, latestVersion
local showConfirmUpdate
local showConfirmDisableNotifications
local function showUpdateMessageBox()
    local msg = string.format('A new version of Ashfall is now available!')
    ---@type tes3ui.showMessageMenu.params.button[]
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
    ---@type tes3ui.showMessageMenu.params.button[]
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
    ---@type tes3ui.showMessageMenu.params.button[]
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
        currentVersion = "v" .. this.getVersion()
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