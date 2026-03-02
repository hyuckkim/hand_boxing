local StartScreen = {}
StartScreen.__index = StartScreen
local L = require("modules.localization")

function StartScreen.new(font, logoImage, options)
    options = options or {}

    return setmetatable({
        font = font,
        logoImage = logoImage,
        buttonRect = {
            x = options.buttonX or 70,
            y = options.buttonY or 300,
            w = options.buttonW or 260,
            h = options.buttonH or 60,
        },
        confirmedMouseIds = {},
        mouseConfirmCount = 0,
    }, StartScreen)
end

function StartScreen:reset()
    self.confirmedMouseIds = {}
    self.mouseConfirmCount = 0
end

function StartScreen:pointInRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

function StartScreen:updateLayout(width, height)
    self.width = width
    self.height = height
end

function StartScreen:onMouseDown(button, mouseId, mouseX, mouseY)
    if button ~= 0 then
        return nil
    end

    if not self:pointInRect(mouseX, mouseY, self.buttonRect) then
        return nil
    end

    if self.confirmedMouseIds[mouseId] then
        return nil
    end

    self.mouseConfirmCount = self.mouseConfirmCount + 1
    self.confirmedMouseIds[mouseId] = true

    if self.mouseConfirmCount >= 2 then
        return "start"
    end

    return nil
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
        g.text(self.font, L.t("ui.start.title"), math.floor(width * 0.33), math.floor(height * 0.22))
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

    if self.mouseConfirmCount >= 1 then
        g.color(0.72, 0.92, 0.72)
        g.text(self.font, L.t("ui.start.mouse1_confirmed"), math.floor(width * 0.18), math.floor(height * 0.82))
    else
        g.color(0.5, 0.5, 0.5)
        g.text(self.font, "", math.floor(width * 0.18), math.floor(height * 0.82))
    end

    if self.mouseConfirmCount >= 2 then
        g.color(0.72, 0.92, 0.72)
        g.text(self.font, L.t("ui.start.mouse2_confirmed"), math.floor(width * 0.18), math.floor(height * 0.88))
    else
        g.color(0.5, 0.5, 0.5)
        g.text(self.font, "", math.floor(width * 0.18), math.floor(height * 0.88))
    end
    g.color("#cccccc")
    g.text(self.font, L.t("ui.start.need_two_mice"), 20, height - 40)
end

return StartScreen
