local PhaseActionRunner = {}
PhaseActionRunner.__index = PhaseActionRunner

function PhaseActionRunner.new(slideManager, actors, getPlaySize)
    return setmetatable({
        slideManager = slideManager,
        actors = actors,
        getPlaySize = getPlaySize,
    }, PhaseActionRunner)
end

function PhaseActionRunner:ensureActorObject(name)
    local actor = self.actors[name]
    if not actor then
        return nil, nil
    end

    local objectState = self.slideManager:getObjectState(name)
    if not objectState then
        local width, height = self.getPlaySize()
        local defaultX = math.floor((width - actor.w) / 2)
        local defaultY = math.floor((height - actor.h) / 2)
        self.slideManager:registerOrUpdate(name, {
            imageId = actor.img,
            width = actor.w,
            height = actor.h,
            x = defaultX,
            y = defaultY,
            zIndex = actor.zIndex,
            visible = false,
        })
        objectState = self.slideManager:getObjectState(name)
    else
        self.slideManager:registerOrUpdate(name, {
            imageId = actor.img,
            width = actor.w,
            height = actor.h,
            zIndex = actor.zIndex,
        })
    end

    return actor, objectState
end

function PhaseActionRunner:resolveAxis(spec, axis, actor, objectState)
    if not spec then
        if axis == "x" then
            return objectState and objectState.x or 0
        end
        return objectState and objectState.y or 0
    end

    local directValue = axis == "x" and spec.x or spec.y
    if directValue ~= nil then
        return directValue
    end

    local anchor = axis == "x" and spec.xAnchor or spec.yAnchor
    local offset = axis == "x" and (spec.xOffset or 0) or (spec.yOffset or 0)
    local width, height = self.getPlaySize()
    local base = 0

    if axis == "x" then
        if anchor == "left" then
            base = 0
        elseif anchor == "center" then
            base = math.floor((width - actor.w) / 2)
        elseif anchor == "right" then
            base = width - actor.w
        elseif anchor == "leftOutside" then
            base = -actor.w
        elseif anchor == "rightOutside" then
            base = width
        elseif anchor == "current" and objectState then
            base = objectState.x
        elseif objectState then
            base = objectState.x
        end
    else
        if anchor == "top" then
            base = 0
        elseif anchor == "center" then
            base = math.floor((height - actor.h) / 2)
        elseif anchor == "bottom" then
            base = height - actor.h
        elseif anchor == "topOutside" then
            base = -actor.h
        elseif anchor == "bottomOutside" then
            base = height
        elseif anchor == "current" and objectState then
            base = objectState.y
        elseif objectState then
            base = objectState.y
        end
    end

    return base + offset
end

function PhaseActionRunner:executeSlideAction(action)
    if not action or action.type ~= "slide" then
        return
    end

    local actor, objectState = self:ensureActorObject(action.object)
    if not actor then
        return
    end

    local toX = self:resolveAxis(action.to, "x", actor, objectState)
    local toY = self:resolveAxis(action.to, "y", actor, objectState)
    local durationMs = action.durationMs or actor.enterDurationMs or 500
    local easing = action.easing or "linear"

    if action.mode == "enter" then
        local fromX = self:resolveAxis(action.from, "x", actor, objectState)
        local fromY = self:resolveAxis(action.from, "y", actor, objectState)
        self.slideManager:startEnter(action.object, {
            startX = fromX,
            startY = fromY,
            targetX = toX,
            targetY = toY,
            durationMs = durationMs,
            easing = easing,
            keepVisible = (action.keepVisible ~= false),
        })
        return
    end

    if action.mode == "move" or action.mode == "exit" then
        if action.from then
            local fromX = self:resolveAxis(action.from, "x", actor, objectState)
            local fromY = self:resolveAxis(action.from, "y", actor, objectState)
            self.slideManager:registerOrUpdate(action.object, {
                x = fromX,
                y = fromY,
                visible = true,
            })
        end

        self.slideManager:startExit(action.object, {
            targetX = toX,
            targetY = toY,
            durationMs = durationMs,
            easing = easing,
            hideOnComplete = (action.mode == "exit") and (action.hideOnComplete ~= false) or false,
        })
    end
end

function PhaseActionRunner:runActions(actions)
    if not actions then
        return
    end

    for _, action in ipairs(actions) do
        self:executeSlideAction(action)
    end
end

function PhaseActionRunner:runPhaseEnterActions(phaseConfig)
    self:runActions(phaseConfig and phaseConfig.enterActions)
end

function PhaseActionRunner:runDialogueActions(phaseConfig, dialogueIndex)
    if not phaseConfig or not phaseConfig.dialogueActions then
        return
    end

    local actions = phaseConfig.dialogueActions[dialogueIndex]
    self:runActions(actions)
end

function PhaseActionRunner:bindHandManagerPhaseEvents(handManager)
    handManager:setPhaseEventHandler(function(eventType, _, phaseConfig, dialogueIndex)
        if eventType == "phase_enter" then
            self:runPhaseEnterActions(phaseConfig)
        elseif eventType == "dialogue_changed" then
            self:runDialogueActions(phaseConfig, dialogueIndex)
        end
    end)
end

return PhaseActionRunner
