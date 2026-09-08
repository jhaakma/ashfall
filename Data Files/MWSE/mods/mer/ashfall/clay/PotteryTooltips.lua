local common = require("mer.ashfall.common.common")
local Campfire = require("mer.ashfall.camping.campfire.Campfire")

---Shared tooltip helpers for pottery items (unfired + fired).
---@class Ashfall.PotteryTooltips
local PotteryTooltips = {}

---@class Ashfall.PotteryTooltips.TemperatureKind
---@field unfired "unfired"
---@field fired "fired"

---Temperature stage names for unfired pottery (firing-specific language).
---@type table<string, string>
PotteryTooltips.STAGE_NAMES_UNFIRED = {
    glazing = "Glaze Firing",
    firing = "Bisque Firing",
    cooking = "Hot",
}

---Temperature stage names for fired pottery (no firing/glazing language).
---@type table<string, string>
PotteryTooltips.STAGE_NAMES_FIRED = {
    glazing = "Very Hot",
    firing = "Very Hot", --Can't pick up, likely to crack if cooled too quickly
    cooking = "Hot", --Can't pick up, but maybe safe to extinguish fire and let cool
}

---@param tooltip tes3uiElement
---@param labels (string|{text: string, color: number[]?})[]
function PotteryTooltips.addLabelsToTooltip(tooltip, labels)
    for _, label in ipairs(labels) do
        if type(label) == "table" then
            common.helper.addLabelToTooltip(tooltip, label.text, label.color)
        else
            common.helper.addLabelToTooltip(tooltip, label)
        end
    end
end

---@param cracked boolean?
---@param text string?
---@return {text: string, color: number[]}|nil
function PotteryTooltips.getCrackedLabel(cracked, text)
    if cracked then
        return {text = text or "Cracked", color = {1.0, 0.5, 0.0}}
    end
end

---@return {text: string, color: number[]}
function PotteryTooltips.getTemperedLabel()
    return {text = "Tempered", color = {0.6, 0.9, 0.7}}
end

---@param quality number?
---@param opts { includeWhenNil: boolean? }?
---@return string|nil
function PotteryTooltips.getQualityLabel(quality, opts)
    local includeWhenNil = opts and opts.includeWhenNil == true
    if quality == nil and not includeWhenNil then
        return nil
    end
    local qualityPercent = (quality or 0.0) * 100
    return string.format("Quality: %d", qualityPercent)
end

function PotteryTooltips.getDecorationLabel(decoration)
    if decoration then
        return { text = decoration.name, color = {0.8, 0.6, 1.0} }
    end
end

---Get the temperature state and color based on current temperature.
---@param heated Ashfall.Clay.HeatedItem?
---@param opts { kind: "unfired"|"fired" }?
---@return string|nil stateName The state description, or nil if no heat
---@return number[]|nil color The RGB color
function PotteryTooltips.getTemperatureState(heated, opts)
    local currentTemp = heated and (heated.data.currentTemperature or 0) or 0

    -- No tooltip if completely cold
    if currentTemp <= 0 then
        return nil, nil
    end

    local kind = opts and opts.kind or "unfired"
    local stageNames = (kind == "fired") and PotteryTooltips.STAGE_NAMES_FIRED or PotteryTooltips.STAGE_NAMES_UNFIRED

    -- Find the current stage from Campfire.ORDERED_STAGES
    local currentStage = Campfire.getStageForHeat(currentTemp)
    if not currentStage then
        return nil, nil
    end

    -- Map the stage to the appropriate name and color
    local stageName = stageNames.cooking -- fallback
    local color = currentStage.color

    for key, stage in pairs(Campfire.STAGES) do
        if stage == currentStage then
            stageName = stageNames[key] or currentStage.name
            break
        end
    end

    return stageName, color
end

---@param heated Ashfall.Clay.HeatedItem?
---@param opts { kind: "unfired"|"fired" }?
---@return {text: string, color: number[]}|nil
function PotteryTooltips.getTemperatureLabel(heated, opts)
    local stateName, stateColor = PotteryTooltips.getTemperatureState(heated, opts)
    if stateName then
        return {text = stateName, color = stateColor}
    end
end

return PotteryTooltips
