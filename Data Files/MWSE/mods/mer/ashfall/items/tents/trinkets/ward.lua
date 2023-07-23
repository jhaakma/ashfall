--[[
    When in the vicinity of a ward, nearby enemies will flee
]]
local common = require("mer.ashfall.common.common")
local logger = common.createLogger("ward")

local fleeIncrease = 50

local function doWardEffect(e)
    if not (common.data.creatureWard or common.data.npcWard) then return end
    for _, cell in pairs(tes3.getActiveCells()) do
        for reference in cell:iterateReferences{tes3.objectType.npc, tes3.objectType.creature} do
            local mobile = reference.mobile
            if mobile and mobile.fight > 80 then
                local previousFlee = reference.data.ashfallWardedPrevFlee

                local refType = reference.object.objectType
                local isWarded = common.data.creatureWard and refType == tes3.objectType.creature
                    or common.data.npcWard and refType == tes3.objectType.npc

                if isWarded then
                    local closeEnough = reference.position:distance(tes3.player.position) < 1000
                    if closeEnough and not previousFlee then
                        reference.data.ashfallWardedPrevFlee = mobile.flee
                        mobile.flee = math.min(100, mobile.flee + fleeIncrease)
                        logger:debug("Making %s flee", reference.object.id)
                    end

                    if previousFlee and not closeEnough then
                        mobile.flee = previousFlee
                        reference.data.ashfallWardedPrevFlee = nil
                        logger:debug("%s no longer fleeing: not close enough", reference.object.id)
                    end
                elseif previousFlee then
                    mobile.flee = previousFlee
                    reference.data.ashfallWardedPrevFlee = nil
                    logger:debug("%s no longer fleeing: no ward effect", reference.object.id)
                end
            end
        end
    end
end
event.register("simulate", doWardEffect)


event.register("Ashfall:ActivateWard", function(e)
    if e.refType == tes3.objectType.npc then
        common.data.npcWard = true
    elseif e.refType == tes3.objectType.creature then
        common.data.creatureWard = true
    end
end)

event.register("Ashfall:DeactivateWard", function(e)
    if e.refType == tes3.objectType.npc then
        common.data.npcWard = nil
    elseif e.refType == tes3.objectType.creature then
        common.data.creatureWard = nil
    end
end)