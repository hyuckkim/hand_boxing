local ParticleSystem = require("modules.particle_system")

local BattleFeedback = {}
BattleFeedback.__index = BattleFeedback

local DUST_DISPERSAL_MULTIPLIER = 5
local SCREEN_SHAKE_DURATION_MS_BASE = 90
local SCREEN_SHAKE_DURATION_MS_STEP = 25
local SCREEN_SHAKE_INTENSITY_BASE = 3
local SCREEN_SHAKE_INTENSITY_STEP = 2
local SCREEN_SHAKE_MAX_OFFSET = 16

local function safeAtan2(y, x)
    if x == 0 then
        if y > 0 then
            return math.pi * 0.5
        elseif y < 0 then
            return -math.pi * 0.5
        end
        return 0
    end

    local angle = math.atan(y / x)
    if x < 0 then
        if y >= 0 then
            angle = angle + math.pi
        else
            angle = angle - math.pi
        end
    end
    return angle
end

function BattleFeedback.new()
    return setmetatable({
        hitCount = 0,
        hitText = "",
        hitTextTimerMs = 0,
        screenShakeTimerMs = 0,
        screenShakeIntensity = 0,
        screenShakeX = 0,
        screenShakeY = 0,
        particleSystem = ParticleSystem.new({
            maxParticles = 800,
            gravity = 620,
            defaultShape = "circle",
        }),
    }, BattleFeedback)
end

function BattleFeedback:reset()
    self.hitCount = 0
    self.hitText = ""
    self.hitTextTimerMs = 0
    self.screenShakeTimerMs = 0
    self.screenShakeIntensity = 0
    self.screenShakeX = 0
    self.screenShakeY = 0
    self.particleSystem:clear()
end

function BattleFeedback:addScreenShake(level)
    local power = math.max(1, math.min(3, level or 1))
    local duration = SCREEN_SHAKE_DURATION_MS_BASE + (power - 1) * SCREEN_SHAKE_DURATION_MS_STEP
    local intensity = SCREEN_SHAKE_INTENSITY_BASE + (power - 1) * SCREEN_SHAKE_INTENSITY_STEP

    self.screenShakeTimerMs = math.max(self.screenShakeTimerMs, duration)
    self.screenShakeIntensity = math.min(SCREEN_SHAKE_MAX_OFFSET, self.screenShakeIntensity + intensity)
end

function BattleFeedback:updateScreenShake(dtMs)
    if self.screenShakeTimerMs <= 0 then
        self.screenShakeTimerMs = 0
        self.screenShakeIntensity = 0
        self.screenShakeX = 0
        self.screenShakeY = 0
        return
    end

    self.screenShakeTimerMs = math.max(0, self.screenShakeTimerMs - dtMs)
    local decay = math.max(0, 1 - (dtMs / 120))
    self.screenShakeIntensity = self.screenShakeIntensity * decay

    if self.screenShakeTimerMs > 0 and self.screenShakeIntensity > 0.1 then
        self.screenShakeX = (math.random() * 2 - 1) * self.screenShakeIntensity
        self.screenShakeY = (math.random() * 2 - 1) * self.screenShakeIntensity * 0.8
    else
        self.screenShakeX = 0
        self.screenShakeY = 0
    end
end

function BattleFeedback:spawnSandbagDust(targetRect, hit)
    if not targetRect then
        return
    end

    local power = 1
    if hit and hit.level then
        power = math.max(1, math.min(3, hit.level))
    end

    local sideBias = 0
    if hit and hit.side == "left" then
        sideBias = -18
    elseif hit and hit.side == "right" then
        sideBias = 18
    end

    local count = 9 + power * 4
    local speedScale = DUST_DISPERSAL_MULTIPLIER
    local angleDeg = -90
    if hit and hit.dirX and hit.dirY then
        angleDeg = math.deg(safeAtan2(hit.dirY, hit.dirX))
    end

    self.particleSystem:emitBurst({
        x = targetRect.x + targetRect.w * 0.5 + sideBias,
        y = targetRect.y + targetRect.h * 0.45,
        count = count,
        angleDeg = angleDeg,
        spreadDeg = 140,
        minSpeed = (90 + power * 24) * speedScale,
        maxSpeed = (190 + power * 35) * speedScale,
        minLifeMs = 500,
        maxLifeMs = 1100,
        minSize = 8,
        maxSize = 20 + power * 2,
        endSizeScale = 2.2,
        drag = 1.7,
        startAlpha = 0.72,
        endAlpha = 0,
        color = { r = 0.74, g = 0.70, b = 0.63 },
        colorJitter = 0.09,
    })
end

function BattleFeedback:onHit(targetRect, hit)
    self.hitCount = self.hitCount + 1
    self.hitText = "HIT! " .. tostring(hit.techniqueName or "스트레이트") .. " L" .. tostring(hit.level) .. " (" .. hit.side .. ")"
    self.hitTextTimerMs = 400

    self:spawnSandbagDust(targetRect, hit)
    self:addScreenShake(hit.level)
end

function BattleFeedback:update(dtMs)
    self.particleSystem:update(dtMs)
    self:updateScreenShake(dtMs)

    if self.hitTextTimerMs > 0 then
        self.hitTextTimerMs = math.max(0, self.hitTextTimerMs - dtMs)
        if self.hitTextTimerMs == 0 then
            self.hitText = ""
        end
    end
end

function BattleFeedback:beginWorldTransform()
    g.push()
    g.translate(self.screenShakeX, self.screenShakeY)
end

function BattleFeedback:endWorldTransform()
    g.pop()
end

function BattleFeedback:drawWorld()
    self.particleSystem:draw()
end

function BattleFeedback:drawHud(font, width, height)
    g.color(1, 1, 1)
    g.text(font, "Hits: " .. tostring(self.hitCount), 20, height - 44)

    if self.hitText ~= "" then
        g.color(1, 0.85, 0.4)
        g.text(font, self.hitText, math.floor(width * 0.43), math.floor(height * 0.16))
    end
end

return BattleFeedback
