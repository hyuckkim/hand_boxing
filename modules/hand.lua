local Hand = {}
Hand.__index = Hand

local HAND_SPRITE_WIDTH = 400
local PUNCH_BASE_SPEED_THRESHOLD = 30
local PUNCH_TRIGGER_SPEED = PUNCH_BASE_SPEED_THRESHOLD * (2 / 3)
local PUNCH_LEVEL2_SPEED = PUNCH_BASE_SPEED_THRESHOLD
local PUNCH_LEVEL3_SPEED = PUNCH_BASE_SPEED_THRESHOLD * (4 / 3)
local PUNCH_DURATION_BY_LEVEL = {
    [1] = 120,
    [2] = 150,
    [3] = 180,
}
local PUNCH_FORWARD_OFFSET_BASE = 20
local PUNCH_FORWARD_OFFSET_STEP = 6
local IMPACT_STOP_MS_BASE = 38
local IMPACT_STOP_MS_STEP = 10
local IMPACT_RECOIL_X_BASE = 210
local IMPACT_RECOIL_X_STEP = 55
local IMPACT_RECOIL_Y_BASE = 45
local IMPACT_RECOIL_DAMPING_PER_SEC = 8
local IMPACT_INPUT_SCALE_DURING_STOP = 0.08
local TRAJECTORY_WINDOW_MS = 180
local TRAJECTORY_DECAY_PER_SEC = 6
local DEBUG_DRAW_HIT_RECT = true

local DEFAULT_HIT_RECT = {
    left = { x = 117, y = 159, w = 156, h = 131 },
    right = { x = 126, y = 162, w = 155, h = 128 },
}

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function classifyTechnique(dx, dy)
    local absX = math.abs(dx)
    local absY = math.abs(dy)

    if absX < 2 and absY < 2 then
        return {
            id = "straight",
            name = "스트레이트",
            dirX = 1,
            dirY = 0,
        }
    end

    if absX > absY * 1.35 then
        if dx >= 0 then
            return {
                id = "straight",
                name = "스트레이트",
                dirX = 1,
                dirY = 0,
            }
        end
        return {
            id = "backfist",
            name = "백피스트",
            dirX = -1,
            dirY = 0,
        }
    end

    if absY > absX * 1.35 then
        if dy <= 0 then
            return {
                id = "uppercut",
                name = "어퍼컷",
                dirX = 0,
                dirY = -1,
            }
        end
        return {
            id = "hammer",
            name = "해머",
            dirX = 0,
            dirY = 1,
        }
    end

    if dx >= 0 and dy <= 0 then
        return {
            id = "rising_hook",
            name = "라이징 훅",
            dirX = 0.7,
            dirY = -0.7,
        }
    end

    if dx >= 0 and dy > 0 then
        return {
            id = "down_hook",
            name = "다운 훅",
            dirX = 0.7,
            dirY = 0.7,
        }
    end

    if dx < 0 and dy <= 0 then
        return {
            id = "pull_upper",
            name = "풀 어퍼",
            dirX = -0.7,
            dirY = -0.7,
        }
    end

    return {
        id = "pull_smash",
        name = "풀 스매시",
        dirX = -0.7,
        dirY = 0.7,
    }
end

function Hand.new(side)
    local baseRect = DEFAULT_HIT_RECT[side] or DEFAULT_HIT_RECT.left

    return setmetatable({
        side = side,
        x = 0,
        y = 0,
        thumb_left = false,
        thumb_right = false,
        punchTimerMs = 0,
        punchLevel = 0,
        lastPunchLevel = 0,
        punchConsumed = false,
        impactStopMs = 0,
        recoilVx = 0,
        recoilVy = 0,
        trajectoryDx = 0,
        trajectoryDy = 0,
        trajectoryLifeMs = 0,
        lastTechnique = {
            id = "straight",
            name = "스트레이트",
            dirX = 1,
            dirY = 0,
        },
        hitRect = {
            x = baseRect.x,
            y = baseRect.y,
            w = baseRect.w,
            h = baseRect.h,
        },
    }, Hand)
