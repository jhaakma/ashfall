local common = require("mer.ashfall.common.common")
local logger = common.createLogger("bandages")
local bandageConfig = require("mer.ashfall.items.bandages.config")


--Dynamic Bandage Display
-- Disabled until Better Bodies compatibility is sorted out

local function getCurrentBandages()
    if not (common.data and common.data.bandages) then
        common.data.bandages = {}
    end
	return common.data.bandages
end

local function onBodyPartAssigned(e)
	if (e.reference == tes3.player) then
		if e.bodyPart and not e.object then
            local bandagePart = bandageConfig.bandageParts[e.index]
			if getCurrentBandages()[e.index] and bandagePart then
                logger:debug(bandagePart)
				local bandage = tes3.getObject(bandagePart)
				if bandage.part == e.bodyPart.part then
					logger:debug("Index: %s, Part Mesh: %s", e.index, e.bodyPart.mesh)
					e.bodyPart = bandage
				else
					logger:error("invalid body part mapping")
				end
			end
        end
	end
end
event.register("Ashfall:dataLoadedOnce", function()
    --event.register("bodyPartAssigned", onBodyPartAssigned)
end)