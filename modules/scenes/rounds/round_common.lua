local function buildRoundPhases(introName, settleName, introLines, settleLine, options)
    options = options or {}
    local stageSetup = options.stageSetup

    local phases = {
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
            stageSetup = stageSetup,
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
            stageSetup = stageSetup,
        }
    }

    return phases
end

return {
    buildRoundPhases = buildRoundPhases,
}
