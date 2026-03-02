local HandManager = require("modules.hand_manager")
local Hand = require("modules.hand")
local BattleFeedback = require("modules.battle_feedback")
local PauseMenu = require("modules.pause_menu")
local StartScreen = require("modules.start_screen")
local SlideManager = require("modules.slide_manager")
local PhaseActionRunner = require("modules.phase_action_runner")
local SandbagTarget = require("modules.sandbag_target")
local StageProgression = require("modules.stage_progression")
local L = require("modules.localization")
local NewOpponentSandbag = require("modules.scenes.new_opponent_sandbag")

local font = res.fontFile("솔뫼 김대건 Medium.ttf", "솔뫼 김대건 Medium", 24)
local countdownFont = res.fontFile("솔뫼 김대건 Medium.ttf", "솔뫼 김대건 Medium", 88)
local logoImage = res.image("logo.png")
local DEBUG_DRAW_HITBOXES = false
local getStageSetup = NewOpponentSandbag.getStageSetup or function()
    return nil
end
local defaultSetup = getStageSetup(1) or {}
local defaultStageConfig = defaultSetup.sandbag or {
    img = res.image("sandbag.png"),
    w = 136,
    h = 328,
    hitbox = { x = 48, y = 134, w = 40, h = 60 },
}
local defaultTophatConfig = (getStageSetup(3) or {}).tophat or {
    img = -1,
    w = 0,
    h = 0,
}
local actors = {
    coach = {
        img = res.image("coach.png"),
        w = 163,
        h = 328,
        enterDurationMs = 900,
        zIndex = 20,
    },
    sandbag = {
        img = defaultStageConfig.img,
        w = defaultStageConfig.w,
        h = defaultStageConfig.h,
        enterDurationMs = 700,
        zIndex = 10,
        hitbox = {
            x = defaultStageConfig.hitbox.x,
            y = defaultStageConfig.hitbox.y,
            w = defaultStageConfig.hitbox.w,
            h = defaultStageConfig.hitbox.h,
        },
    },
    tophat = {
        img = defaultTophatConfig.img,
        w = defaultTophatConfig.w,
        h = defaultTophatConfig.h,
        enterDurationMs = 240,
        zIndex = 30,
        offsetX = defaultTophatConfig.offsetX or 0,
        offsetY = defaultTophatConfig.offsetY or 0,
        flyInOffsetX = defaultTophatConfig.flyInOffsetX or 0,
        flyInOffsetY = defaultTophatConfig.flyInOffsetY or -120,
        flyInDurationMs = defaultTophatConfig.flyInDurationMs or 240,
    },
}
local w, h
local scene = "start"
local START_FADE_DURATION_MS = 1000
local RECORD_END_WAIT_MS = 2000
local RECORD_END_FADE_MS = 1000
local startFadeTimerMs = 0
local wasBattleMode = false
local startMode = "check"
local currentRunStage = nil
local recordEndState = "idle"
local recordEndTimerMs = 0
local handManager = HandManager.new()
local slideManager = SlideManager.new()
local battleFeedback = BattleFeedback.new()
local pauseMenu = PauseMenu.new(font)
local startScreen = StartScreen.new(font, logoImage, {
    buttonX = 70,
    buttonY = 300,
    buttonW = 260,
    buttonH = 60,
    countdownFont = countdownFont,
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

local function toBool(value)
    if type(value) == "boolean" then
        return value
    end
    if type(value) == "number" then
        return value ~= 0
    end
    if type(value) == "string" then
        local normalized = string.lower(value)
        return normalized == "1" or normalized == "true" or normalized == "yes" or normalized == "on"
    end
    return false
end

local function readDebugHitboxFlagFromConfig()
    local cfg = is.config and is.config() or nil
    if type(cfg) ~= "table" then
        return false
    end

    if toBool(cfg.debug_hitbox) or toBool(cfg.debugHitbox) then
        return true
    end

    local debugTable = cfg.debug or cfg.Debug
    if type(debugTable) == "table" then
        if toBool(debugTable.hitbox) or toBool(debugTable.hitboxes) then
            return true
        end
    end

    return false
end

local function configureStageRecordCallbacks()
    local phaseConfig = handManager:getPhaseConfig()
    local handlers = phaseConfig and phaseConfig.recordTimeCueHandlers or nil
    if type(handlers) ~= "table" then
        battleFeedback:setRecordTimeCueCallbacks(nil)
        return
    end

    local callbacks = {}
    for cueMs, handler in pairs(handlers) do
        if type(handler) == "function" then
            callbacks[cueMs] = function(context)
                return handler({
                    cueMs = context and context.cueMs or cueMs,
                    remainingMs = context and context.remainingMs or 0,
                    elapsedMs = context and context.elapsedMs or 0,
                    hitCount = context and context.hitCount or 0,
                    handManager = handManager,
                    battleFeedback = battleFeedback,
                    slideManager = slideManager,
                    actors = actors,
                    stage = currentRunStage,
                    playWidth = w,
                    playHeight = h,
                })
            end
        end
    end

    battleFeedback:setRecordTimeCueCallbacks(callbacks)
end

local function applyStageConfig(stage)
    local config = getStageSetup(stage) or getStageSetup(1) or {
        phase = "sandbag_intro",
        sandbag = defaultStageConfig,
    }
    local opponent = config.sandbag
    local tophat = config.tophat
    actors.sandbag.img = opponent.img
    actors.sandbag.w = opponent.w
    actors.sandbag.h = opponent.h
    actors.sandbag.hitbox.x = opponent.hitbox.x
    actors.sandbag.hitbox.y = opponent.hitbox.y
    actors.sandbag.hitbox.w = opponent.hitbox.w
    actors.sandbag.hitbox.h = opponent.hitbox.h

    if tophat then
        actors.tophat.img = tophat.img or -1
        actors.tophat.w = tophat.w or 0
        actors.tophat.h = tophat.h or 0
        actors.tophat.offsetX = tophat.offsetX or 0
        actors.tophat.offsetY = tophat.offsetY or 0
        actors.tophat.flyInOffsetX = tophat.flyInOffsetX or 0
        actors.tophat.flyInOffsetY = tophat.flyInOffsetY or -120
        actors.tophat.flyInDurationMs = tophat.flyInDurationMs or 240
    else
        actors.tophat.img = -1
        actors.tophat.w = 0
        actors.tophat.h = 0
        actors.tophat.offsetX = 0
        actors.tophat.offsetY = 0
        actors.tophat.flyInOffsetX = 0
        actors.tophat.flyInOffsetY = -120
        actors.tophat.flyInDurationMs = 240
    end

    return config
end

local function enterStartScene()
    scene = "start"
    startFadeTimerMs = 0
    wasBattleMode = false
    recordEndState = "idle"
    recordEndTimerMs = 0
    currentRunStage = nil
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
    wasBattleMode = false
    recordEndState = "idle"
    recordEndTimerMs = 0
    currentRunStage = nil
    slideManager:clear()
    battleFeedback:reset()

    if startMode == "check" then
        HandManager.clearPersistentHandRegistry()
    end

    local selectedStage = 1
    if startMode == "stage1" then
        selectedStage = 1
    elseif startMode == "stage2" then
        selectedStage = 2
    elseif startMode == "stage3" then
        selectedStage = 3
    end
    local stageConfig = applyStageConfig(selectedStage)
    configureStageRecordCallbacks()

    handManager = HandManager.new()
    phaseActionRunner:bindHandManagerPhaseEvents(handManager)
    handManager:setPlayArea(w, h)
    handManager:beginHandEntryAnimation()
    if startMode == "stage1" then
        currentRunStage = 1
        handManager:setPhase(stageConfig.phase)
    elseif startMode == "stage2" then
        currentRunStage = 2
        handManager:setPhase(stageConfig.phase)
    elseif startMode == "stage3" then
        currentRunStage = 3
        handManager:setPhase(stageConfig.phase)
    else
        currentRunStage = 1
        handManager:emitPhaseEnter()
    end
    configureStageRecordCallbacks()
    pauseMenu:setPaused(false)
end

function Init()
    w, h = is.size()
    StageProgression.load()
    local debugHitbox = readDebugHitboxFlagFromConfig()
    Hand.setDebugDrawHitRect(debugHitbox)
    sandbagTarget:setDebugDraw(debugHitbox)
    handManager:setPlayArea(w, h)
    pauseMenu:updateLayout(w, h)
    startScreen:updateLayout(w, h)
    enterStartScene()
end

function Update(dtMs)
    if scene == "start" then
        local hasHands = HandManager.hasPersistentBothHands()
        local records = StageProgression.getRecords()
        startScreen:setStageAvailability(
            hasHands,
            hasHands and records[1] ~= nil,
            hasHands and records[2] ~= nil
        )
        startScreen:setStageRecords(records)
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

    local isBattleMode = handManager:getCurrentMode() == "battle"
    if isBattleMode and not wasBattleMode then
        battleFeedback:startRecordMode(30000)
    end
    wasBattleMode = isBattleMode

    if isBattleMode and battleFeedback:isRecordActive() then
        local targetRect = sandbagTarget:getWorldRect()
        local hit = handManager:tryConsumeBattlePunchHit(targetRect)
        if hit then
            battleFeedback:onHit(targetRect, hit)
        end
    end

    if isBattleMode and battleFeedback:isRecordFinished() and recordEndState == "idle" then
        if currentRunStage ~= nil then
            StageProgression.completeStage(currentRunStage, battleFeedback:getHitCount())
        end
        handManager:showCoachMessage(L.t("ui.battle.record_finished_coach"))
        recordEndState = "wait"
        recordEndTimerMs = 0
    end

    if recordEndState == "wait" then
        recordEndTimerMs = recordEndTimerMs + dtMs
        if recordEndTimerMs >= RECORD_END_WAIT_MS then
            recordEndState = "fade"
            recordEndTimerMs = 0
        end
    elseif recordEndState == "fade" then
        recordEndTimerMs = recordEndTimerMs + dtMs
        if recordEndTimerMs >= RECORD_END_FADE_MS then
            enterStartScene()
            return
        end
    end
end

function Draw()
    w, h = is.size()
    handManager:setPlayArea(w, h)
    pauseMenu:updateLayout(w, h)
    startScreen:updateLayout(w, h)

    if scene == "start" or scene == "start_fade" then
        local hasHands = HandManager.hasPersistentBothHands()
        local records = StageProgression.getRecords()
        startScreen:setStageAvailability(
            hasHands,
            hasHands and records[1] ~= nil,
            hasHands and records[2] ~= nil
        )
        startScreen:setStageRecords(records)
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

    if recordEndState == "wait" or recordEndState == "fade" then
        g.color(1, 0.9, 0.25)
        g.text(countdownFont, L.t("ui.battle.record_finished_coach"), math.floor(w * 0.36), math.floor(h * 0.42))
    end

    if handManager:getCurrentMode() == "battle" then
        battleFeedback:drawHud(font, w, h)
    end

    battleFeedback:endWorldTransform()

    if recordEndState == "fade" then
        local alpha = math.min(1, recordEndTimerMs / RECORD_END_FADE_MS)
        g.color(0, 0, 0, alpha)
        g.rect(0, 0, w, h, true)
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
        if action == "start_check" then
            startMode = "check"
            beginStartTransition()
        elseif action == "start_stage1" then
            startMode = "stage1"
            beginStartTransition()
        elseif action == "start_stage2" then
            startMode = "stage2"
            beginStartTransition()
        elseif action == "start_stage3" then
            startMode = "stage3"
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

    if key == 0x50 then -- P
        if handManager:getCurrentMode() == "battle" and battleFeedback:isRecordActive() then
            battleFeedback:forceRecordRemainingMs(1000)
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
