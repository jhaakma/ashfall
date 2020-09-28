local common = require("mer.ashfall.common.common")

local Meal = {}
Meal.duration = 6
Meal.spellId = "ashfall_default_meal"

function Meal:new(data)
    local t = data or {}
    setmetatable(t, self)
    self.__index = self
    return t
end

function Meal:applyBuff()
    --Remove previous meal buff
    local doRemoveOld = (
        common.data.mealTime and common.data.mealTime > 0 and
        common.data.mealBuff and
        common.data.mealBuff ~= self.spellId 
    )
    if doRemoveOld then
        mwscript.removeSpell({ reference = tes3.player, spell = common.data.mealBuff })
    end
    --add new buff
    mwscript.addSpell({ reference = tes3.player, spell = self.spellId })
    tes3.playSound({ sound = "restoration hit" })  

    --Update player ref with current buff/duration
    common.data.mealTime = self.duration
    common.data.mealBuff = self.spellId
end

return Meal