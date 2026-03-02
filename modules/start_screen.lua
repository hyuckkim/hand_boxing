local StartScreen = {}
StartScreen.__index = StartScreen
local L = require("modules.localization")

function StartScreen.new(font, logoImage, options)
    options = options or {}

    return setmetatable({
        font = font,
        countdownFont = options.countdownFont or font,
        logoImage = logoImage,
        buttonRect = {
            x = options.buttonX or 70,
            y = options.buttonY or 300,
            w = options.buttonW or 260,
            h = options.buttonH or 60,
        },
        stage1Rect = { x = 0, y = 0, w = 0, h = 0 },
        stage2Rect = { x = 0, y = 0, w = 0, h = 0 },
        stage3Rect = { x = 0, y = 0, w = 0, h = 0 },
        stage1Enabled = false,
        stage2Enabled = false,
        stage3Enabled = false,
        stageRecords = {
            [1] = nil,
            [2] = nil,
            [3] = nil,
        },
    }, StartScreen)
end

function StartScreen:reset()
    self.stage1Enabled = false
    self.stage2Enabled = false
    self.stage3Enabled = false
end

function StartScreen:pointInRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

function StartScreen:updateLayout(width, height)
    self.width = width
    self.height = height

    local stageY = self.buttonRect.y + self.buttonRect.h + 18
    local stageW = 70
    local stageH = 46
    local gap = 12
    local startX = self.buttonRect.x + math.floor((self.buttonRect.w - (stageW * 3 + gap * 2)) / 2)

    self.stage1Rect = { x = startX, y = stageY, w = stageW, h = stageH }
    self.stage2Rect = { x = startX + stageW + gap, y = stageY, w = stageW, h = stageH }
    self.stage3Rect = { x = startX + (stageW + gap) * 2, y = stageY, w = stageW, h = stageH }
end

function StartScreen:setStageAvailability(stage1Enabled, stage2Enabled, stage3Enabled)
    self.stage1Enabled = stage1Enabled == true
    self.stage2Enabled = stage2Enabled == true
    self.stage3Enabled = stage3Enabled == true
end

function StartScreen:setStageRecords(records)
    self.stageRecords[1] = records and records[1] or nil
    self.stageRecords[2] = records and records[2] or nil
    self.stageRecords[3] = records and records[3] or nil
end

function StartScreen:onMouseDown(button, mouseId, mouseX, mouseY)
    if button ~= 0 then
        return nil
    end

    if self:pointInRect(mouseX, mouseY, self.buttonRect) then
        return "start_check"
    end

    if self.stage1Enabled and self:pointInRect(mouseX, mouseY, self.stage1Rect) then
        return "start_stage1"
    end
    if self.stage2Enabled and self:pointInRect(mouseX, mouseY, self.stage2Rect) then
        return "start_stage2"
    end
    if self.stage3Enabled and self:pointInRect(mouseX, mouseY, self.stage3Rect) then
        return "start_stage3"
    end

    return nil
end

local function drawStageButton(font, rect, label, enabled, hover)
    if enabled then
        if hover then
            g.color(0.35, 0.38, 0.35)
        else
            g.color(0.24, 0.27, 0.24)
        end
    else
        g.color(0.17, 0.17, 0.17)
    end
    g.rect(rect.x, rect.y, rect.w, rect.h, true)

    if enabled then
        g.color(0.95, 0.95, 0.95)
    else
        g.color(0.45, 0.45, 0.45)
    end
    g.text(font, label, rect.x + 28, rect.y + 9)
end

local function drawStageRecord(font, rect, record)
    g.color(0.75, 0.75, 0.75)
    if record ~= nil then
        g.text(font, L.t("ui.start.stage_record_format", { count = tostring(record) }), rect.x + 4, rect.y + rect.h + 6)
    end
end

function StartScreen:draw(width, height)
    self:updateLayout(width, height)

    g.color(0.08, 0.08, 0.08)
    g.rect(0, 0, width, height, true)

    if self.logoImage and self.logoImage >= 0 then
        local logoW = 420
        local logoH = 180
        local logoX = math.floor((width - logoW) / 2)
        local logoY = math.floor(height * 0.14)
        g.color(1, 1, 1)
        g.image(self.logoImage, logoX, logoY, logoW, logoH)
    else
        g.color(1, 1, 1)
        g.text(self.countdownFont, L.t("ui.start.title"), math.floor(width * 0.33), math.floor(height * 0.22))
    end

    local mx, my = is.mouse()
    local hover = self:pointInRect(mx, my, self.buttonRect)

    if hover then
        g.color(0.36, 0.36, 0.36)
    else
        g.color(0.25, 0.25, 0.25)
    end
    g.rect(self.buttonRect.x, self.buttonRect.y, self.buttonRect.w, self.buttonRect.h, true)

    g.color(1, 1, 1)
    g.text(self.font, L.t("ui.start.button"), self.buttonRect.x + 100, self.buttonRect.y + 15)

    local h1 = self:pointInRect(mx, my, self.stage1Rect)
    local h2 = self:pointInRect(mx, my, self.stage2Rect)
    local h3 = self:pointInRect(mx, my, self.stage3Rect)
    drawStageButton(self.font, self.stage1Rect, "1", self.stage1Enabled, h1)
    drawStageButton(self.font, self.stage2Rect, "2", self.stage2Enabled, h2)
    drawStageButton(self.font, self.stage3Rect, "3", self.stage3Enabled, h3)
    drawStageRecord(self.font, self.stage1Rect, self.stageRecords[1])
    drawStageRecord(self.font, self.stage2Rect, self.stageRecords[2])
    drawStageRecord(self.font, self.stage3Rect, self.stageRecords[3])

    g.color("#cccccc")
end

return StartScreen
