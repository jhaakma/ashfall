local Debris = require("mer.ashfall.branch.Debris")

event.register("cellChanged", function(e)
    if e.cell.isInterior then return end
    local cameFromInterior = e.previousCell and e.previousCell.isInterior
    Debris:enterCell{
        immediate = cameFromInterior,
    }
end)

event.register("Ashfall:dataLoaded", function(e)
    if tes3.player.cell.isInterior then return end
    Debris:enterCell{
        immediate = true,
    }
end)

local function onActivate(e)
    if not (e.activator == tes3.player) then return end
    if string.startswith(e.target.object.id:lower(), "ashfall_branch_") then
        e.target.data.lastPickedUp = tes3.getSimulationTimestamp()
        e.target:disable()

        tes3.addItem{
            reference = tes3.player,
            item = "ashfall_firewood",
            playSound = true,
        }
        tes3.messageBox("Collected 1 firewood.")
        return false
    end
end

event.register("activate", onActivate)
