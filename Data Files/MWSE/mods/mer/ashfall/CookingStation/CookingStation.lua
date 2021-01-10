local Interface = {}

function Interface:new(data)
    if data then
        for field, _ in pairs(data) do
            assert( self.fields[field], string.format("Invalid %s field for objectType %s", field, data.type) )
        end
    end
    local t = data or {}
    setmetatable(t, self)
    self.__index = self
    return t
end

Campfire.


return Interface