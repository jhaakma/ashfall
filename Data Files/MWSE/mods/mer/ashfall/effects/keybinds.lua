local common = require("mer.ashfall.common.common")

local function makeAxe()
    tes3.messageBox("Making Stone axe")
end

local function makeTent()
    tes3.messageBox("Making Tent")
end

local buttons = {
    { text = "Make Stone Axe", callback = makeAxe },
    { text = "Craft Tent", callback =  makeTent},
    { text = "Cancel" }
}

local function craftingMenu()
    if tes3.player and not tes3.menuMode() then
        common.helper.messageBox({
            message = "Ashfall Crafting Menu",
            buttons = buttons
        })
    end
end

local actions = {
    craftingKey = craftingMenu
}

local function keyPressed(e)
    local config = mwse.loadConfig("ashfall")
    local doCrafting = (
        common.data and
        common.config.getConfig().enableCrafting
    )    
    if doCrafting then
        for var, callback in pairs(actions) do
            local correctCombo = (
                e.keyCode == config[var].keyCode and
                e.isShiftDown == config[var].isShiftDown and
                e.isAltDown == config[var].isAltDown and
                e.isControlDown == config[var].isControlDown
            )
            if correctCombo then
                callback()
            end
        end
    end
end

event.register("keyDown", keyPressed)
