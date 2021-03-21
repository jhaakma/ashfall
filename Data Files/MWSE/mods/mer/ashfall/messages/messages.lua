
local function getMessages(lang)
    return include(string.format("mer.ashfall.messages.%s", lang))
end
--Start with English in case translation is incomplete
local messages = getMessages("eng") or {}
-- Get the ISO language code.
local language = tes3.getLanguage()
if language ~= "eng" then
    --Copy the translation if we have one
    local translation = getMessages(language)
    if translation then
        table.copy(translation, messages)
    end
end

return messages