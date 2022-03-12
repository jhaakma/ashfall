--TODO
local common = require ("mer.ashfall.common.common")


local function stopSound(sound, target, duration)
    local safeRef = tes3.makeSafeObjectHandle(target)
    timer.start{
        type = timer.real,
        duration = duration,
        callback = function()
            if not safeRef:valid() then return end
            tes3.removeSound{
                reference = safeRef:getObject(),
                sound = sound
            }
        end
    }
end

local salts = {
    ingred_frost_salts_01 = {
        text = "Create Cold Flame",
        callback = function(target)
            mwscript.explodeSpell{
                reference = target,
                spell = "ashfall_coldflame"
            }
            stopSound("frost_cast", target, 1.5)
            target.data.hasColdFlame = true
            local lightNode = target:getOrCreateAttachedDynamicLight()
            local light = lightNode and lightNode.light
            if light then
                light.diffuse = tes3vector3.new(
                    40/255,
                    40/255,
                    255/255
                )
                target.sceneNode:updateNodeEffects()
            end
        end
    },
    ingred_fire_salts_01 = {
        text = "Reverse Cold Flame",
        callback = function(target)
            mwscript.explodeSpell{
                reference = target,
                spell = "ashfall_hotflame"
            }
            stopSound("destruction cast", target, 1.5)
            target.data.hasColdFlame = false
            local lightNode = target:getOrCreateAttachedDynamicLight()
            local light = lightNode and lightNode.light
            if light then
                light.diffuse = tes3vector3.new(
                    255/255,
                    150/255,
                    40/255
                )
                target.sceneNode:updateNodeEffects()
            end
        end,
    }
}
return {
    dropText = function(campfire, item, data)
        local data = salts[item.id:lower()]
        return data.text
    end,
    canDrop = function(ref, item, itemData)
        local isSalt = salts[item.id:lower()]
        local isLit = ref.data.isLit
        return isSalt and isLit
    end,
    onDrop = function(target, reference)
        local data = salts[reference.object.id:lower()]
        if data then
            tes3ui.leaveMenuMode()
            timer.delayOneFrame(function()
                local remaining = common.helper.reduceReferenceStack(reference, 1)
                if remaining > 0 then
                    common.helper.pickUp(reference)
                end
                data.callback(target)
                event.trigger("Ashfall:UpdateAttachNodes", { campfire = target})
            end)
        end
    end
}