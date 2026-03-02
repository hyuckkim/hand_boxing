local SandbagTarget = {}
SandbagTarget.__index = SandbagTarget

function SandbagTarget.new(slideManager, sandbagActor, debugDraw)
    return setmetatable({
        slideManager = slideManager,
        sandbagActor = sandbagActor,
        debugDraw = debugDraw == true,
    }, SandbagTarget)
end

function SandbagTarget:getWorldRect()
    local sandbagState = self.slideManager:getObjectState("sandbag")
    if not sandbagState or not sandbagState.visible or not self.sandbagActor.hitbox then
        return nil
    end

    local hb = self.sandbagActor.hitbox
    return {
        x = sandbagState.x + hb.x,
        y = sandbagState.y + hb.y,
        w = hb.w,
        h = hb.h,
    }
end

function SandbagTarget:drawDebugHitbox()
    if not self.debugDraw then
        return
    end

    local rect = self:getWorldRect()
    if not rect then
        return
    end

    g.color(0xff3333)
    g.rect(rect.x, rect.y, rect.w, rect.h, false)
end

return SandbagTarget
