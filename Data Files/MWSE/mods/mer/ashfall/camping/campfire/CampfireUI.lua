local Bellows = require("mer.ashfall.camping.Bellows")
local HeatUtil = require("mer.ashfall.heat.HeatUtil")
local Campfire = require("mer.ashfall.camping.campfire.Campfire")

---UI-related functions for campfire tooltips and displays
---@class Ashfall.CampfireUI
local CampfireUI = {}


---Create fuel level label
---@param tooltip table The tooltip object
---@param fuelLevel number The fuel level value
local function createFuelLabel(tooltip, fuelLevel)
    tooltip:createLabel{
        text = string.format("Fuel: %.1f", fuelLevel)
    }
end

---Create heat level label with color gradient
---@param tooltip table The tooltip object
---@param heat number The heat value
---@return number normalisedHeat The normalized heat value (0-1)
local function createHeatLabel(tooltip, heat)
    local heatLabel = tooltip:createLabel{
        text = string.format("Heat: %d", heat * 100)
    }

    local normalisedHeat = math.clamp(
        math.remap(heat, 0, Campfire.STAGES.glazing.minTemp, 0, 1),
        0, 1
    )

    heatLabel.color = {
        math.remap(normalisedHeat, 0, 1, 0.5, 1.0),
        math.remap(normalisedHeat, 0, 1, 0.5, 0.0),
        math.remap(normalisedHeat, 0, 1, 0.5, 0.0)
    }

    return normalisedHeat
end

---Create firing temperature reached label
---@param tooltip table The tooltip object
---@param heat number The current heat value
local function createFiringTempLabel(tooltip, heat)
    local innerBlock = tooltip:createBlock{}
    innerBlock.autoWidth = true
    innerBlock.autoHeight = true
    innerBlock.flowDirection = "left_to_right"

    -- Determine which stage is currently active based on heat
    local activeStage = Campfire.getStageForHeat(heat)
    -- Create labels for each stage
    for i, stage in ipairs(Campfire.ORDERED_STAGES) do
        local label = innerBlock:createLabel{
            text = stage.name
        }

        -- Active stage gets its designated color, inactive stages are greyed out
        if stage == activeStage then
            label.color = stage.color
        else
            label.color = {0.5, 0.5, 0.5}
        end

        -- Add separator between stages (except after last one)
        if i < #Campfire.ORDERED_STAGES then
            local separator = innerBlock:createLabel{
                text = "|"
            }
            separator.color = {0.5, 0.5, 0.5}
            separator.borderLeft = 5
            separator.borderRight = 5
        end
    end
end

---Create bellows effect label
---@param tooltip table The tooltip object
---@param campfireRef tes3reference The campfire reference
local function createBellowsLabel(tooltip, campfireRef)
    local isLit = campfireRef.data.isLit
    if not isLit then return end
    local heatEffect = Bellows.getScaledHeatEffect(campfireRef)
    if not (heatEffect and heatEffect > 0.0) then return end

    local effectText = string.format("+Bellows (Heat x%.2f)", heatEffect)
    local bellowsLabel = tooltip:createLabel{
        text = effectText
    }
    bellowsLabel.color = { 0.5, 0.8, 0.2 }
end

---Create tooltip display for campfire
---@param campfireRef tes3reference The campfire reference
---@param tooltip table The tooltip object
function CampfireUI.createTooltip(campfireRef, tooltip)
    local fuelLevel = campfireRef.data.fuelLevel or 0
    if fuelLevel > 0 then

        local heat = HeatUtil.getHeat(campfireRef)

        createFuelLabel(tooltip, fuelLevel)
        createHeatLabel(tooltip, heat)
        createFiringTempLabel(tooltip, heat)
        createBellowsLabel(tooltip, campfireRef)
    end
end

return CampfireUI
