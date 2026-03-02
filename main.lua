local HandManager = require("modules.hand_manager")
local BattleFeedback = require("modules.battle_feedback")
local PauseMenu = require("modules.pause_menu")
local StartScreen = require("modules.start_screen")
local SlideManager = require("modules.slide_manager")
local PhaseActionRunner = require("modules.phase_action_runner")
local SandbagTarget = require("modules.sandbag_target")
local StageProgression = require("modules.stage_progression")
local L = require("modules.localization")

local font = res.fontFile("Shilla_Culture.ttf", "Shilla_Culture(M)", 24)
local countdownFont = res.fontFile("Shilla_Culture.ttf", "Shilla_Culture(M)", 88)
local logoImage = res.image("logo.png")
local sandbagImage = res.image("sandbag.png")
local fatImage = res.image("fat.png")
local DEBUG_DRAW_HITBOXES = true
local actors = {
    coach = {
        img = res.image("coach.png"),
        w = 163,
        h = 328,
        enterDurationMs = 900,
    },
    sandbag = {
        img = sandbagImage,
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
local STAGE_CONFIGS = {
    [1] = {
        phase = "sandbag_intro",
        sandbag = {
            img = sandbagImage,
            w = 136,
            h = 328,
            hitbox = { x = 48, y = 134, w = 40, h = 60 },
        },
    },
    [2] = {
        phase = "fat_intro",
        sandbag = {
            img = fatImage,
            w = 280,
            h = 327,
            hitbox = { x = 110, y = 132, w = 62, h = 64 },
        },
    },
    [3] = {
        phase = "sandbag_intro",
        sandbag = {
            img = sandbagImage,
            w = 136,
            h = 328,
            hitbox = { x = 48, y = 134, w = 40, h = 60 },
        },
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

local function applyStageConfig(stage)
    local config = STAGE_CONFIGS[stage] or STAGE_CONFIGS[1]
    local opponent = config.sandbag
    actors.sandbag.img = opponent.img
    actors.sandbag.w = opponent.w
    actors.sandbag.h = opponent.h
    actors.sandbag.hitbox.x = opponent.hitbox.x
    actors.sandbag.hitbox.y = opponent.hitbox.y
    actors.sandbag.hitbox.w = opponent.hitbox.w
    actors.sandbag.hitbox.h = opponent.hitbox.h
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
        local hasHands = HandManager.hasPersistentBothHands()
        local unlocked = StageProgression.getUnlockedStage()
        startScreen:setStageAvailability(hasHands and unlocked >= 1, hasHands and unlocked >= 2, hasHands and unlocked >= 3)
        startScreen:setStageRecords(StageProgression.getRecords())
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
        local unlocked = StageProgression.getUnlockedStage()
        startScreen:setStageAvailability(hasHands and unlocked >= 1, hasHands and unlocked >= 2, hasHands and unlocked >= 3)
        startScreen:setStageRecords(StageProgression.getRecords())
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
