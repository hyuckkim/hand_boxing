local HandManager = require("modules.hand_manager")
local BattleFeedback = require("modules.battle_feedback")
local PauseMenu = require("modules.pause_menu")
local StartScreen = require("modules.start_screen")
local SlideManager = require("modules.slide_manager")
local PhaseActionRunner = require("modules.phase_action_runner")
local SandbagTarget = require("modules.sandbag_target")

local font = res.fontFile("Shilla_Culture.ttf", "Shilla_Culture(M)", 24)
local countdownFont = res.fontFile("Shilla_Culture.ttf", "Shilla_Culture(M)", 88)
local logoImage = res.image("logo.png")
local DEBUG_DRAW_HITBOXES = true
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
local handManager = HandManager.new()
local slideManager = SlideManager.new()
local battleFeedback = BattleFeedback.new()
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
local phaseActionRunner = PhaseActionRunner.new(slideManager, actors, function()
    return w, h
end)
local sandbagTarget = SandbagTarget.new(slideManager, actors.sandbag, DEBUG_DRAW_HITBOXES)

local function enterStartScene()
    scene = "start"
    startFadeTimerMs = 0
    slideManager:clear()
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
    slideManager:clear()
    battleFeedback:reset()
    handManager = HandManager.new()
    phaseActionRunner:bindHandManagerPhaseEvents(handManager)
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
    battleFeedback:update(dtMs)

    handManager:update(dtMs)

    if handManager:getCurrentMode() == "battle" then
        local targetRect = sandbagTarget:getWorldRect()
        local hit = handManager:tryConsumeBattlePunchHit(targetRect)
        if hit then
            battleFeedback:onHit(targetRect, hit)
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

    battleFeedback:beginWorldTransform()
    battleFeedback:drawWorld()
    slideManager:draw()
    sandbagTarget:drawDebugHitbox()
    handManager:draw(font, images, countdownFont)

    if handManager:getCurrentMode() == "battle" then
        battleFeedback:drawHud(font, w, h)
    end

    battleFeedback:endWorldTransform()

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