end

local function getPunchLevelFromSpeed(speed)
    if speed < PUNCH_TRIGGER_SPEED then
        return 0
    end
    if speed >= PUNCH_LEVEL3_SPEED then
        return 3
    end
    if speed >= PUNCH_LEVEL2_SPEED then
        return 2
    end
    return 1
end

function Hand:setHitRect(x, y, w, h)
    self.hitRect.x = x
    self.hitRect.y = y
    self.hitRect.w = w
    self.hitRect.h = h
end

function Hand:setPosition(x, y)
    self.x = x
    self.y = y
end

function Hand:update(dtMs, bounds)
    local dt = dtMs / 1000

    if self.punchTimerMs > 0 then
        self.punchTimerMs = math.max(0, self.punchTimerMs - dtMs)
        if self.punchTimerMs == 0 then
            self.punchLevel = 0
            self.punchConsumed = false
        end
    end

    if self.trajectoryLifeMs > 0 then
        self.trajectoryLifeMs = math.max(0, self.trajectoryLifeMs - dtMs)
        local decay = math.max(0, 1 - TRAJECTORY_DECAY_PER_SEC * dt)
        self.trajectoryDx = self.trajectoryDx * decay
        self.trajectoryDy = self.trajectoryDy * decay

        if self.trajectoryLifeMs == 0 then
            self.trajectoryDx = 0
            self.trajectoryDy = 0
        end
    end

    if self.impactStopMs > 0 then
        self.impactStopMs = math.max(0, self.impactStopMs - dtMs)
    end

    if self.recoilVx ~= 0 or self.recoilVy ~= 0 then
        self.x = self.x + self.recoilVx * dt
        self.y = self.y + self.recoilVy * dt

        local damp = math.max(0, 1 - IMPACT_RECOIL_DAMPING_PER_SEC * dt)
        self.recoilVx = self.recoilVx * damp
        self.recoilVy = self.recoilVy * damp

        if math.abs(self.recoilVx) < 2 then
            self.recoilVx = 0
        end
        if math.abs(self.recoilVy) < 2 then
            self.recoilVy = 0
        end

        if bounds then
            self.x = clamp(self.x, bounds.minX, bounds.maxX)
            self.y = clamp(self.y, bounds.minY, bounds.maxY)
        end
    end
end

function Hand:isPunching()
    return self.punchTimerMs > 0
end

function Hand:getPunchLevel()
    return self.punchLevel
end

function Hand:getLastPunchLevel()
    return self.lastPunchLevel
end

function Hand:getLastTechnique()
    return self.lastTechnique
end

function Hand:move(dx, dy, bounds, ownerId)
    if self.impactStopMs > 0 then
        dx = dx * IMPACT_INPUT_SCALE_DURING_STOP
        dy = dy * IMPACT_INPUT_SCALE_DURING_STOP
    end

    self.trajectoryDx = self.trajectoryDx + dx
    self.trajectoryDy = self.trajectoryDy + dy
    self.trajectoryLifeMs = TRAJECTORY_WINDOW_MS

    local speed = math.sqrt(dx * dx + dy * dy)
    local level = getPunchLevelFromSpeed(speed)
    if level > 0 then
        if self.punchLevel == 0 then
            self.punchLevel = level
            self.lastPunchLevel = level
            self.punchConsumed = false
            local directionalDx = self.trajectoryDx
            if self.side == "right" then
                directionalDx = -directionalDx
            end
            self.lastTechnique = classifyTechnique(directionalDx, self.trajectoryDy)
            self.trajectoryDx = 0
            self.trajectoryDy = 0
            self.trajectoryLifeMs = 0
            self.punchTimerMs = PUNCH_DURATION_BY_LEVEL[level]
            print("Punch L" .. level .. " detected for " .. self.side .. " hand (owner=" .. tostring(ownerId) .. ") with speed " .. speed .. " / technique=" .. self.lastTechnique.id)
        elseif level > self.punchLevel then
            self.punchLevel = level
            self.lastPunchLevel = level
            self.punchConsumed = false
            self.punchTimerMs = math.max(self.punchTimerMs, PUNCH_DURATION_BY_LEVEL[level])
            print("Punch upgraded to L" .. level .. " for " .. self.side .. " hand (owner=" .. tostring(ownerId) .. ") with speed " .. speed)
        end
    end

    local nextX = self.x + dx
    local nextY = self.y + dy

    if bounds then
        nextX = clamp(nextX, bounds.minX, bounds.maxX)
        nextY = clamp(nextY, bounds.minY, bounds.maxY)
    end

    self.x = nextX
    self.y = nextY
