local scene = {
    sandbag_intro = {
        mode = "dialog",
        dialogues = {
            "새 상대를 소개하지.",
            "새 상대: 샌드백.",
            "움직이지 않지만, 네 주먹의 정확도를 전부 드러내 줄 거다.",
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
            "좋다. 샌드백을 중앙에 고정했다. 이제 시작한다.",
        },
        nextPhase = "countdown",
    },
    countdown = {
        mode = "countdown",
        speaker = "",
        instantDialogue = true,
        dialogues = {
            "3...",
            "2...",
            "1...",
            "Start!"
        },
        nextPhase = "battle"
    },
    battle = {
        mode = "battle",
        dialogues = {
            "실전 시작! 샌드백을 쳐라!"
        }
    }
}

return scene
