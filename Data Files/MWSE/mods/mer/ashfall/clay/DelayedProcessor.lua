---Uses timer.delayOneFrame to process items in batches over multiple frames
---@class DelayedProcessor : DelayedProcessor.config
---@field callback fun(item: any) The callback function to process each item
local DelayedProcessor = {}

---@class DelayedProcessor.config
---@field processDuringPause boolean (Default: false) Whether to process items while the game is paused
---@field callback fun(item: any) The callback function to process each item
---@field batchSize number (Default: 10) The number of items to process per frame

---@param e DelayedProcessor.config
---@return DelayedProcessor
function DelayedProcessor:new(e)
    local processor = {
        safeRefs = {},
        callback = e.callback,
        batchSize = e.batchSize or 1
    }
    setmetatable(processor, self)
    self.__index = self
    return processor
end

---Process a list of items in batches over multiple frames
---@param items any[]
function DelayedProcessor:processItems(items)
    local function processBatch()
        local count = 0
        while #items > 0 and count < self.batchSize do
            local item = table.remove(items, 1)
            self.callback(item)
            count = count + 1
        end

        if #items > 0 then
            timer.delayOneFrame(processBatch)
        end
    end

    timer.delayOneFrame(processBatch)
end

return DelayedProcessor