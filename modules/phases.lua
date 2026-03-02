local sandbagScene = require("modules.scenes.new_opponent_sandbag")

local phases = {
    intro = {
        mode = "dialog",
        enterActions = {
            {
                type = "slide",
                object = "coach",
                mode = "enter",
                from = { xAnchor = "leftOutside", xOffset = -40, yAnchor = "center", yOffset = -40 },
                to = { xAnchor = "center", yAnchor = "center", yOffset = -40 },
                durationMs = 900,
                easing = "ease_out_cubic",
                keepVisible = true,
            },
        },
        dialogues = {
            "링 위에 올라가기 전에 마음가짐부터 다시 잡는다.",
            "...",
            "오늘 훈련, 끝까지 버틸 자신 있나? 대답 대신 양손 엄지로 표시해라.",
        },
        nextPhase = "register_left",
    },
    register_left = {
        mode = "register",
        target = "left",
        requiredButton = 1,
        invalidMessage = "그건 엄지가 아니라 새끼손까락이다.",
        dialogues = {
            "우선 왼손. 엄지를 올려 자신감을 보여봐.",
        },
        nextPhase = "register_right",
    },
    register_right = {
        mode = "register",
        target = "right",
        requiredButton = 0,
        invalidMessage = "그건 엄지가 아니라 새끼손까락이다.",
        dialogues = {
            "그렇지. 이제 오른손도. 엄지를 확실하게 세워라.",
        },
        nextPhase = "sandbag_intro",
    },
    play = {
        mode = "dialog",
        dialogues = {
            "좋아. 준비 자세를 유지해라.",
        },
    },
}

for name, config in pairs(sandbagScene) do
    phases[name] = config
end

return phases
