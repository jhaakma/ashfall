local common = require ("mer.ashfall.common.common")

local tutorials = {
    grillFood = {
        event = "Ashfall:attachGrill",
        header = "Cooking Food",
        text = [[
To cook food, place raw food from your inventory directly onto the grill/frying pan.
Food is fully cooked when it turns brown. Leave it too long and it will become burnt. There is also a chance food will become burnt immediately if your survival skill is low.
]]
    },

}

local Tutorial = {
    event = nil,
    header = nil,
    text = nil,
    enable = function(self)

    end
}

local function tutorialsEnabled()
    return tes3.player and tes3.player.data.ashfall_tutorials_enabled
end

local function enableTutorials()
    if tes3.player then
        tes3.player.data.ashfall_tutorials_enabled = true
    end
end

local function disableTutorials()
    if tes3.player then
        tes3.player.data.ashfall_tutorials_enabled = false
    end
end

local function getFlagId(tutorialId)
    return string.format("ashfall_tutorial_%s_done", tutorialId)
end

local function doShowTutorial(tutorialId)
    if not tutorialsEnabled() then return false end
    local flagId = getFlagId(tutorialId)
    if tes3.player.data[flagId] then return false end
    return true
end

for id, data in pairs(tutorials) do
    assert(data.event, "Tutorial " .. id .. " has no event")
    assert(data.header, "Tutorial " .. id .. " has no header")
    assert(data.text, "Tutorial " .. id .. " has no text")

    event.register(data.event, function()
        if doShowTutorial(id) then
             tes3ui.showMessageMenu{
                header = data.header,
                text = data.text,
                buttons = {
                    {
                        text = tes3.findGMST(tes3.gmst.sOK).value,
                    },
                    {
                        text = "Disable Tutorials",
                        callback = function()
                            disableTutorials()
                        end
                    }
                }
            }
        end
    end)
end