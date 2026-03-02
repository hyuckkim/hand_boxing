local L = require("modules.localization")
local Common = require("modules.scenes.rounds.round_common")

local fatImage = res.image("fat.png")

local stageSetup = {
    phase = "fat_intro",
    sandbag = {
        img = fatImage,
        w = 280,
        h = 327,
        hitbox = { x = 110, y = 132, w = 62, h = 64 },
    },
}

local phases = Common.buildRoundPhases(
    "fat_intro",
    "fat_settle",
    {
        L.t("scene.fat_intro.line1"),
        L.t("scene.fat_intro.line2"),
        L.t("scene.fat_intro.line3"),
        L.t("scene.fat_intro.line4"),
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
