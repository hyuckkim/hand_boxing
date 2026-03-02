local L = require("modules.localization")
local round1 = require("modules.scenes.rounds.round1")
local round2 = require("modules.scenes.rounds.round2")
local round3 = require("modules.scenes.rounds.round3")

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

for name, config in pairs(round1.phases) do
    scene[name] = config
end
for name, config in pairs(round2.phases) do
    scene[name] = config
end
for name, config in pairs(round3.phases) do
    scene[name] = config
end

function scene.getStageSetup(stage)
    if stage == 2 then
        return round2.stageSetup
    end
    if stage == 3 then
        return round3.stageSetup
    end
    return round1.stageSetup
end

return scene
