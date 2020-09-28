local this = {}
local common = require("mer.ashfall.common.common")

--Block or unblock hunger, thirst and sleep
function this.blockNeeds()
    if common.data then
        common.data.blockNeeds = true
    end
end
function this.unblockNeeds()
    if common.data then
        common.data.blockNeeds = false
    end
end

--block or unblock sleep
function this.blockSleepLoss()
    if common.data then
        common.data.blockSleepLoss = true
    end
end
function this.unblockSleepLoss()
    if common.data then
        common.data.blockSleepLoss = false
    end
end

--block or unblock hunger
function this.blockHunger()
    if common.data then
        common.data.blockHunger = true
    end
end
function this.unblockHunger()
    if common.data then
        common.data.blockHunger = false
    end
end

--block or unblock thirst
function this.blockThirst()
    if common.data then
        common.data.blockThirst = true
    end
end
function this.unblockThirst()
    if common.data then
        common.data.blockThirst = false
    end
end

return this