--Updates condition spell effect strength based on player stats
--Uses base version of spell as a reference to get attribute  values without multiplier
local common = require("mer.ashfall.common.common")
local conditionConfig = common.staticConfigs.conditionConfig
local this = {}


--Update the spell strength to scale with player attributes/level

function this.updateCondition(id)

    if not common.data then return end
    local thisCondition = conditionConfig[id]

    if common.data.currentStates[id] == nil then
        common.data.currentStates[id] = thisCondition.default
    end

    local previousState = common.data.currentStates[id] or thisCondition.default
    local currentState = thisCondition:getCurrentState()

    local conditionChanging = ( currentState ~= previousState )
    --Restore fatigue if it drops below 0
    if conditionChanging then
        common.helper.restoreFatigue()
        common.data.currentStates[id] = currentState
        thisCondition:conditionChanged(currentState)
    end

end

--Update all conditions - called by the script timer
function this.updateConditions()
    --if tes3.menuMode() then return end
    for id, _ in pairs(conditionConfig) do
        this.updateCondition(id)
    end
end

local function refreshConditions()
    for _, condition in pairs(conditionConfig) do
        condition:updateConditionEffects()
    end
end

--Update all conditions on load

local function updateConditionsOnLoad()
    refreshConditions()
    timer.start{
        type = timer.real,
        duration = 1,
        iterations = -1, 
        callback = refreshConditions
    } 
end
event.register("loaded", updateConditionsOnLoad)

--Remove and re-add the condition spell if the player healed their stats with a potion or spell. 
local function refreshAfterRestore(e)
    if e.target ~= tes3.player then return end
    local doRefresh = (
        e.effectInstance.state == tes3.spellState.ending and
        --We aren't checking Ashfall spells, we're checking other spells that might have healed the ashfall spells
        not ( string.startswith(e.source.id, "fw") or string.startswith(e.source.id, "ashfall_") )
    )
    if doRefresh then
        for id, condition in pairs(conditionConfig) do
            local states = conditionConfig[id].states
            if states then
                local spell = condition:getCurrentSpellObj()
                if spell and tes3.player.object.spells:contains(spell) then
                    mwscript.addSpell({ reference = tes3.player, spell = spell })
                end
            end
        end
    end
end

event.register("spellTick", refreshAfterRestore)

return this