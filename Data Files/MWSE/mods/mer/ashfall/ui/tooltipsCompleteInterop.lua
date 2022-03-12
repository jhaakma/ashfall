
--Tooltips
local tooltipsComplete = include("Tooltips Complete.interop")
local itemDescriptions = require("mer.ashfall.config.itemDescriptions")

for id, description in ipairs(itemDescriptions) do
    if tooltipsComplete then
        if tes3.getObject(id) then
            tooltipsComplete.addTooltip(id, description)
        end
    end
end
