local StageProgression = {}
local SAVE_PATH = "save.json"

local state = {
    records = {
        [1] = nil,
        [2] = nil,
        [3] = nil,
    },
}

function StageProgression.getUnlockedStage()
    return 3
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

local function normalizeScore(value)
    if type(value) == "number" then
        return math.floor(value)
    end
    return nil
end

function StageProgression.load()
    local loaded = res.loadjson(SAVE_PATH)
    if type(loaded) ~= "table" then
        return false
    end

    local records = loaded.records
    if type(records) ~= "table" then
        return false
    end

    state.records[1] = normalizeScore(records[1] or records["1"])
    state.records[2] = normalizeScore(records[2] or records["2"])
    state.records[3] = normalizeScore(records[3] or records["3"])
    return true
end

function StageProgression.save()
    local payload = {
        records = {
            [1] = state.records[1],
            [2] = state.records[2],
            [3] = state.records[3],
        },
    }
    return res.savejson(SAVE_PATH, payload)
end

function StageProgression.completeStage(stage, score)
    if stage == nil then
        return
    end

    local current = state.records[stage]
    if current == nil or score > current then
        state.records[stage] = score
        StageProgression.save()
    end
end

return StageProgression
