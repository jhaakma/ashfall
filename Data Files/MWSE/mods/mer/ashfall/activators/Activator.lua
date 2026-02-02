---@class Ashfall.Activator : Ashfall.Activator.newData
---@field id string Unique identifier for this activator variant
---@field type string The activator type (functional category)
---@field ids table<string, boolean|table> A set of specific object IDs that are this activator type
---@field patterns table<string, boolean> A set of string patterns to match object IDs against
---@field name string|nil The name of the activator (if any)
---@field requirements fun(self: Ashfall.Activator, reference:tes3reference):boolean|nil A function that takes a reference
---@field mcmSetting string|nil The MCM setting that enables/disables this activator (if any)
---@field isStewer boolean|nil Whether this activator is a stewer
---@field owned boolean|nil Whether this activator is owned by NPCs
---@field menuConfig any TODO Figure out what this is
---@field currentRef tes3reference|nil The current reference being looked at
local Activator = {
    ---@type table<string, Ashfall.Activator> Registry of all activators indexed by ID
    registeredActivators = {},

    --- Current activator ID being looked at
    current = nil,
    --- Current reference being looked at
    currentRef = nil,
    --- Current parent node
    parentNode = nil,
}

---@type mwseSafeObjectHandle|nil
local safeCurrentRef

-- Metatable to handle safe object handles for currentRef
setmetatable(Activator, {
    ---when setting currentRef, create a safeObjectHandle
    __newindex = function(self, key, val)
        if key == "currentRef" then
            if val then
                safeCurrentRef = tes3.makeSafeObjectHandle(val)
            else
                safeCurrentRef = nil
            end
        else
            rawset(self, key, val)
        end
    end,
    ---when getting currentRef, validate and return the safeObjectHandle
    __index = function(self, key)
        if key == "currentRef" then
            if safeCurrentRef and safeCurrentRef:valid() then
                local ref = safeCurrentRef:getObject()
                if ref then
                    return ref
                else
                    safeCurrentRef = nil
                end
            else
                safeCurrentRef = nil
            end
        else
            return rawget(self, key)
        end
    end
})

---@class Ashfall.Activator.newData
---@field id string Unique identifier for this activator variant
---@field type string The activator type (functional category)
---@field ids table<string, boolean|table>? A set of specific object IDs that are this activator type
---@field patterns table<string, boolean>? A set of string patterns to match object IDs against
---@field name string? The name of the activator (if any)
---@field requirements? fun(self: Ashfall.Activator, reference:tes3reference):boolean|nil A function that takes a reference
---@field mcmSetting string? The MCM setting that enables/disables this activator
---@field isStewer boolean? Whether this activator is a stewer
---@field owned boolean? Whether this activator is owned by NPCs
---@field menuConfig any TODO Figure out what this is

---Create a new activator instance and register it
---@param data Ashfall.Activator.newData
---@return Ashfall.Activator
function Activator:new(data)
    assert(data.id, "Activator must have an id")
    assert(data.type, "Activator must have a type")

    local t = data or {}
    ---@cast t Ashfall.Activator
    t.ids = t.ids or {}
    t.patterns = t.patterns or {}
    setmetatable(t, self)
    self.__index = self

    -- Register by ID
    Activator.registeredActivators[t.id] = t
    return t
end

---Register an alias ID that points to an existing activator
---@param aliasId string The alias ID to register
---@param targetId string The existing activator ID to point to
function Activator.registerAlias(aliasId, targetId)
    local target = Activator.registeredActivators[targetId]
    if not target then
        error(string.format("Cannot create alias '%s': target activator '%s' does not exist", aliasId, targetId))
    end
    Activator.registeredActivators[aliasId] = target
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
                --add to ids
                self:addId(reference.baseObject.id)
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

---Get an activator by its ID
---@param id string
---@return Ashfall.Activator|nil
function Activator.get(id)
    return Activator.registeredActivators[id]
end

---Get the currently looked-at activator
---@return Ashfall.Activator|nil
function Activator.getCurrent()
    if not Activator.current then return nil end
    return Activator.registeredActivators[Activator.current]
end

---Get the current activator type
---@return string|nil
function Activator.getCurrentType()
    local current = Activator.getCurrent()
    return current and current.type
end

---Get the current reference being looked at
---@return tes3reference|nil
function Activator.getCurrentReference()
    return Activator.currentRef
end

---Find which activator matches a given reference
---@param reference tes3reference
---@return Ashfall.Activator|nil
function Activator.getForReference(reference)
    for _, activator in pairs(Activator.registeredActivators) do
        if activator:isActivator(reference) then
            return activator
        end
    end
    return nil
end

---Get all registered activators
---@return table<string, Ashfall.Activator>
function Activator.getAll()
    return Activator.registeredActivators
end

return Activator