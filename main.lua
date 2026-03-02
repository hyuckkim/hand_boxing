local HandManager = dofile("modules/hand_manager.lua")
local PauseMenu = dofile("modules/pause_menu.lua")
local StartScreen = dofile("modules/start_screen.lua")
local SlideManager = dofile("modules/slide_manager.lua")
local ParticleSystem = dofile("modules/particle_system.lua")

local font = res.fontFile("Shilla_Culture.ttf", "Shilla_Culture(M)", 24)
local countdownFont = res.fontFile("Shilla_Culture.ttf", "Shilla_Culture(M)", 88)
local logoImage = res.image("logo.png")
local DEBUG_DRAW_HITBOXES = true
local DUST_DISPERSAL_MULTIPLIER = 5
local actors = {
    coach = {
        img = res.image("coach.png"),
        w = 163,
        h = 328,
        enterDurationMs = 900,
    },
    sandbag = {
        img = res.image("sandbag.png"),
        w = 136,
        h = 328,
        enterDurationMs = 700,
        hitbox = {
            x = 48,
            y = 134,
            w = 40,
            h = 60,
        },
    },
}
local w, h
local scene = "start"
local START_FADE_DURATION_MS = 1000
local startFadeTimerMs = 0
local battleHitCount = 0
local battleHitText = ""
local battleHitTextTimerMs = 0
local handManager = HandManager.new()
local slideManager = SlideManager.new()
local particleSystem = ParticleSystem.new({
    maxParticles = 800,
    gravity = 620,
    defaultShape = "circle",
})
local pauseMenu = PauseMenu.new(font)
local startScreen = StartScreen.new(font, logoImage, {
    buttonX = 70,
    buttonY = 300,
    buttonW = 260,
    buttonH = 60,
})
local images = {
    base = res.image("1.png"),
    left = res.image("2.png"),
    right = res.image("3.png"),
    both = res.image("4.png"),
}

local function drawDebugHitboxes()
    if not DEBUG_DRAW_HITBOXES then
        return
    end

    local sandbagState = slideManager:getObjectState("sandbag")
    if sandbagState and sandbagState.visible and actors.sandbag.hitbox then
        local hb = actors.sandbag.hitbox
        g.color(0xff3333)
        g.rect(sandbagState.x + hb.x, sandbagState.y + hb.y, hb.w, hb.h, false)
    end
end

local function getSandbagHitboxWorldRect()
    local sandbagState = slideManager:getObjectState("sandbag")
    if not sandbagState or not sandbagState.visible or not actors.sandbag.hitbox then
        return nil
    end

    local hb = actors.sandbag.hitbox
    return {
        x = sandbagState.x + hb.x,
        y = sandbagState.y + hb.y,
        w = hb.w,
        h = hb.h,
    }
end

