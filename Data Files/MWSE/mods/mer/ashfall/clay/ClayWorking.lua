local common = require("mer.ashfall.common.common")
local config = require("mer.ashfall.config").config
local logger = common.createLogger("ClayTemper")
local RawClay = require("mer.ashfall.clay.RawClay")
local PotteryRecipe = require("mer.ashfall.clay.PotteryRecipe")
local CraftingFramework = require("CraftingFramework")
local UnfiredPottery = require("mer.ashfall.clay.UnfiredPottery")
local Temper = require("mer.ashfall.clay.Temper")

---@class Ashfall.Clay.TemperData
---@field id string The object ID of the ingredient used as temper
---@field name string The name of the temper
---@field description string The description of the temper


---Class for managing the clayworking menu
---triggered by equipping raw clay
---@class Ashfall.Clay.ClayWorking
local ClayWorking    = {
    ---@type table<string, boolean>
    animationActivatorIds = {}


}



function ClayWorking.getCraftMenuAnimationActivatorIds()
    return ClayWorking.animationActivatorIds
end


function ClayWorking.registerActivatorId(id)
    ClayWorking.animationActivatorIds[id:lower()] = true
    logger:debug("Registered clay working activator id: %s", id)
end




---On activate: Show message box with:
--- - Temper clay
--- - Work Clay
--- - Pick Up
--- - Cancel
---@param e activateEventData
function ClayWorking.onActivate(e)
    local clayRef = e.target
    if not ClayWorking.animationActivatorIds[clayRef.baseObject.id:lower()] then
        return
    end

    tes3ui.showMessageMenu{
        message = "Clay Working",
        buttons = {
            {
                text = "Temper Clay",
                callback = function()
                    ClayWorking.addTemper(clayRef)
                end
            },
            {
                text = "Work Clay",
                callback = function()
                    ClayWorking.openCraftMenu(clayRef)
                end
            },
            {
                text = "Pick Up",
                callback = function()
                    common.helper.pickUp(clayRef, true)
                end
            }
        },
        cancels = true
    }
end

function ClayWorking.initialise()
    logger:debug("Initialising ClayWorking menu activator")
    ---@type CraftingFramework.Recipe.data[]
    local recipes = {}

    ClayWorking.menuActivator = CraftingFramework.MenuActivator:new{
        id = "ashfall_clay_working_menu",
        type = "event",
        name = "Clay Working",
        recipes = recipes,
        doesTimePass = function()
            return config.craftingTakesTime
        end,
    }

    local craftingAnimationActivatorIds = ClayWorking.getCraftMenuAnimationActivatorIds()
    for id in pairs(craftinganimationActivatorIds) do
        CraftingFramework.Indicator.register{
            objectId = id,
            additionalUI = function(_, parent)
                parent:createLabel{ text = "Activate: Clay Working" }
            end
        }
    end

    event.register("activate", ClayWorking.onActivate)

    logger:debug("ClayWorking initialised with %d recipes", #recipes)
end

return ClayWorking