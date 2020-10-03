
local Activator = {}

Activator.type = nil 
Activator.name = ""
Activator.mcmSetting = nil
Activator.ids = {}
Activator.patterns = {}
Activator.hideTooltip = false

function Activator:new(data)
    local t = data or {}
    setmetatable(t, self)
    self.__index = self
    return t
end
 
function Activator:isActivator(id)
    
    if self.ids then
        if self.ids[string.lower(id)] == true then
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

return Activator