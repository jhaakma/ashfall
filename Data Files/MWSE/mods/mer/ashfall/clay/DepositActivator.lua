local common = require("mer.ashfall.common.common")
local logger = common.createLogger("DepositActivator")
local ClayDeposit = require("mer.ashfall.clay.ClayDeposit")

---Class for handling interactions with clay deposits
---@class Ashfall.DepositActivator
local DepositActivator = {

}

--- Play digging sound effect
local function playDiggingSound()
    local diggingSound = "corpDRAG"
    tes3.playSound{ reference = tes3.player, sound = diggingSound }
    timer.start({
        type = timer.real,
        duration = 0.8,
        iterations = 2,
        callback = function()
            tes3.playSound{ reference = tes3.player, sound = diggingSound }
        end
    })
end

function DepositActivator.onActivate(e)
    if ClayDeposit.isClayDeposit(e.target) then
        logger:info("Player activated clay deposit: %s", e.target.id)
        tes3ui.showMessageMenu{
            message = "A deposit of raw clay.",
            buttons = {
                {
                    text = "Harvest Clay",
                    callback = function()
                        DepositActivator.harvestClay(e.target)
                    end
                }
            },
            cancels = true
        }

    end
end

function DepositActivator.harvestClay(depositRef)
    playDiggingSound()
    --disable halfway through
    timer.start({
        type = timer.real,
        duration = ClayDeposit.harvestRealSeconds * 0.5,
        callback = function()
            depositRef:disable()
        end
    })
    common.helper.fadeTimeOut(ClayDeposit.harvestHours,
        ClayDeposit.harvestRealSeconds,
        function()
            depositRef.data.ashfallClayDepositHarvestTime = tes3.getSimulationTimestamp()
            tes3.addItem{
                reference = tes3.player,
                item = ClayDeposit.pickRandomClayMiscId(),
                count = math.random(ClayDeposit.minClayPerHarvest, ClayDeposit.maxClayPerHarvest),
                showMessage = true,
            }
        end
    )
end

return DepositActivator