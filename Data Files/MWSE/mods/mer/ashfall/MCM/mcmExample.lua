

--[[local function registerModConfig()
    EasyMCM = require("easyMCM.EasyMCM")
    local template = EasyMCM.createTemplate{ name = "Basic MCM" }
    local page = template:createPage()
    local category = page:createCategory{ label = "Settings" }
    category:createButton{ label = "A Button", buttonText = "Press" }
    category:createButton{ label = "Another Button", buttonText = "Press" }
    EasyMCM.register(template)
end
event.register("modConfigReady", registerModConfig)]]--



--Get our config file
local confPath = "config_test"
local config = mwse.loadConfig(confPath)
if not config then 
    config = { blocked = {} }
end

local function registerModConfig()
    --get EasyMCM
    local EasyMCM = require("easyMCM.EasyMCM")
    --create template
    local template = EasyMCM.createTemplate("Advanced MCM")
    --Have our config file save when MCM is closed
    template:saveOnClose(confPath, config)
    --Make a page
    local page = template:createSideBarPage{
        description = "This text is shown on the sidebar"
    }
    --Make a category inside our page
    local category = page:createCategory("Settings")

    --Make some settings
    category:createButton({ 
        buttonText = "Hello", 
        description = "A useless button",
        callback = function(self)
            tes3.messageBox("Button pressed!")
        end
    })

    category:createSlider{
        label = "Time Scale",
        description = "Changes the speed of the day/night cycle.",
        variable = EasyMCM:createGlobal{ id = "timeScale" }
    }

    --Make an exclusions page
    local exclusionsPage = template:createExclusionsPage{
        label = "Exclusions",
        description = (
            "Use an exclusions page to add items to a blacklist"
        ),
        variable = EasyMCM:createTableVariable{
            id = "blocked",
            table = config,
        },
        filters = {
            {
                label = "Plugins",
                type = "Plugin",
            },
            {
                label = "Food",
                type = "Object",
                objectType = tes3.objectType.ingredient,
            }
        }
    }

    --Register our MCM
    EasyMCM.register(template)
end



--register our mod when mcm is ready for it
event.register("modConfigReady", registerModConfig)