local PauseMenu = {}
PauseMenu.__index = PauseMenu
local L = require("modules.localization")

function PauseMenu.new(font)
    return setmetatable({
        font = font,
        paused = false,
        panelW = 360,
        panelH = 306,
        buttonW = 260,
        buttonH = 52,
        resumeRect = { x = 0, y = 0, w = 0, h = 0 },
        mainMenuRect = { x = 0, y = 0, w = 0, h = 0 },
        quitRect = { x = 0, y = 0, w = 0, h = 0 },
    }, PauseMenu)
end

function PauseMenu:setPaused(value)
    self.paused = value
    if self.paused then
        sys.clip(false)
        sys.showCursor(true)
    else
        sys.clip(true)
        sys.showCursor(false)
    end
end

function PauseMenu:toggle()
    self:setPaused(not self.paused)
end

function PauseMenu:isPaused()
    return self.paused
end

function PauseMenu:updateLayout(width, height)
    local panelX = math.floor((width - self.panelW) / 2)
    local panelY = math.floor((height - self.panelH) / 2)
    local buttonX = panelX + math.floor((self.panelW - self.buttonW) / 2)

    self.resumeRect = {
        x = buttonX,
        y = panelY + 86,
        w = self.buttonW,
        h = self.buttonH,
    }

    self.mainMenuRect = {
        x = buttonX,
        y = panelY + 152,
        w = self.buttonW,
        h = self.buttonH,
    }

    self.quitRect = {
        x = buttonX,
        y = panelY + 218,
        w = self.buttonW,
        h = self.buttonH,
    }
end

function PauseMenu:pointInRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

function PauseMenu:onMouseDown(button, mouseX, mouseY)
    if button ~= 0 then
        return nil
    end

    if self:pointInRect(mouseX, mouseY, self.resumeRect) then
        self:setPaused(false)
        return "resume"
    end

    if self:pointInRect(mouseX, mouseY, self.mainMenuRect) then
        self:setPaused(false)
        return "main_menu"
    end

    if self:pointInRect(mouseX, mouseY, self.quitRect) then
        return "quit"
    end

    return nil
end

function PauseMenu:onKeyDown(key)
    if key == 0x0D then
        self:setPaused(false)
        return "resume"
    end
    if key == 0x51 then
        return "quit"
    end
    return nil
end

function PauseMenu:draw(width, height)
    local panelX = math.floor((width - self.panelW) / 2)
    local panelY = math.floor((height - self.panelH) / 2)
    local mx, my = is.mouse()
    local resumeHover = self:pointInRect(mx, my, self.resumeRect)
    local mainMenuHover = self:pointInRect(mx, my, self.mainMenuRect)
    local quitHover = self:pointInRect(mx, my, self.quitRect)

    g.color(0, 0, 0, 0.55)
    g.rect(0, 0, width, height, true)

    g.color(0.15, 0.15, 0.15, 0.95)
    g.rect(panelX, panelY, self.panelW, self.panelH, true)

    g.color(1, 1, 1)
    g.text(self.font, L.t("ui.pause.title"), panelX + 124, panelY + 24)

    if resumeHover then
        g.color(0.36, 0.36, 0.36)
    else
        g.color(0.25, 0.25, 0.25)
    end
    g.rect(self.resumeRect.x, self.resumeRect.y, self.resumeRect.w, self.resumeRect.h, true)

    if mainMenuHover then
        g.color(0.32, 0.32, 0.4)
    else
        g.color(0.25, 0.25, 0.25)
    end
    g.rect(self.mainMenuRect.x, self.mainMenuRect.y, self.mainMenuRect.w, self.mainMenuRect.h, true)

    if quitHover then
        g.color(0.45, 0.24, 0.24)
    else
        g.color(0.25, 0.25, 0.25)
    end
    g.rect(self.quitRect.x, self.quitRect.y, self.quitRect.w, self.quitRect.h, true)

    g.color(1, 1, 1)
    g.text(self.font, L.t("ui.pause.resume"), self.resumeRect.x + 84, self.resumeRect.y + 13)
    g.text(self.font, L.t("ui.pause.main_menu"), self.mainMenuRect.x + 84, self.mainMenuRect.y + 13)
    g.text(self.font, L.t("ui.pause.quit"), self.quitRect.x + 84, self.quitRect.y + 13)
end

return PauseMenu
