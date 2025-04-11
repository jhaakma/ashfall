

---@class StaggeredRefProcessor
---@field refs table<tes3reference, boolean>
---@field private callback fun(ref: tes3reference)
---@field private onEmpty fun(self: StaggeredRefProcessor)?
---@field private interval number
---@field private refsPerFrame integer
---@field private timerHandle mwseTimer|nil
---@field private logger mwseLogger
local StaggeredRefProcessor = {}
StaggeredRefProcessor.__index = StaggeredRefProcessor

---@class StaggeredRefProcessor.newParams
---@field callback fun(ref: tes3reference) Callback function to be called for each reference
---@field interval number Time interval between processing batches of references (in seconds)
---@field refsPerFrame integer Number of references to process per frame
---@field logger mwseLogger Logger instance for logging messages
---@field onEmpty fun(self: StaggeredRefProcessor)? Callback function to be called when all references are processed

---Create a new StaggeredRefProcessor
---@param  config StaggeredRefProcessor.newParams
---@return StaggeredRefProcessor
function StaggeredRefProcessor.new(config)
    local self = setmetatable({}, StaggeredRefProcessor) --[[@as StaggeredRefProcessor]]
    self.refs = {}
    self.callback = config.callback
    self.interval = config.interval or 1.0
    self.refsPerFrame = config.refsPerFrame or 1
    self.logger = config.logger
    self.onEmpty = config.onEmpty
    self.timerHandle = nil

    -- Automatically remove invalid references
    event.register("objectInvalidated", function(e)
        self.refs[e.object] = nil
    end)

    return self
end

---Add a reference
---@type StaggeredRefProcessor|nil
function StaggeredRefProcessor:add(ref)
    if ref and ref.sceneNode then
        self.refs[ref] = true
    end
end


---Remove a reference
---@param ref tes3reference
function StaggeredRefProcessor:remove(ref)
    self.refs[ref] = nil
end

---Clear all references
function StaggeredRefProcessor:clear()
    self.refs = {}
end

---Start processing loop
function StaggeredRefProcessor:start()
    if self.timerHandle then
        self.timerHandle:cancel()
        self.timerHandle = nil
    end
    self.timerHandle = timer.start{
        duration = self.interval,
        iterations = -1,
        callback = function()
            self:_process()
        end
    }
end

---Stop processing
function StaggeredRefProcessor:stop()
    if self.timerHandle then
        self.timerHandle:cancel()
        self.timerHandle = nil
    end
end

---Internal function to process some references
function StaggeredRefProcessor:_process()
    local processed = 0
    for ref in pairs(self.refs) do
        if not ref.sceneNode then
            self.refs[ref] = nil
        else
            self.callback(ref)
            self.refs[ref] = nil
            processed = processed + 1
        end
        if processed >= self.refsPerFrame then
            break
        end
    end

    if next(self.refs) == nil and self.onEmpty then
        self:onEmpty()
    end
end

return StaggeredRefProcessor