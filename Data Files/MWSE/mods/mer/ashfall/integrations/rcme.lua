
local rcmeButtons = {
    {
        menu = "Ashfall:DecorationMenu",
        button =  "Ashfall:DecorationMenuCancelButton"
    },
    {
        menu = "Ashfall:ShapingMenu",
        button = "Ashfall:ShapingMenuCancelButton"
    },
}
event.register(tes3.event.initialized, function()
    local RightClickMenuExit = include("mer.RightClickMenuExit")
    if RightClickMenuExit and RightClickMenuExit.registerMenu then
        for _, data in ipairs(rcmeButtons) do
            RightClickMenuExit.registerMenu{
                menuId = data.menu,
                buttonId = data.button
            }
        end
    end
end)