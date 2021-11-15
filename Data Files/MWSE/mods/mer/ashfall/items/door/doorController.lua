---@param e referenceActivatedEventData
local function checkDoorStateOnActivated(e)
    if e.reference.data and e.reference.data.ashfallDoorIsOpen then
        tes3.playAnimation {
            reference = e.reference,
            group = tes3.animationGroup.idle2,
            startFlag = tes3.animationStartFlag.immediate,
            loopCount = 0,
        }
    end
end
event.register("referenceActivated", checkDoorStateOnActivated)