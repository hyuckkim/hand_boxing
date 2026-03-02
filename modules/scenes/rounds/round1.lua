local L = require("modules.localization")
local Common = require("modules.scenes.rounds.round_common")

local sandbagImage = res.image("sandbag.png")

local stageSetup = {
    phase = "sandbag_intro",
    sandbag = {
        img = sandbagImage,
        w = 136,
        h = 328,
        hitbox = { x = 48, y = 134, w = 40, h = 60 },
    },
}

local phases = Common.buildRoundPhases(
    "sandbag_intro",
    "sandbag_settle",
    {
        L.t("scene.sandbag_intro.line1"),
        L.t("scene.sandbag_intro.line2"),
        L.t("scene.sandbag_intro.line3"),
    },
    L.t("scene.sandbag_settle.line1"),
    {
        stageSetup = stageSetup,
    }
)

return {
    stageSetup = stageSetup,
    phases = phases,
}
