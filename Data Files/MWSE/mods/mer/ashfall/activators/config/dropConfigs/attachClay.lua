local common = require("mer.ashfall.common.common")
local PotteryWheel = require("mer.ashfall.clay.PotteryWheel")
local RawClay = require("mer.ashfall.clay.RawClay")
local Temper = require("mer.ashfall.clay.Temper")
return {
    dropText = function()
        return "Add Clay"
    end,
    canDrop = function(reference, item, itemData)
        if item.id:lower() ~= RawClay.rawClayId then
            return false
        end
        local potteryWheel = PotteryWheel:new(reference)
        if not potteryWheel then return false end
        return potteryWheel:canAddClay()
    end,
    onDrop = function(wheelRef, clayRef)
        local potteryWheel = PotteryWheel:new(wheelRef)
        if not potteryWheel then return end

        potteryWheel:addClay(1)

        local tempered = Temper:new{ reference = clayRef }
        potteryWheel.data.isClayTempered = tempered and tempered:hasTemper() or false

        local stackCount = common.helper.getStackCount(clayRef)
        if stackCount == 1 then
            clayRef:delete()
        else
            clayRef.attachments.variables.count = clayRef.attachments.variables.count - 1
            common.helper.pickUp(clayRef)
        end
    end
}