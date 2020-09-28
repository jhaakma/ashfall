
local activatorController = require("mer.ashfall.activators.activatorController")
local common = require("mer.ashfall.common.common")
local activatorConfig = common.staticConfigs.activatorConfig
local lastRef

--How many swings required to collect wood. Randomised again after each harvest
local swingsNeeded
local swings = 0


local function onAttack(e)
    -- for i=1, 100 do
    --     logger:info("INFO %s", i)
    --     logger:debug("DEBUG")
    -- end
--[[
    Use an axe on a tree to chop firewood
    - Number of swings is based on the size of your swing
    - Number of wood collected is based on the size of swing and axe attack power
]]--
    if not common.config.getConfig().enableTemperatureEffects then
        return
    end
    local lookingAtWood = activatorController.getCurrentType() == activatorConfig.types.woodSource
    local isPlayer = e.mobile.reference == tes3.player
    --attacker is player and looking at wood
    if isPlayer and lookingAtWood then
        --Get weapon details
        local weapon = tes3.mobilePlayer.readiedWeapon
        if weapon then
            local swingType = tes3.mobilePlayer.actionData.attackDirection
            local swingStrength = tes3.mobilePlayer.actionData.attackSwing
            
            --Chopping with an axe--
            local chop = 2
            local axe1h = 7
            local axe2h = 8
            local choppingWithAxe = (
                swingType == chop and 
                ( weapon.object.type == axe1h or weapon.object.type == axe2h ) 
            )
            if choppingWithAxe then 
                
                
                --More chop damage == more wood collected. Maxes out at chopCeiling. Range 0.0-1.0
                local chopCeiling = 50
                local axeDamageMultiplier = math.min(weapon.object.chopMax, chopCeiling) / chopCeiling

                local woodAxeMulti = 0.0
                if weapon.object.id == common.staticConfigs.objectIds.woodaxe then
                    woodAxeMulti = 0.5
                end

                --If attacking the same target, accumulate swings
                local targetRef = activatorController.currentRef
                if lastRef == targetRef then
                    swings = swings + swingStrength * ( 1 + axeDamageMultiplier + woodAxeMulti )
                else
                    lastRef = targetRef
                    swings = 0
                end
                
                --Check if legal to harvest wood
                local illegalToHarvest = ( 
                    common.config.getConfig().illegalHarvest and
                    tes3.getPlayerCell().restingIsIllegal
                )
                if illegalToHarvest then
                    tes3.messageBox("You must be in the wilderness to harvest firewood.")
                else

                    tes3.playSound({reference=tes3.player, sound="ashfall_chop"})
                    --Weapon degradation, unequip if below 0
                    weapon.variables.condition = weapon.variables.condition - (10 * swingStrength)
                    if weapon.variables.condition <= 0 then
                        weapon.variables.condition = 0
                        tes3.mobilePlayer:unequip{ type = tes3.objectType.weapon }
                        --mwscript.playSound({reference=playerRef, sound="Item Misc Down"})
                        return
                    end

                    local function getSwingsNeeded()                    
                        --survival = 0, 0.75
                        return ( math.random(4,6) )
                    end
                    
                    if not swingsNeeded then
                        swingsNeeded = getSwingsNeeded()
                    end
                     
                    
                    --wait until chopped enough times
                    if swings >= swingsNeeded then 
                        --wood collected based on strength of previous swings
                        --Between 0.5 and 1.0 (at chop == 50)

                        --if skills are implemented, use Survival Skill                
                        local survivalSkill = common.skills.survival.value or 30
                        --cap at 100
                        survivalSkill = ( survivalSkill < 100 ) and survivalSkill or 100
                        --Between 0.5 and 1.0 (at 100 Survival)
                        local survivalMultiplier = 1 + ( survivalSkill / 50 )
                        local numWood =  math.floor( ( 1 + math.random() * 2 )  * survivalMultiplier )
                        --Max 8
                        numWood = ( numWood < 100 ) and numWood or 8
                        --minimum 1 wood collected
                        if numWood == 1 then
                            tes3.messageBox("You have harvested 1 piece of firewood")
                        else
                            tes3.messageBox("You have harvested %d pieces of firewood", numWood)
                        end
                        
                        tes3.playSound({reference=tes3.player, sound="Item Misc Up"})
                        mwscript.addItem{reference=tes3.player, item=common.staticConfigs.objectIds.firewood, count=numWood}
                        event.trigger("Ashfall:triggerPackUpdate")
                        common.skills.survival:progressSkill(swingsNeeded*2)
                        --reset swings
                        swings = 0
                        swingsNeeded = getSwingsNeeded()
                    end
                end
            end
        end
    end
end

event.register("attack", onAttack )
