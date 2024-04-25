local lanternConfig = require("mer.ashfall.items.lantern.config")
local SwitchNode = require("CraftingFramework.nodeVisuals.SwitchNode")
local NodeManager = require("CraftingFramework.nodeVisuals.NodeManager")
--Always turn off handle so it doesn't show when dropped
-- defaults to on when equipped
local switchConfig = {
    id = "LANTERN_HANDLE_SWITCH",
    getActiveIndex = function(self, e)
        return self.getIndex(e.node, "OFF")
    end
}

local switchNode = SwitchNode.new(switchConfig)

NodeManager.register{
    id = "Ashfall_lantern_handle",
    nodes = { switchNode },
    referenceRequirements = function(reference)
        return lanternConfig.ids[reference.object.id:lower()]
    end
}