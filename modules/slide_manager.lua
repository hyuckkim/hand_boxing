local SlideManager = {}
SlideManager.__index = SlideManager

local function easeOutCubic(t)
    local inv = 1 - t
    return 1 - (inv * inv * inv)
end

local function applyEasing(t, easing)
    if easing == "ease_out_cubic" then
        return easeOutCubic(t)
    end
    return t
end

function SlideManager.new()
    return setmetatable({
        objects = {},
    }, SlideManager)
end

function SlideManager:clear()
    self.objects = {}
end

function SlideManager:registerOrUpdate(name, config)
    local object = self.objects[name]
    if not object then
        object = {
            name = name,
            visible = false,
            state = "hidden",
            x = 0,
            y = 0,
            width = 0,
            height = 0,
            imageId = -1,
        }
        self.objects[name] = object
    end

    object.imageId = config.imageId or object.imageId
    object.width = config.width or object.width
    object.height = config.height or object.height
    object.x = config.x or object.x
    object.y = config.y or object.y

    if config.visible ~= nil then
        object.visible = config.visible
    end
end

function SlideManager:getObjectState(name)
    return self.objects[name]
end

function SlideManager:startEnter(name, config)
    local object = self.objects[name]
    if not object then
        return
    end

    object.startX = config.startX
    object.startY = config.startY
    object.targetX = config.targetX
    object.targetY = config.targetY
    object.durationMs = config.durationMs or 500
    object.elapsedMs = 0
    object.easing = config.easing or "linear"
    object.keepVisible = (config.keepVisible ~= false)
    object.visible = true
    object.state = "enter"
    object.x = object.startX
    object.y = object.startY
end

function SlideManager:startExit(name, config)
    local object = self.objects[name]
    if not object then
        return
    end

    object.startX = object.x
    object.startY = object.y
    object.targetX = config.targetX
    object.targetY = config.targetY
    object.durationMs = config.durationMs or 500
    object.elapsedMs = 0
    object.easing = config.easing or "linear"
    object.hideOnComplete = (config.hideOnComplete ~= false)
    object.visible = true
    object.state = "exit"
end

function SlideManager:update(dtMs)
    for _, object in pairs(self.objects) do
        if object.state == "enter" or object.state == "exit" then
            object.elapsedMs = object.elapsedMs + dtMs
            local t = 1
            if object.durationMs > 0 then
                t = math.min(1, object.elapsedMs / object.durationMs)
            end
            local eased = applyEasing(t, object.easing)

            object.x = object.startX + (object.targetX - object.startX) * eased
            object.y = object.startY + (object.targetY - object.startY) * eased

            if t >= 1 then
                if object.state == "enter" then
                    object.state = object.keepVisible and "shown" or "hidden"
                    object.visible = object.keepVisible
                else
                    object.state = object.hideOnComplete and "hidden" or "shown"
                    object.visible = not object.hideOnComplete
                end
            end
        end
    end
end

function SlideManager:draw()
    for _, object in pairs(self.objects) do
        if object.visible and object.imageId and object.imageId >= 0 then
            g.color(1, 1, 1)
            g.image(object.imageId, object.x, object.y, object.width, object.height)
        end
    end
end

return SlideManager