local function spawnSandbagDust(targetRect, hit)
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

    particleSystem:emitBurst({
        x = targetRect.x + targetRect.w * 0.5 + sideBias,
        y = targetRect.y + targetRect.h * 0.45,
        count = count,
        angleDeg = -90,
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

local function ensureActorObject(name)
    local actor = actors[name]
    if not actor then
        return nil, nil
    end

    local objectState = slideManager:getObjectState(name)
    if not objectState then
        local defaultX = math.floor((w - actor.w) / 2)
        local defaultY = math.floor((h - actor.h) / 2)
        slideManager:registerOrUpdate(name, {
            imageId = actor.img,
            width = actor.w,
            height = actor.h,
            x = defaultX,
            y = defaultY,
            visible = false,
        })
        objectState = slideManager:getObjectState(name)
    else
        slideManager:registerOrUpdate(name, {
            imageId = actor.img,
            width = actor.w,
            height = actor.h,
        })
    end

    return actor, objectState
end

local function resolveAxis(spec, axis, actor, objectState)
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
    local base = 0

    if axis == "x" then
        if anchor == "left" then
            base = 0
        elseif anchor == "center" then
            base = math.floor((w - actor.w) / 2)
        elseif anchor == "right" then
            base = w - actor.w
        elseif anchor == "leftOutside" then
            base = -actor.w
        elseif anchor == "rightOutside" then
            base = w
        elseif anchor == "current" and objectState then
            base = objectState.x
        elseif objectState then
            base = objectState.x
        end
    else
        if anchor == "top" then
            base = 0
        elseif anchor == "center" then
            base = math.floor((h - actor.h) / 2)
        elseif anchor == "bottom" then
            base = h - actor.h
        elseif anchor == "topOutside" then
            base = -actor.h
        elseif anchor == "bottomOutside" then
            base = h
        elseif anchor == "current" and objectState then
            base = objectState.y
        elseif objectState then
            base = objectState.y
        end
    end

    return base + offset
end

local function executeSlideAction(action)
    if not action or action.type ~= "slide" then
        return
    end

    local actor, objectState = ensureActorObject(action.object)
    if not actor then
        return
    end

    local toX = resolveAxis(action.to, "x", actor, objectState)
    local toY = resolveAxis(action.to, "y", actor, objectState)
    local durationMs = action.durationMs or actor.enterDurationMs or 500
    local easing = action.easing or "linear"

    if action.mode == "enter" then
        local fromX = resolveAxis(action.from, "x", actor, objectState)
        local fromY = resolveAxis(action.from, "y", actor, objectState)
        slideManager:startEnter(action.object, {
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
            local fromX = resolveAxis(action.from, "x", actor, objectState)
            local fromY = resolveAxis(action.from, "y", actor, objectState)
            slideManager:registerOrUpdate(action.object, {
                x = fromX,
                y = fromY,
                visible = true,
            })
        end

        slideManager:startExit(action.object, {
            targetX = toX,
            targetY = toY,
            durationMs = durationMs,
            easing = easing,
            hideOnComplete = (action.mode == "exit") and (action.hideOnComplete ~= false) or false,
        })
    end
end

local function runActions(actions)
    if not actions then
        return
    end

    for _, action in ipairs(actions) do
        executeSlideAction(action)
    end
end

local function runPhaseEnterActions(phaseConfig)
    runActions(phaseConfig and phaseConfig.enterActions)
end

local function runDialogueActions(phaseConfig, dialogueIndex)
    if not phaseConfig or not phaseConfig.dialogueActions then
        return
    end

    local actions = phaseConfig.dialogueActions[dialogueIndex]
    runActions(actions)
end

local function bindHandManagerPhaseEvents(manager)
    manager:setPhaseEventHandler(function(eventType, phaseName, phaseConfig, dialogueIndex)
        if eventType == "phase_enter" then
            runPhaseEnterActions(phaseConfig)
        elseif eventType == "dialogue_changed" then
            runDialogueActions(phaseConfig, dialogueIndex)
        end
    end)
end

local function enterStartScene()
    scene = "start"
    startFadeTimerMs = 0
    startScreen:reset()
    sys.clip(false)
    sys.showCursor(true)
end

local function beginStartTransition()
    scene = "start_fade"
    startFadeTimerMs = 0
    sys.clip(false)
    sys.showCursor(true)
end

local function enterGameScene()
    scene = "game"
    battleHitCount = 0
    battleHitText = ""
    battleHitTextTimerMs = 0
    particleSystem:clear()
    handManager = HandManager.new()
    bindHandManagerPhaseEvents(handManager)
    handManager:setPlayArea(w, h)
    handManager:beginHandEntryAnimation()
    handManager:emitPhaseEnter()
    pauseMenu:setPaused(false)
end

function Init()
    w, h = is.size()
    handManager:setPlayArea(w, h)
    pauseMenu:updateLayout(w, h)
    startScreen:updateLayout(w, h)
    enterStartScene()
end

function Update(dtMs)
    if scene == "start" then
        return
    end

    if scene == "start_fade" then
        startFadeTimerMs = startFadeTimerMs + dtMs
        if startFadeTimerMs >= START_FADE_DURATION_MS then
            enterGameScene()
        end
        return
    end

    if pauseMenu:isPaused() then
        return
    end

    slideManager:update(dtMs)
    particleSystem:update(dtMs)

    handManager:update(dtMs)

    if battleHitTextTimerMs > 0 then
        battleHitTextTimerMs = math.max(0, battleHitTextTimerMs - dtMs)
        if battleHitTextTimerMs == 0 then
            battleHitText = ""
        end
    end

    if handManager:getCurrentMode() == "battle" then
        local targetRect = getSandbagHitboxWorldRect()
        local hit = handManager:tryConsumeBattlePunchHit(targetRect)
        if hit then
            battleHitCount = battleHitCount + 1
            battleHitText = "HIT! L" .. tostring(hit.level) .. " (" .. hit.side .. ")"
            battleHitTextTimerMs = 400
            spawnSandbagDust(targetRect, hit)
        end
    end
end

function Draw()
    w, h = is.size()
    handManager:setPlayArea(w, h)
    pauseMenu:updateLayout(w, h)
    startScreen:updateLayout(w, h)

    if scene == "start" or scene == "start_fade" then
        startScreen:draw(w, h)

        if scene == "start_fade" then
            local alpha = math.min(1, startFadeTimerMs / START_FADE_DURATION_MS)
            g.color(0, 0, 0, alpha)
            g.rect(0, 0, w, h, true)
        end
        return
    end

    g.color(0, 0, 0)
    g.rect(0, 0, w, h)

    particleSystem:draw()
    slideManager:draw()
    drawDebugHitboxes()
    handManager:draw(font, images, countdownFont)

    if handManager:getCurrentMode() == "battle" then
        g.color(1, 1, 1)
        g.text(font, "Hits: " .. tostring(battleHitCount), 20, h - 44)
        if battleHitText ~= "" then
            g.color(1, 0.85, 0.4)
            g.text(font, battleHitText, math.floor(w * 0.43), math.floor(h * 0.16))
        end
    end

    if pauseMenu:isPaused() then
        pauseMenu:draw(w, h)
    end
end

function CheckHit(x, y)
    return true
end

function OnMouseDown(btn, id)
    if scene == "start" then
        local mx, my = is.mouse()
        local action = startScreen:onMouseDown(btn, id, mx, my)
        if action == "start" then
            beginStartTransition()
        end
        return
    end

    if scene == "start_fade" then
        return
    end

    if pauseMenu:isPaused() then
        local mx, my = is.mouse()
        local action = pauseMenu:onMouseDown(btn, mx, my)
        if action == "main_menu" then
            enterStartScene()
            return
        end
        if action == "quit" then
            sys.quit()
        end
        return
    end

    handManager:onMouseDown(btn, id)
end

function OnMouseMove(id, dx, dy)
    if scene == "start" or scene == "start_fade" then return end
    if pauseMenu:isPaused() then return end
    handManager:onMouseMove(id, dx, dy)
end

function OnKeyDown(key)
    if scene == "start" or scene == "start_fade" then
        if key == 0x1B then -- ESC
            sys.quit()
        end
        return
    end

    if key == 0x1B then -- ESC
        pauseMenu:toggle()
    end

    if pauseMenu:isPaused() then
        local action = pauseMenu:onKeyDown(key)
        if action == "main_menu" then
            enterStartScene()
            return
        end
        if action == "quit" then
            sys.quit()
        end
        return
    end
end

function OnMouseUp(btn, id)
    if scene == "start" then return end
    if pauseMenu:isPaused() then return end
    handManager:onMouseUp(btn, id)
end
