
local Activator = {}

Activator.type = nil 
Activator.name = ""
Activator.mcmSetting = nil
Activator.ids = {}
Activator.patterns = {}
Activator.hideTooltip = false

function Activator:new(data)
    local t = data or {}
    t.ids = t.ids or {}
    t.patterns = t.patterns or {}
    setmetatable(t, self)
    self.__index = self
    return t
end


function Activator:isActivator(id)
    if self.ids then
        if self.ids[string.lower(id)] then
            return true
        end
    end
    if self.patterns then
        for pattern, _ in pairs(self.patterns) do
            if string.find(string.lower(id), pattern) ~= nil then
                return true
            end
        end
    end

    return false
end

function Activator:addId(id)
    self.ids[id:lower()] = true
end

function Activator:addPattern(pattern)
    self.patterns[pattern:lower()] = true
end

return Activator