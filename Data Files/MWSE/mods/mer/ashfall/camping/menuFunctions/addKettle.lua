local common = require ("mer.ashfall.common.common")

local function addKettle(kettle, campfire)
    mwscript.removeItem{ reference = tes3.player, item = kettle }
    campfire.data.utensil = "kettle"
    tes3.playSound{ reference = tes3.player, sound = "Item Misc Down"  }

    campfire.data.kettleId = kettle.id:lower()
    event.trigger("Ashfall:UpdateAttachNodes", {campfire = campfire})
    --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
end

local function kettleSelect(campfire)
    timer.delayOneFrame(function()
        tes3ui.showInventorySelectMenu{
            title = "Select Kettle",
            noResultsText = "You do not have a kettle.",
            filter = function(e)
                return common.staticConfigs.kettles[e.item.id:lower()] ~= nil
            end,
            callback = function(e)
                if e.item then
                    addKettle(e.item, campfire)
                end
            end
        }
    end)
end

return {
    text = "Attach Kettle",
    showRequirements = function(campfire)
        return (
            campfire.data.hasSupports and
            not campfire.data.utensil and
            campfire.data.dynamicConfig and
            campfire.data.dynamicConfig.kettle == "dynamic"
        )
    end,
    enableRequirements = function()

        for kettleId, _ in pairs(common.staticConfigs.kettles) do
            if  mwscript.getItemCount{ reference = tes3.player, item = kettleId} > 0 then
                return true
            end
        end
        return false
    end,
    tooltipDisabled = { 
        text = "Requires 1 Kettle."
    },
    callback = kettleSelect
}