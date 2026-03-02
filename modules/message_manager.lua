local MessageManager = {}
MessageManager.__index = MessageManager

local function getTextLength(text)
    if utf8 and utf8.len then
        local len = utf8.len(text)
        if len then
            return len
        end
    end
    return #text
end

local function getTextPrefix(text, charCount)
    if charCount <= 0 then
        return ""
    end

    if utf8 and utf8.offset then
        local byteIndex = utf8.offset(text, charCount + 1)
        if byteIndex then
            return string.sub(text, 1, byteIndex - 1)
        end
        return text
    end

    return string.sub(text, 1, charCount)
end

function MessageManager.new(options)
    options = options or {}

    return setmetatable({
        fullText = "",
        textLength = 0,
        visibleChars = 0,
        revealedText = "",
        elapsedMs = 0,
        msPerChar = options.msPerChar or 36,
        speaker = options.speaker or "",
        errorText = "",
        errorTimerMs = 0,
        errorDurationMs = options.errorDurationMs or 1000,
    }, MessageManager)
end

function MessageManager:setMessage(text)
    self.fullText = text or ""
    self.textLength = getTextLength(self.fullText)
    self.visibleChars = 0
    self.revealedText = ""
    self.elapsedMs = 0
end

function MessageManager:update(dtMs)
    if self.errorTimerMs > 0 then
        self.errorTimerMs = math.max(0, self.errorTimerMs - dtMs)
        if self.errorTimerMs == 0 then
            self.errorText = ""
        end
    end

    if self.visibleChars >= self.textLength then
        return
    end

    self.elapsedMs = self.elapsedMs + dtMs
    local revealCount = math.floor(self.elapsedMs / self.msPerChar)
    if revealCount <= 0 then
        return
    end

    self.elapsedMs = self.elapsedMs - (revealCount * self.msPerChar)
    self.visibleChars = math.min(self.textLength, self.visibleChars + revealCount)
    self.revealedText = getTextPrefix(self.fullText, self.visibleChars)
end

function MessageManager:completeCurrentMessage()
    self.visibleChars = self.textLength
    self.revealedText = self.fullText
    self.elapsedMs = 0
end

function MessageManager:setErrorMessage(text, durationMs)
    self:completeCurrentMessage()
    self.errorText = text or ""
    self.errorTimerMs = durationMs or self.errorDurationMs
end

function MessageManager:getText()
    if self.speaker ~= "" then
        return self.speaker .. ": " .. self.revealedText
    end
    return self.revealedText
end

function MessageManager:isComplete()
    return self.visibleChars >= self.textLength
end

function MessageManager:hasErrorMessage()
    return self.errorTimerMs > 0 and self.errorText ~= ""
end

function MessageManager:getErrorText()
    return self.errorText
end

return MessageManager
