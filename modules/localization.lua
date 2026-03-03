local Localization = {}
Localization.__index = Localization

local dictionaries = {
    ko = require("loc.ko"),
    en = require("loc.en"),
}

local currentLanguage = "ko"

local function normalizeLanguage(language)
    if type(language) ~= "string" then
        return nil
    end

    local lowered = string.lower(language)
    if lowered == "ko" or lowered == "en" then
        return lowered
    end

    return nil
end

local function readLanguageFromConfig()
    if not is or not is.config then
        return nil
    end

    local cfg = is.config()
    if type(cfg) ~= "table" then
        return nil
    end

    local direct = normalizeLanguage(cfg.language)
    if direct then
        return direct
    end

    local locale = cfg.localization or cfg.Localization
    if type(locale) == "table" then
        local nested = normalizeLanguage(locale.language)
        if nested then
            return nested
        end
    end

    return nil
end

local function lookupByPath(root, path)
    local node = root
    for segment in string.gmatch(path, "[^%.]+") do
        if type(node) ~= "table" then
            return nil
        end
        node = node[segment]
        if node == nil then
            return nil
        end
    end
    return node
end

local function applyParams(text, params)
    if not params then
        return text
    end

    return (text:gsub("{([%w_]+)}", function(name)
        local value = params[name]
        if value == nil then
            return "{" .. name .. "}"
        end
        return tostring(value)
    end))
end

function Localization.setLanguage(language)
    if dictionaries[language] then
        currentLanguage = language
        return true
    end
    return false
end

function Localization.getLanguage()
    return currentLanguage
end

function Localization.t(path, params)
    local dict = dictionaries[currentLanguage] or dictionaries.ko
    local value = lookupByPath(dict, path)
    if value == nil and dict ~= dictionaries.ko then
        value = lookupByPath(dictionaries.ko, path)
    end
    if value == nil then
        return path
    end
    if type(value) ~= "string" then
        return value
    end
    return applyParams(value, params)
end

function Localization.loadLanguageFromConfig()
    local language = readLanguageFromConfig()
    if language and dictionaries[language] then
        currentLanguage = language
        return language
    end
    return currentLanguage
end

Localization.loadLanguageFromConfig()

return Localization
