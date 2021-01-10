
local Object = {}

Object.type = "Object"
Object.fields = {}

function Object:new(data)
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

function Object:__index(key)
	return self[key]
end

return Object