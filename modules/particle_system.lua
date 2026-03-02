local ParticleSystem = {}
ParticleSystem.__index = ParticleSystem

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function randRange(minValue, maxValue)
    return minValue + (maxValue - minValue) * math.random()
end

function ParticleSystem.new(options)
    options = options or {}

    return setmetatable({
        particles = {},
        maxParticles = options.maxParticles or 600,
        gravity = options.gravity or 560,
        defaultShape = options.defaultShape or "circle",
    }, ParticleSystem)
end

function ParticleSystem:clear()
    self.particles = {}
end

function ParticleSystem:update(dtMs)
    local dt = dtMs / 1000
    if dt <= 0 then
        return
    end

    for i = #self.particles, 1, -1 do
        local particle = self.particles[i]
        particle.age = particle.age + dtMs

        if particle.age >= particle.lifeMs then
            table.remove(self.particles, i)
        else
            local gravity = particle.gravity
            if gravity == nil then
                gravity = self.gravity
            end

            particle.vx = particle.vx + particle.ax * dt
            particle.vy = particle.vy + (particle.ay + gravity) * dt

            if particle.drag > 0 then
                local dragFactor = math.max(0, 1 - particle.drag * dt)
                particle.vx = particle.vx * dragFactor
                particle.vy = particle.vy * dragFactor
            end

            particle.x = particle.x + particle.vx * dt
            particle.y = particle.y + particle.vy * dt
        end
    end
end

function ParticleSystem:draw()
    for _, particle in ipairs(self.particles) do
        local t = clamp(particle.age / particle.lifeMs, 0, 1)
        local size = lerp(particle.startSize, particle.endSize, t)
        local alpha = lerp(particle.startAlpha, particle.endAlpha, t)

        g.color(particle.r, particle.g, particle.b, alpha)

        if particle.shape == "rect" then
            g.rect(particle.x - size * 0.5, particle.y - size * 0.5, size, size, true)
        else
            g.circle(particle.x, particle.y, math.max(1, size * 0.5), true)
        end
    end
end

function ParticleSystem:emitBurst(config)
    config = config or {}

    local count = config.count or 10
    local x = config.x or 0
    local y = config.y or 0
    local angleDeg = config.angleDeg or -90
    local spreadDeg = config.spreadDeg or 80
    local minSpeed = config.minSpeed or 120
    local maxSpeed = config.maxSpeed or 260
    local minLifeMs = config.minLifeMs or 200
    local maxLifeMs = config.maxLifeMs or 420
    local minSize = config.minSize or 4
    local maxSize = config.maxSize or 10
    local endSizeScale = config.endSizeScale or 1.5

    local color = config.color or { r = 0.72, g = 0.67, b = 0.57 }
    local colorJitter = config.colorJitter or 0.08

    local ax = config.ax or 0
    local ay = config.ay or 0
    local drag = config.drag or 0
    local startAlpha = config.startAlpha or 0.9
    local endAlpha = config.endAlpha or 0
    local shape = config.shape or self.defaultShape

    for _ = 1, count do
        if #self.particles >= self.maxParticles then
            break
        end

        local particleAngleDeg = angleDeg + randRange(-spreadDeg * 0.5, spreadDeg * 0.5)
        local particleAngle = math.rad(particleAngleDeg)
        local speed = randRange(minSpeed, maxSpeed)

        local r = clamp(color.r + randRange(-colorJitter, colorJitter), 0, 1)
        local gVal = clamp(color.g + randRange(-colorJitter, colorJitter), 0, 1)
        local b = clamp(color.b + randRange(-colorJitter, colorJitter), 0, 1)

        local startSize = randRange(minSize, maxSize)

        self.particles[#self.particles + 1] = {
            x = x + randRange(-2, 2),
            y = y + randRange(-2, 2),
            vx = math.cos(particleAngle) * speed,
            vy = math.sin(particleAngle) * speed,
            ax = ax,
            ay = ay,
            gravity = config.gravity,
            drag = drag,
            lifeMs = randRange(minLifeMs, maxLifeMs),
            age = 0,
            startSize = startSize,
            endSize = startSize * endSizeScale,
            startAlpha = startAlpha,
            endAlpha = endAlpha,
            r = r,
            g = gVal,
            b = b,
            shape = shape,
        }
    end
end

return ParticleSystem
