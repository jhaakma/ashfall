---@class AshfallTooltipData
---@field header string (optional) The header at the top of the tooltip
---@field text string (optional) The text in the body of the tooltip

---@class AshfallMessageBoxButton
---@field showRequirements function If set, the button will only be visible if this function returns true.
---@field requirements function (optional) function that, if provided, determines whether the button will be call the callback when clicked, or be disabled + greyed out.
---@field text string The label on the button.
---@field callback function The function to call when this button is clicked.
---@field tooltip AshfallTooltipData (optional) table with header and text that will display as a tooltip when the button is hovered over.
---@field tooltipDisabled AshfallTooltipData (optional) tooltip for when a button has been disabled.

---@class AshfallMessageBoxData
---@field message string The message at the top of the messagebox.
---@field maxButtons number (optional) Number of buttons displayed per page. Default is 30.
---@field doesCancel boolean (optional) When set to true, a cancel button is automatically added to the buttom of the list, even when paginated.
---@field cancelCallback function (optional) function to call when the user clicks the cancel button.
---@field buttons AshfallMessageBoxButton[] List of buttons
