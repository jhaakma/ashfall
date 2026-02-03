local common = require("mer.ashfall.common.common")
local Campfire = require("mer.ashfall.camping.campfire.Campfire")

---Shared tooltip helpers for pottery items (unfired + fired).
---@class Ashfall.PotteryTooltips
local PotteryTooltips = {}

---@class Ashfall.PotteryTooltips.TemperatureKind
---@field unfired "unfired"
---@field fired "fired"

---Temperature stages for unfired pottery (firing-specific language).
---@type { minTemp: number, name: string, color: number[] }[]
PotteryTooltips.COLOR_STAGES_UNFIRED = {
    {
        minTemp = Campfire.STAGES.glazing.minTemp,
        name = "Glazing",
        color = Campfire.STAGES.glazing.color,
    },
    {
        minTemp = Campfire.STAGES.firing.minTemp,
        name = "Firing",
        color = {1.0, 0.3, 0.3},
    },
    {
        minTemp = 0,
        name = "Heating Up",
        color = {1.0, 0.8, 0.4},
    },
}

---Temperature stages for fired pottery (no firing/glazing language).
---@type { minTemp: number, name: string, color: number[] }[]
PotteryTooltips.COLOR_STAGES_FIRED = {
    {
        minTemp = Campfire.STAGES.glazing.minTemp,
        name = "Hot",
        color = Campfire.STAGES.glazing.color,
    },
    {
        minTemp = Campfire.STAGES.firing.minTemp,
        name = "Hot",
        color = {1.0, 0.3, 0.3},
    },
    {
        minTemp = 0,
        name = "Warm",
        color = {1.0, 0.8, 0.4},
    },
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

---@param tempered boolean?
---@return {text: string, color: number[]}|nil
function PotteryTooltips.getTemperedLabel(tempered)
    if tempered then
        return {text = "Tempered", color = {0.6, 0.9, 0.7}}
    end
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

---Get the temperature state and color based on current temperature.
---@param heated Ashfall.Clay.HeatedItem?
---@param opts { kind: "unfired"|"fired" }?
---@return string|nil stateName The state description, or nil if no heat
---@return number[]|nil color The RGB color
function PotteryTooltips.getTemperatureState(heated, opts)
    local currentTemp = heated and (heated.data.currentTemperature or 0) or 0
    local targetHeat = heated and (heated.data.targetHeat or 0) or 0
    local isWarming = currentTemp < targetHeat

    -- No tooltip if completely cold
    if currentTemp <= 0 then
        return nil, nil
    end

    local kind = opts and opts.kind or "unfired"
    local stages = (kind == "fired") and PotteryTooltips.COLOR_STAGES_FIRED or PotteryTooltips.COLOR_STAGES_UNFIRED

    local stageName = stages[#stages].name
    local color = stages[#stages].color

    for _, stage in ipairs(stages) do
        if currentTemp >= stage.minTemp then
            stageName = stage.name
            color = stage.color
            break
        end
    end

    -- Override with "Cooling Down" if below firing temp and cooling
    if currentTemp < Campfire.STAGES.firing.minTemp and not isWarming then
        stageName = "Cooling Down"
        color = {0.5, 0.7, 1.0}
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
