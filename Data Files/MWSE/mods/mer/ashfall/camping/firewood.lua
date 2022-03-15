
local CampfireUtil = require "mer.ashfall.camping.campfire.CampfireUtil"

local activatorController = require "mer.ashfall.activators.activatorController"
----------------------
--FIREWOOD
----------------------

local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("firewood")
local config = require("mer.ashfall.config").config
local skipActivate
local function pickupFirewood(ref)
    timer.delayOneFrame(function()
        skipActivate = true
        tes3.player:activate(ref)
        skipActivate = false
    end)
end




local function placeCampfire(e)
    --Check how steep the land is
    local maxSteepness = common.staticConfigs.placementConfig.ashfall_firewood.maxSteepness
    local ground = common.helper.getGroundBelowRef({ref = e.target})
    local tooSteep = (
        ground.normal.x > maxSteepness or
        ground.normal.x < -maxSteepness or
        ground.normal.y > maxSteepness or
        ground.normal.y < -maxSteepness
    )
    if tooSteep then
        tes3.messageBox{ message = "The ground is too steep here.", buttons = {tes3.findGMST(tes3.gmst.sOK).value}}
        return
    end

    mwscript.disable({ reference = e.target })

    local campfire = tes3.createReference{
        object = common.staticConfigs.objectIds.campfire,
        position = e.target.position,
        orientation = {
            e.target.orientation.x,
            e.target.orientation.y,
            tes3.player.orientation.z
        },
        scale = 0.8,
        cell = e.target.cell
    }
    tes3.playSound{ sound = "Item Misc Down" }
    campfire:deleteDynamicLightAttachment()

    local stackSize = e.target.stackSize or 1
    local max = 10
    local remaining = common.helper.reduceReferenceStack(e.target, math.min(stackSize, max))
    if remaining > 0 then
        local safeRef = tes3.makeSafeObjectHandle(e.target)
        timer.delayOneFrame(function()
            if safeRef:valid() then
                common.helper.pickUp(safeRef:getObject())
            end
        end)
    end
    campfire.data.fuelLevel = stackSize - remaining
    event.trigger("Ashfall:UpdateAttachNodes", { campfire = campfire})
end


---@param e activateEventData
local function onActivateFirewood(e)
    if not (e.activator == tes3.player) then return end
    if skipActivate then return end
    if tes3.menuMode() then return end
    if  string.lower(e.target.object.id) == common.staticConfigs.objectIds.firewood then
        if tes3.player.cell.restingIsIllegal then
            if common.helper.getInside() then
                return
            end
            if not config.canCampInSettlements then
                return
            end
        end
        if common.helper.getRefUnderwater(e.target) then
            return
        end

        local inputController = tes3.worldController.inputController
        local isModifierKeyPressed = common.helper.isModifierKeyPressed()

        if isModifierKeyPressed then
            return
        else
            common.helper.messageBox({
                message = string.format("You have %d %s.", e.target.stackSize, e.target.object.name),
                buttons = {
                    { text = "Create Campfire", callback = function() placeCampfire(e) end },
                    { text = "Pick Up", callback = function() pickupFirewood(e.target) end },
                },
                doesCancel = true
            })
            return true
        end
    end
end
event.register("activate", onActivateFirewood )



local function extinguishFire(campfire)
    event.trigger("Ashfall:fuelConsumer_Extinguish", {fuelConsumer = campfire, playSound = true})
end

---@param e magicCastedEventData
local function onMagicCasted(e)

    if e.caster == tes3.player then
        logger:debug("Player magic casted")
        local isFireTouch
        local isFrostTouch
        for _, effect in ipairs(e.source.effects) do
            if effect.rangeType == tes3.effectRange.touch then
                if effect.id == tes3.effect.fireDamage then
                    isFireTouch = true
                    break
                end
                if effect.id == tes3.effect.frostDamage then
                    isFrostTouch = true
                    break
                end
            end
        end
        if isFireTouch or isFrostTouch then
            logger:debug("%s", isFireTouch and "Cast fire" or "Cast frost")
            local campfire = activatorController.currentRef
            if campfire then
                logger:debug("Looking at campfire")
                local isLit = campfire.data.isLit
                local hasFuel = campfire.data.fuelLevel and campfire.data.fuelLevel > 0
                local doLight = hasFuel and isFireTouch and not isLit
                local doExtinguish = hasFuel and isFrostTouch and isLit
                local isEnchant = e.sourceInstance.itemData

                if isEnchant then --Is a ring, so mimic the fire effect
                    logger:debug("Is enchantment")
                    local hasCharge = e.sourceInstance.itemData.charge >= e.source.chargeCost
                    if hasCharge and (doLight or doExtinguish) then
                        logger:debug("hasCharge and can light/extinguish")
                        local spell = isFireTouch and "fire bite" or "frostbite"
                        logger:debug("Casting %s", spell)
                        mwscript.explodeSpell{ reference = campfire, spell = spell }
                        timer.start{
                            type = timer.simulate,
                            duration = 1,
                            callback = function()
                                if doLight then
                                    event.trigger("Ashfall:fuelConsumer_Alight", { fuelConsumer = campfire})
                                else
                                    extinguishFire(campfire)
                                end
                                --Exploding spell on a light object causes infinite sound loop, so manually stop the sound
                                mwscript.stopSound{ reference = campfire, sound = 'destruction cast'}
                            end
                        }

                    end
                else-- Is a spell, so no extra effects necessary
                    logger:debug("is spell")
                    if doLight then
                        logger:debug("Lighting fire")
                        event.trigger("Ashfall:fuelConsumer_Alight", { fuelConsumer = campfire})
                    elseif doExtinguish then
                        logger:debug("extinguishing fire")
                        extinguishFire(campfire)
                    end
                end
            end
        end
    end
end
event.register("magicCasted", onMagicCasted)


--TODO find a way to do this with ranged fire
---@param e projectileExpireEventData
local function onSpellHit(e)
    if e.mobile.reference and e.mobile.spellInstance then
        local isFireSpell
        local isFrostSpell
        for _, effect in ipairs(e.mobile.spellInstance.source.effects) do
            if effect.rangeType == tes3.effectRange.target then
                if effect.id == tes3.effect.fireDamage then
                    isFireSpell = true
                    break
                end
                if effect.id == tes3.effect.frostDamage then
                    isFrostSpell = true
                    break
                end
            end
        end
        if isFireSpell or isFrostSpell then
            logger:debug("on target %s spell expired", isFireSpell and "fire" or "frost")
            local spellRef = e.mobile.reference
            local result =  tes3.rayTest{
                position = {spellRef.position.x, spellRef.position.y, spellRef.position.z},
                direction = {0,0,-1},
                ignore = { spellRef },
                useBackTriangles = true,
            }
            if result and result.reference then
                logger:debug("Found target")
                local campfire = result.reference
                local hasFuel = campfire.data.fuelLevel and campfire.data.fuelLevel > 0
                local isLit = campfire.data.isLit
                if hasFuel then
                    logger:debug("Target has fuel")
                    if isFireSpell and not isLit then
                        logger:debug("lighting fire on target")
                        event.trigger("Ashfall:fuelConsumer_Alight", { fuelConsumer = campfire})
                    end
                    if isLit and isFrostSpell then
                        logger:debug("Extinguishing fire on target")
                        extinguishFire(campfire)
                    end
                end
            end
        end
    end
end
event.register("projectileExpire", onSpellHit)