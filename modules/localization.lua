local Localization = {}
Localization.__index = Localization

local dictionaries = {
    ko = require("loc.ko"),
}

local currentLanguage = "ko"

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
    if value == nil then
        return path
    end
    if type(value) ~= "string" then
        return value
    end
    return applyParams(value, params)
end

return Localization
