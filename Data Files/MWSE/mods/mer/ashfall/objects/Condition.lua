local Parent = require("mer.ashfall.objects.Object")
local Condition = Parent:new()
local config = require("mer.ashfall.config.config")
Condition.type = "Condition"
Condition.fields = {
    id = true,
    default = true, 
    showMessageOption = true,
    enableOption = true,
    states = true,
    minDebuffState = true,
    min = true, 
    max = true,
    minCallback = true,
    maxCallback = true,
    getCurrentStateMessage = true,
    isAffected = true,
    getCurrentSpellObj = true,
    conditionChanged = true,
    updateConditionEffects = true,
    hasSpell = true,
    getBlights = true,
}


function Condition:scaleSpellValues()

    local state = self:getCurrentStateData()
    local spell = self:getCurrentSpellObj(state)
    if not spell then return end
    if not state.effects then return end
    
    for _, stateEffect in ipairs(state.effects) do
        for _, spellEffect in ipairs(spell.effects) do
            local doScale = (
                spellEffect.id == stateEffect.id and 
                spellEffect.attribute == stateEffect.attribute and
                stateEffect.amount
            )
            if doScale then
                --For drain/fortify attributes, we scale according
                --to the player's base amount. 
                if stateEffect.attribute then
                    local baseAttr = tes3.mobilePlayer.attributes[stateEffect.attribute + 1].base 
                    spellEffect.min = baseAttr * stateEffect.amount
                    spellEffect.max = spellEffect.min
                end
            end
        end
    end

end

function Condition:isActive()
    return ( 
        config.getConfig()[self.enableOption] == true 
    )
end

function Condition:conditionChanged(newState)
    self:showUpdateMessages()
    self:playConditionSound()
    self:updateConditionEffects(newState)
end

function Condition:showUpdateMessages()
    if (
        self:isActive() and
        ( tes3.player.data.Ashfall.fadeBlock ~= true ) and
        ( config.getConfig()[self.showMessageOption] == true ) 
    ) then
        local message = self:getCurrentStateMessage()
        if message then
            tes3.messageBox(message)
        end
    end
end

function Condition:playConditionSound()
    if not self:isActive() then return end 
    local sound = self:getCurrentStateData().sound
    if sound then
        tes3.playSound{ sound = sound } 
    end
end

function Condition:getCurrentStateMessage()
    return string.format("You are %s.", self:getCurrentStateData().text )
end

function Condition:getCurrentStateData()
    return self.states[self:getCurrentState()]
end

function Condition:getCurrentSpellObj(stateData)
    stateData = stateData or self:getCurrentStateData()
    local spellId =  type(stateData.spell) == "function" and stateData.spell() or stateData.spell
    if spellId then
        return tes3.getObject(spellId)
    end
end

--[[
    Returns the current state ID the player is in for this condition
]]
function Condition:getCurrentState()
    local currentState = self.default
    local currentValue = self:getValue()
    currentValue = math.clamp(currentValue, self.min, self.max)

    for id, values in pairs (self.states) do
        if values.min <= currentValue and currentValue <= values.max then
            currentState = id
        end
    end
    return currentState
end

function Condition:isAffected(stateData)
    stateData = stateData or self:getCurrentStateData()
    return tes3.player.mobile:isAffectedByObject(self:getCurrentSpellObj(stateData))
end

function Condition:updateConditionEffects(currentState)
    if tes3ui.menuMode() then return end
    currentState = currentState or self:getCurrentState()
    for state, stateData in pairs(self.states) do
        local isCurrentState = ( currentState == state )
        local spell = self:getCurrentSpellObj(stateData)
        if spell then
            local hasCondition = self:isAffected(stateData)
            if isCurrentState and self:isActive() then
                self:scaleSpellValues()
                if not hasCondition then
                    mwscript.addSpell({ reference = tes3.player, spell = spell })
                end
            else
                if hasCondition then
                    mwscript.removeSpell({ reference = tes3.player, spell = spell })
                end
            end
        end
    end
end

function Condition:getValue()
    if not tes3.player or not tes3.player.data.Ashfall then
        mwse.log("ERROR: trying to get condition value %s before player was loaded", self.id)
        return 0
    end
    return tes3.player.data.Ashfall[self.id] or 0
end


function Condition:setValue(newVal)
    if not tes3.player or not tes3.player.data.Ashfall then
        --mwse.log("ERROR: trying to set condition value %s before player was loaded", self.id)
        return
    end
    tes3.player.data.Ashfall[self.id] = math.clamp(newVal, self.min, self.max)
end

function Condition:getStatMultiplier()
    if self.minDebuffState then
        local minVal =  self.states[self.minDebuffState].min
        local value = math.max(self:getValue(), minVal)
        return math.remap(value, minVal, 100, 1.0, 0.0)
    else
        mwse.log("[Asfall ERROR] getStatMultiplier(): %s does not have a debuffState", self.id)
    end
end

return Condition