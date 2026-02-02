local common = require("mer.ashfall.common.common")
local logger = common.createLogger("PotteryBreaking")
local PotteryRecipe = require("mer.ashfall.clay.PotteryRecipe")
local RawClay = require("mer.ashfall.clay.RawClay")
local PotteryDecals = require("mer.ashfall.clay.PotteryDecals")

---Module for handling pottery breaking mechanics shared between unfired and fired pottery
---@class Ashfall.PotteryBreaking
local PotteryBreaking = {}

---Crack a pottery item, setting cracked status and applying visual effects
---@param reference tes3reference The pottery reference to crack
---@param data table The pottery data containing cracked status
---@param shouldNotifyPlayer boolean Whether to play sound effects for the player
function PotteryBreaking.crackPottery(reference, data, shouldNotifyPlayer)
    if not reference then
        logger:warn("PotteryBreaking.crackPottery() called but no reference present")
        return
    end
    if data.cracked then
        logger:warn("PotteryBreaking.crackPottery() called but pottery is already cracked")
        return
    end
    data.cracked = true
    logger:trace("PotteryBreaking.crackPottery() called - pottery has cracked")

    if shouldNotifyPlayer then
        tes3.playSound{
            soundPath = "ashfall/potcrack.wav",
        }
    end

    PotteryBreaking.setDecals(reference, data)
end

---Set decals on pottery based on its state
---@param reference tes3reference The pottery reference
---@param data table The pottery data containing cracked status
function PotteryBreaking.setDecals(reference, data)
    if not reference then
        logger:warn("PotteryBreaking.setDecals() called but no reference present")
        return
    end

    if data.cracked then
        logger:debug("Applying cracked decal to pottery: %s", reference.id)
        local cracks = PotteryDecals.get("cracks")
        if cracks then
            cracks:applyDecal(reference)
        end
    end
end

---Break a pottery item, replacing it with animated broken clay activator
---@param reference tes3reference The pottery reference to break
---@param recipe Ashfall.PotteryRecipe The pottery recipe
---@param shouldNotifyPlayer boolean Whether to play sound effects for the player
function PotteryBreaking.breakPottery(reference, recipe, shouldNotifyPlayer)
    if not reference then
        logger:warn("PotteryBreaking.breakPottery() called but no reference present")
        return
    end

    logger:trace("PotteryBreaking.breakPottery() called - pottery has broken")

    if shouldNotifyPlayer then
        tes3.playSound{
            soundPath = "ashfall/potbreak.wav",
        }
    end

    if recipe and recipe.brokenId then
        local brokenActivator = tes3.createReference{
            object = recipe.brokenId,
            position = reference.position,
            orientation = reference.orientation,
            cell = reference.cell,
        }

        if brokenActivator then
            brokenActivator.hasNoCollision = true
            tes3.playAnimation{
                reference = brokenActivator,
                group = tes3.animationGroup.idle2,
                flag = tes3.animationStartFlag.immediate,
                loopCount = 0
            }
        end
        reference:delete()
    end
end

---Check if a reference is a broken pottery activator
---@param ref tes3reference
---@return boolean
function PotteryBreaking.isBrokenActivator(ref)
    return PotteryRecipe.registeredBrokenActivators[ref.baseObject.id:lower()] ~= nil
end

---Handle activation of broken pottery activators
---Adds broken clay to player inventory and removes the activator
---@param e activateEventData
---@return boolean|nil False to block activation
function PotteryBreaking.onActivateBroken(e)
    if not PotteryBreaking.isBrokenActivator(e.target) then
        return
    end

    tes3.addItem{
        reference = tes3.player,
        item = RawClay.brokenClayId,
        count = 1,
        showMessage = true
    }
    timer.delayOneFrame(function()
        e.target:delete()
    end)
    return false
end

---When hitting fired clay with a blunt weapon, crack or break it
function PotteryBreaking.onHit(target)
    -- Lazy require to avoid circular dependency
    local FiredPottery = require("mer.ashfall.clay.FiredPottery")

    if not FiredPottery.isFiredItem(target.baseObject) then
        return
    end

    logger:trace("Fired pottery hit detected")
    local pottery = FiredPottery:new{ reference = target }
    if not pottery then
        logger:error("Failed to create FiredPottery instance for hit pottery: " .. target.baseObject.id)
        return
    end

    -- If already cracked, break it. Otherwise, crack it.
    if pottery.data.cracked then
        logger:trace("Pottery is already cracked, breaking it")
        local recipe = PotteryRecipe.getRecipeByFiredItemId(target.baseObject.id)
        PotteryBreaking.breakPottery(target, recipe, true)
    else
        logger:trace("Pottery is not cracked, cracking it")
        PotteryBreaking.crackPottery(target, pottery.data, true)
    end
end

function PotteryBreaking.initialise()
    event.register(tes3.event.attackHit, function(e)
        if e.reference == tes3.player then
            PotteryBreaking.onHit(tes3.getPlayerTarget())
        end
    end)
end

return PotteryBreaking