end

function Hand:onMouseDown(button)
    if self.side == "left" then
        if button == 1 then self.thumb_left = true end
        if button == 0 then self.thumb_right = true end
    else
        if button == 0 then self.thumb_left = true end
        if button == 1 then self.thumb_right = true end
    end
end

function Hand:onMouseUp(button)
    if self.side == "left" then
        if button == 1 then self.thumb_left = false end
        if button == 0 then self.thumb_right = false end
    else
        if button == 0 then self.thumb_left = false end
        if button == 1 then self.thumb_right = false end
    end
end

function Hand:getImage(images)
    if self.thumb_left and self.thumb_right then
        return images.both
    end
    if self.thumb_left then
        return images.left
    end
    if self.thumb_right then
        return images.right
    end
    return images.base
end

function Hand:getHitRect(drawX)
    local hx = drawX + self.hitRect.x

    return {
        x = hx,
        y = self.y + self.hitRect.y,
        w = self.hitRect.w,
        h = self.hitRect.h,
    }
end

function Hand:getDrawX()
    local drawX = self.x
    if self:isPunching() then
        local punchForwardOffset = PUNCH_FORWARD_OFFSET_BASE + (self.punchLevel - 1) * PUNCH_FORWARD_OFFSET_STEP
        if self.side == "right" then
            drawX = drawX - punchForwardOffset
        else
            drawX = drawX + punchForwardOffset
        end
    end
    return drawX
end

function Hand:getWorldHitRect()
    return self:getHitRect(self:getDrawX())
end

function Hand:canDealPunchHit()
    return self:isPunching() and not self.punchConsumed
end

function Hand:consumePunchHit()
    self.punchConsumed = true
end

function Hand:applyImpactFeedback(level)
    local hitLevel = math.max(1, math.min(3, level or 1))

    self.impactStopMs = math.max(self.impactStopMs, IMPACT_STOP_MS_BASE + (hitLevel - 1) * IMPACT_STOP_MS_STEP)

    local dir = -1
    if self.side == "right" then
        dir = 1
    end

    self.recoilVx = self.recoilVx + dir * (IMPACT_RECOIL_X_BASE + (hitLevel - 1) * IMPACT_RECOIL_X_STEP)
    self.recoilVy = self.recoilVy - IMPACT_RECOIL_Y_BASE
end

function Hand:draw(images)
    local targetImage = self:getImage(images)
    local drawX = self:getDrawX()
    if self:isPunching() then
        if self.punchLevel == 3 then
            g.color(1, 0.82, 0.82)
        elseif self.punchLevel == 2 then
            g.color(1, 0.88, 0.88)
        else
            g.color(1, 0.93, 0.93)
        end
    else
        g.color(1, 1, 1)
    end

    if self.side == "right" then
        g.push()
        g.translate(-drawX, self.y)
        g.scale(-1, 1, HAND_SPRITE_WIDTH / 2, HAND_SPRITE_WIDTH / 2)
        g.image(targetImage, 0, 0)
        g.pop()
    else
        g.image(targetImage, drawX, self.y)
    end

    if DEBUG_DRAW_HIT_RECT then
        local hit = self:getHitRect(drawX)
        g.color(0xff3333)
        g.rect(hit.x, hit.y, hit.w, hit.h, false)
    end
end

return Hand