local ParticleSystem = require("modules.particle_system")

local BattleFeedback = {}
BattleFeedback.__index = BattleFeedback

local DUST_DISPERSAL_MULTIPLIER = 5
local SCREEN_SHAKE_DURATION_MS_BASE = 90
local SCREEN_SHAKE_DURATION_MS_STEP = 25
local SCREEN_SHAKE_INTENSITY_BASE = 3
local SCREEN_SHAKE_INTENSITY_STEP = 2
local SCREEN_SHAKE_MAX_OFFSET = 16
local DUST_BACKWARD_WEIGHT = 0.75
local DUST_DIRECTION_WEIGHT = 0.25
local DUAL_HIT_COMBO_WINDOW_MS = 180
local FLOATING_TEXT_LIFE_MS = 650
local FLOATING_TEXT_RISE_PX = 46
local FLOATING_TEXT_MAX_COUNT = 10

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

local function getDustAngleDeg(hit)
    local backwardX = 1
    if hit and hit.side == "right" then
        backwardX = -1
    end
    local backwardY = -0.25

    local dirX = 0
    local dirY = 0
    if hit and hit.dirX and hit.dirY then
        dirX = hit.dirX
        dirY = hit.dirY
    end

    local vx = backwardX * DUST_BACKWARD_WEIGHT + dirX * DUST_DIRECTION_WEIGHT
    local vy = backwardY * DUST_BACKWARD_WEIGHT + dirY * DUST_DIRECTION_WEIGHT

    if vx * backwardX < 0 then
        vx = backwardX * 0.2
    end

    return math.deg(safeAtan2(vy, vx))
end

function BattleFeedback.new()
    return setmetatable({
        hitCount = 0,
        floatingTexts = {},
        elapsedMs = 0,
        lastHitSide = nil,
        lastHitTimeMs = -100000,
        lastHitLevel = 0,
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
    self.floatingTexts = {}
    self.elapsedMs = 0
    self.lastHitSide = nil
    self.lastHitTimeMs = -100000
    self.lastHitLevel = 0
    self.screenShakeTimerMs = 0
    self.screenShakeIntensity = 0
    self.screenShakeX = 0
    self.screenShakeY = 0
    self.particleSystem:clear()
end

function BattleFeedback:addFloatingHitText(text, level)
    local levelScale = math.max(1, math.min(3, level or 1))
    local baseY = 112
    local laneOffset = (#self.floatingTexts % 3) * 20
    local randomX = (math.random() * 2 - 1) * 60

    self.floatingTexts[#self.floatingTexts + 1] = {
        text = text,
        ageMs = 0,
        lifeMs = FLOATING_TEXT_LIFE_MS + (levelScale - 1) * 70,
        startX = randomX,
        startY = baseY + laneOffset,
        risePx = FLOATING_TEXT_RISE_PX + (levelScale - 1) * 8,
    }

    while #self.floatingTexts > FLOATING_TEXT_MAX_COUNT do
        table.remove(self.floatingTexts, 1)
    end
end

function BattleFeedback:getTechniqueDisplayName(hit)
    local baseName = tostring(hit.techniqueName or "스트레이트")
    local side = hit.side
    local now = self.elapsedMs

    if side and self.lastHitSide and side ~= self.lastHitSide then
        local delta = now - self.lastHitTimeMs
        if delta <= DUAL_HIT_COMBO_WINDOW_MS then
            local peakLevel = math.max(hit.level or 1, self.lastHitLevel or 1)
            if peakLevel >= 3 then
                return "더블 임팩트"
            end
            if peakLevel >= 2 then
                return "원투 러시"
            end
            return "원투 콤보"
        end
    end

    return baseName
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
    local angleDeg = getDustAngleDeg(hit)

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
    local displayName = self:getTechniqueDisplayName(hit)
    self:addFloatingHitText("HIT! " .. displayName .. " L" .. tostring(hit.level) .. " (" .. hit.side .. ")", hit.level)

    self.lastHitSide = hit.side
    self.lastHitLevel = hit.level or 1
    self.lastHitTimeMs = self.elapsedMs

    self:spawnSandbagDust(targetRect, hit)
    self:addScreenShake(hit.level)
end

function BattleFeedback:update(dtMs)
    self.elapsedMs = self.elapsedMs + dtMs
    self.particleSystem:update(dtMs)
    self:updateScreenShake(dtMs)

    for i = #self.floatingTexts, 1, -1 do
        local item = self.floatingTexts[i]
        item.ageMs = item.ageMs + dtMs
        if item.ageMs >= item.lifeMs then
            table.remove(self.floatingTexts, i)
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

    local baseX = math.floor(width * 0.43)
    for _, item in ipairs(self.floatingTexts) do
        local t = math.min(1, item.ageMs / item.lifeMs)
        local y = item.startY - (item.risePx * t)
        local alpha = 1 - t
        g.color(1, 0.85, 0.4, alpha)
        g.text(font, item.text, baseX + item.startX, y)
    end
end

return BattleFeedback
