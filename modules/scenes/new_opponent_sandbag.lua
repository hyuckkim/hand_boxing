local L = require("modules.localization")

local scene = {
    sandbag_intro = {
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
        dialogues = {
            L.t("scene.sandbag_intro.line1"),
            L.t("scene.sandbag_intro.line2"),
            L.t("scene.sandbag_intro.line3"),
        },
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
        nextPhase = "sandbag_settle",
    },
    sandbag_settle = {
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
            L.t("scene.sandbag_settle.line1"),
        },
        nextPhase = "countdown",
    },
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

return scene
