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
    -- Initialize clay amount if not set (for old deposits)
    ClayDeposit.initialiseClayAmount(depositRef)

    local remainingClay = depositRef.data.ashfallClayRemaining
    local harvestAmount = math.random(ClayDeposit.minClayPerHarvest, ClayDeposit.maxClayPerHarvest) + (remainingClay * 0.1)
    harvestAmount = math.min(harvestAmount, remainingClay)

    playDiggingSound()

    common.helper.fadeTimeOut(ClayDeposit.harvestHours,
        ClayDeposit.harvestRealSeconds,
        function()
            depositRef.data.ashfallClayRemaining = depositRef.data.ashfallClayRemaining - harvestAmount

            tes3.addItem{
                reference = tes3.player,
                item = ClayDeposit.pickRandomClayMiscId(),
                count = harvestAmount,
                showMessage = true,
            }

            -- Only disable and mark harvest time if deposit is depleted
            if depositRef.data.ashfallClayRemaining <= 0 then
                logger:info("Clay deposit depleted, disabling")
                depositRef.data.ashfallClayDepositHarvestTime = tes3.getSimulationTimestamp()
                depositRef:disable()
            else
                logger:info("Clay deposit has %d clay remaining", depositRef.data.ashfallClayRemaining)
            end
        end
    )
end

local tooltipStates = {
    { minAmount = ClayDeposit.initialClayAmountMax * 0.8, text = "Abundant" },
    { minAmount = ClayDeposit.initialClayAmountMax * 0.5, text = "Plentiful" },
    { minAmount = ClayDeposit.initialClayAmountMax * 0.2, text = "Scarce" },
    { minAmount = 0, text = "Depleted" },
}
---@param e uiObjectTooltipEventData
function DepositActivator.uiObjectTooltip(e)

    if e.reference and ClayDeposit.isClayDeposit(e.reference) then
        ClayDeposit.initialiseClayAmount(e.reference)
        local remaining = e.reference.data.ashfallClayRemaining or 0
        for _, state in ipairs(tooltipStates) do
            if remaining >= state.minAmount then
                local label = e.tooltip:createLabel{ text = state.text }
                label.color = {0.8, 0.7, 0.2}
                break
            end
        end
    end
end
return DepositActivator