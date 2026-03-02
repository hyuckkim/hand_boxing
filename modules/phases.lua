local sandbagScene = require("modules.scenes.new_opponent_sandbag")
local L = require("modules.localization")

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
            L.t("phase.intro.line1"),
            L.t("phase.intro.line2"),
            L.t("phase.intro.line3"),
        },
        nextPhase = "register_left",
    },
    register_left = {
        mode = "register",
        target = "left",
        requiredButton = 1,
        invalidMessage = L.t("phase.register_left.invalid"),
        dialogues = {
            L.t("phase.register_left.line1"),
        },
        nextPhase = "register_right",
    },
    register_right = {
        mode = "register",
        target = "right",
        requiredButton = 0,
        invalidMessage = L.t("phase.register_right.invalid"),
        dialogues = {
            L.t("phase.register_right.line1"),
        },
        nextPhase = "sandbag_intro",
    },
    play = {
        mode = "dialog",
        dialogues = {
            L.t("phase.play.line1"),
        },
    },
}

for name, config in pairs(sandbagScene) do
    phases[name] = config
end

return phases
