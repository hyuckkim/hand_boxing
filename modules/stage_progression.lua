local StageProgression = {}

local state = {
    unlockedStage = 1,
    records = {
        [1] = nil,
        [2] = nil,
        [3] = nil,
    },
}

function StageProgression.getUnlockedStage()
    return state.unlockedStage
end

function StageProgression.getRecord(stage)
    return state.records[stage]
end

function StageProgression.getRecords()
    return {
        [1] = state.records[1],
        [2] = state.records[2],
        [3] = state.records[3],
    }
end

function StageProgression.completeStage(stage, score)
    if stage == nil then
        return
    end

    local current = state.records[stage]
    if current == nil or score > current then
        state.records[stage] = score
    end

    if stage + 1 > state.unlockedStage then
        state.unlockedStage = math.min(3, stage + 1)
    end
end

return StageProgression
