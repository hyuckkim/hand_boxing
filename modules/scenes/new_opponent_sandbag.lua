local L = require("modules.localization")
local sandbagImage = res.image("sandbag.png")
local fatImage = res.image("fat.png")
local hatImage = res.image("hat.png")
local topHatImage = res.image("tophat.png")

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
        phase = "hat_intro",
        sandbag = {
            img = hatImage,
            w = 136,
            h = 328,
            hitbox = { x = 48, y = 134, w = 40, h = 60 },
        },
        tophat = {
            img = topHatImage,
            w = 193,
            h = 342,
            offsetX = -6,
            offsetY = -18,
            flyInOffsetX = 90,
            flyInOffsetY = -120,
            flyInDurationMs = 240,
        },
    },
}

local function runTophatFlyIn(context)
    if not context or not context.slideManager or not context.actors then
        return
    end

    local tophatActor = context.actors.tophat
    if not tophatActor or not tophatActor.img or tophatActor.img < 0 then
        return
    end

    local sandbagState = context.slideManager:getObjectState("sandbag")
    local playWidth = context.playWidth or 0
    local targetX
    local targetY

    if sandbagState then
        targetX = sandbagState.x + math.floor((sandbagState.width - tophatActor.w) * 0.5) + (tophatActor.offsetX or 0)
        targetY = sandbagState.y + (tophatActor.offsetY or 0)
    else
        targetX = math.floor((playWidth - tophatActor.w) * 0.5)
        targetY = 120
    end

    local startX = targetX + (tophatActor.flyInOffsetX or 0)
    local startY = (tophatActor.flyInOffsetY or (-tophatActor.h - 20))

    context.slideManager:registerOrUpdate("tophat", {
        imageId = tophatActor.img,
        width = tophatActor.w,
        height = tophatActor.h,
        x = startX,
        y = startY,
        zIndex = tophatActor.zIndex,
        visible = false,
    })

    context.slideManager:startEnter("tophat", {
        startX = startX,
        startY = startY,
        targetX = targetX,
        targetY = targetY,
        durationMs = tophatActor.flyInDurationMs or 240,
        easing = "ease_out_cubic",
        keepVisible = true,
    })
end

local function buildRoundPhases(introName, settleName, introLines, settleLine, options)
    options = options or {}
    return {
        [introName] = {
            mode = "dialog",
            enterActions = {
                {
                    type = "slide",
                    object = "coach",
                    mode = "move",
                    to = { xAnchor = "center", yAnchor = "center", yOffset = -40 },
                    durationMs = 260,
                    easing = "ease_out_cubic",
                },
            },
            dialogues = introLines,
            recordTimeCueHandlers = options.recordTimeCueHandlers,
            dialogueActions = {
                [2] = {
                    {
                        type = "slide",
                        object = "coach",
                        mode = "move",
                        to = { xAnchor = "center", xOffset = -150, yAnchor = "center", yOffset = -40 },
                        durationMs = 550,
                        easing = "ease_out_cubic",
                    },
                    {
                        type = "slide",
                        object = "sandbag",
                        mode = "enter",
                        from = { xAnchor = "rightOutside", xOffset = 60, yAnchor = "center", yOffset = -10 },
                        to = { xAnchor = "center", xOffset = 140, yAnchor = "center", yOffset = -10 },
                        durationMs = 700,
                        easing = "ease_out_cubic",
                        keepVisible = true,
                    },
                },
            },
            nextPhase = settleName,
        },
        [settleName] = {
            mode = "dialog",
            enterActions = {
                {
                    type = "slide",
                    object = "sandbag",
                    mode = "move",
                    to = { xAnchor = "center", xOffset = 0, yAnchor = "center", yOffset = -10 },
                    durationMs = 450,
                    easing = "ease_out_cubic",
                },
                {
                    type = "slide",
                    object = "coach",
                    mode = "exit",
                    to = { xAnchor = "leftOutside", xOffset = -80, yAnchor = "current", yOffset = 0 },
                    durationMs = 500,
                    easing = "ease_out_cubic",
                    hideOnComplete = true,
                },
            },
            dialogues = {
                settleLine,
            },
            nextPhase = "countdown",
        }
    }
end

local scene = {
    countdown = {
        mode = "countdown",
        speaker = "",
        instantDialogue = true,
        dialogues = {
            L.t("scene.countdown.n3"),
            L.t("scene.countdown.n2"),
            L.t("scene.countdown.n1"),
            L.t("scene.countdown.start")
        },
        nextPhase = "battle"
    },
    battle = {
        mode = "battle",
        dialogues = {
            L.t("scene.battle.line1")
        }
    }
}

local round1 = buildRoundPhases(
    "sandbag_intro",
    "sandbag_settle",
    {
        L.t("scene.sandbag_intro.line1"),
        L.t("scene.sandbag_intro.line2"),
        L.t("scene.sandbag_intro.line3"),
    },
    L.t("scene.sandbag_settle.line1")
)

local round2 = buildRoundPhases(
    "fat_intro",
    "fat_settle",
    {
        L.t("scene.fat_intro.line1"),
        L.t("scene.fat_intro.line2"),
        L.t("scene.fat_intro.line3"),
        L.t("scene.fat_intro.line4"),
    },
    L.t("scene.sandbag_settle.line1")
)

local round3 = buildRoundPhases(
    "hat_intro",
    "hat_settle",
    {
        L.t("scene.hat_intro.line1"),
        L.t("scene.hat_intro.line2"),
        L.t("scene.hat_intro.line3"),
        L.t("scene.hat_intro.line4"),
    },
    L.t("scene.sandbag_settle.line1"),
    {
        recordTimeCueHandlers = {
            [25000] = function(context)
                runTophatFlyIn(context)
            end,
            [15000] = function(context)
            end,
            [5000] = function(context)
            end,
        },
    }
)

scene.sandbag_intro = round1.sandbag_intro
scene.sandbag_settle = round1.sandbag_settle
scene.fat_intro = round2.fat_intro
scene.fat_settle = round2.fat_settle
scene.hat_intro = round3.hat_intro
scene.hat_settle = round3.hat_settle
scene.stageConfigs = STAGE_CONFIGS

return scene
