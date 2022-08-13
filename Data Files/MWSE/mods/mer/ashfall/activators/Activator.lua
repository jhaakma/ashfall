
local Activator = {}

function Activator:new(data)
    local t = data or {}
    t.ids = t.ids or {}
    t.patterns = t.patterns or {}
    setmetatable(t, self)
    self.__index = self
    return t
end


function Activator:isActivator(reference)
    if self.ids then
        if self.ids[reference.baseObject.id:lower()] then
            return true
        end
    end
    if self.patterns then
        for pattern, _ in pairs(self.patterns) do
            if string.find(reference.baseObject.id:lower(), pattern) ~= nil then
                return true
            end
        end
    end
    if self.requirements then
        return self:requirements(reference)
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