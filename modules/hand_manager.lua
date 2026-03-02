local Hand = dofile("modules/hand.lua")
local MessageManager = dofile("modules/message_manager.lua")
local PHASES = dofile("modules/phases.lua")

local HandManager = {}
HandManager.__index = HandManager

local OFFSCREEN_ALLOWANCE = 220
local HAND_SPRITE_SIZE = 400
local HAND_BOTTOM_MARGIN = 20
local HAND_SIDE_MARGIN = 20
local AUTO_ADVANCE_DELAY_MS = 1000
local HAND_ENTRY_DURATION_MS = 500
local HAND_ENTRY_START_OFFSET = HAND_SPRITE_SIZE + 40

function HandManager.new()
    local leftHand = Hand.new("left")
    local rightHand = Hand.new("right")

    local manager = setmetatable({
        leftHand = leftHand,
        rightHand = rightHand,
        hands = { leftHand, rightHand },
        leftOwnerId = nil,
        rightOwnerId = nil,
        phase = "intro",
        dialogueIndex = 1,
        dialogueCompleteHoldMs = 0,
        defaultSpeaker = "코치",
        phaseEventHandler = nil,
        messageManager = MessageManager.new({
            speaker = "코치",
            msPerChar = 40,
            errorDurationMs = 1000,
        }),
        handEntryAnimating = false,
        handEntryElapsedMs = 0,
        playWidth = 0,
        playHeight = 0,
        hasSpawnedHands = false,
        bounds = {
            minX = -OFFSCREEN_ALLOWANCE,
            maxX = OFFSCREEN_ALLOWANCE,
            minY = -OFFSCREEN_ALLOWANCE,
            maxY = OFFSCREEN_ALLOWANCE,
        },
    }, HandManager)

    manager:setPhase("intro")
    return manager
end

function HandManager:setPhaseEventHandler(handler)
    self.phaseEventHandler = handler
end

function HandManager:emitPhaseEnter()
    if self.phaseEventHandler then
        self.phaseEventHandler("phase_enter", self.phase, self:getPhaseConfig())
    end
end

function HandManager:emitDialogueChanged()
    if self.phaseEventHandler then
        self.phaseEventHandler("dialogue_changed", self.phase, self:getPhaseConfig(), self.dialogueIndex)
    end
end

function HandManager:getPhaseConfig()
    return PHASES[self.phase]
end

function HandManager:getCurrentMode()
    local config = self:getPhaseConfig()
    return config and config.mode or nil
end

function HandManager:setPhase(phaseName)
    self.phase = phaseName
    self.dialogueIndex = 1
    self.dialogueCompleteHoldMs = 0

    local config = self:getPhaseConfig()
    local speaker = self.defaultSpeaker
    if config and config.speaker ~= nil then
        speaker = config.speaker
    end
    self.messageManager.speaker = speaker

    if config and config.dialogues and #config.dialogues > 0 then
        self.messageManager:setMessage(config.dialogues[self.dialogueIndex])
        if config.instantDialogue then
            self.messageManager:completeCurrentMessage()
        end
    else
        self.messageManager:setMessage("")
    end

    self:emitPhaseEnter()
    self:emitDialogueChanged()
end

function HandManager:advanceDialogue()
    local config = self:getPhaseConfig()
    if not config or not config.dialogues or #config.dialogues == 0 then
        return
    end

    if not self.messageManager:isComplete() then
        self.messageManager:completeCurrentMessage()
        self.dialogueCompleteHoldMs = 0
        return
    end

    if self.dialogueIndex < #config.dialogues then
        self.dialogueIndex = self.dialogueIndex + 1
        self.messageManager:setMessage(config.dialogues[self.dialogueIndex])
        if config.instantDialogue then
            self.messageManager:completeCurrentMessage()
        end
        self:emitDialogueChanged()
        self.dialogueCompleteHoldMs = 0
        return
    end

    if config.nextPhase then
        self:setPhase(config.nextPhase)
    end
end

function HandManager:setPlayArea(width, height)
    self.playWidth = width
    self.playHeight = height

    self.bounds.minX = -OFFSCREEN_ALLOWANCE
    self.bounds.maxX = width - OFFSCREEN_ALLOWANCE
    self.bounds.minY = -OFFSCREEN_ALLOWANCE
    self.bounds.maxY = height - OFFSCREEN_ALLOWANCE

    if not self.hasSpawnedHands then
        local leftX, leftY = self:getSpawnPosition("left")
        local rightX, rightY = self:getSpawnPosition("right")
        self.leftHand:setPosition(leftX, leftY)
        self.rightHand:setPosition(rightX, rightY)
        self.hasSpawnedHands = true
    end
end

function HandManager:getSpawnPosition(side)
    local y = self.playHeight - HAND_SPRITE_SIZE - HAND_BOTTOM_MARGIN
    if side == "right" then
        local x = self.playWidth - HAND_SPRITE_SIZE - HAND_SIDE_MARGIN
        return x, y
    end
    return HAND_SIDE_MARGIN, y
end

function HandManager:beginHandEntryAnimation()
    self.handEntryAnimating = true
    self.handEntryElapsedMs = 0

    local leftX, _ = self:getSpawnPosition("left")
    local rightX, _ = self:getSpawnPosition("right")
    local startY = self.playHeight + HAND_ENTRY_START_OFFSET
    self.leftHand:setPosition(leftX, startY)
    self.rightHand:setPosition(rightX, startY)
end

function HandManager:updateHandEntryAnimation(dtMs)
    if not self.handEntryAnimating then
        return
    end

    self.handEntryElapsedMs = self.handEntryElapsedMs + dtMs
    local t = math.min(1, self.handEntryElapsedMs / HAND_ENTRY_DURATION_MS)

    local leftX, targetY = self:getSpawnPosition("left")
    local rightX = self:getSpawnPosition("right")
    local startY = self.playHeight + HAND_ENTRY_START_OFFSET
    local currentY = startY + (targetY - startY) * t

    self.leftHand:setPosition(leftX, currentY)
    self.rightHand:setPosition(rightX, currentY)

    if t >= 1 then
        self.handEntryAnimating = false
    end
end

function HandManager:update(dtMs)
    self:updateHandEntryAnimation(dtMs)
    self.messageManager:update(dtMs)

    local phaseConfig = self:getPhaseConfig()
    if phaseConfig and phaseConfig.mode ~= "register" then
        if self.messageManager:isComplete() and not self.messageManager:hasErrorMessage() then
            self.dialogueCompleteHoldMs = self.dialogueCompleteHoldMs + dtMs
            if self.dialogueCompleteHoldMs >= AUTO_ADVANCE_DELAY_MS then
                self:advanceDialogue()
                self.dialogueCompleteHoldMs = 0
            end
        else
            self.dialogueCompleteHoldMs = 0
        end
    else
        self.dialogueCompleteHoldMs = 0
    end

    for _, hand in pairs(self.hands) do
        hand:update(dtMs, self.bounds)
    end
end

function HandManager:setError(message)
    self.messageManager:setErrorMessage(message)
end

function HandManager:getHandByOwnerId(id)
    if self.leftOwnerId == id then
        return self.leftHand
    end
    if self.rightOwnerId == id then
        return self.rightHand
    end
    return nil
end

function HandManager:getPhaseHandForInput(id)
    if self.handEntryAnimating then
        return nil
    end

    local ownedHand = self:getHandByOwnerId(id)
    if ownedHand then
        return ownedHand
    end

    local config = self:getPhaseConfig()
    if not config or config.mode ~= "register" then
        return nil
    end

    if config.target == "left" and self.leftOwnerId == nil then
        return self.leftHand
    end
    if config.target == "right" and self.rightOwnerId == nil then
        return self.rightHand
    end
    return nil
end

function HandManager:draw(font, images, countdownFont)
    local phaseConfig = self:getPhaseConfig()
    if phaseConfig and phaseConfig.mode == "countdown" then
        local drawFont = countdownFont or font
        g.color(1, 1, 1)
        g.text(drawFont, self.messageManager:getText(), math.floor(self.playWidth * 0.46), math.floor(self.playHeight * 0.24))
    else
        g.color(1, 1, 1)
        g.text(font, self.messageManager:getText(), 20, 20)
    end

    if self.messageManager:hasErrorMessage() then
        g.color(0xff3333)
        g.text(font, self.messageManager:getErrorText(), 20, 80)
    end

    for _, hand in pairs(self.hands) do
        hand:draw(images)
    end
end

function HandManager:onMouseDown(button, id)
    local phaseConfig = self:getPhaseConfig()

    local inputHand = self:getPhaseHandForInput(id)
    if inputHand then
        inputHand:onMouseDown(button)
    end

    if not phaseConfig or phaseConfig.mode ~= "register" then
        if button == 0 and (not phaseConfig or phaseConfig.mode ~= "countdown") then
            self:advanceDialogue()
        end
        return
    end

    if phaseConfig.target == "left" and self.leftOwnerId == nil then
        if button ~= phaseConfig.requiredButton then
            self:setError(phaseConfig.invalidMessage)
            return
        end

        self.leftOwnerId = id
        if phaseConfig.nextPhase then
            self:setPhase(phaseConfig.nextPhase)
        end
        print("Left hand registered: " .. id)
    elseif phaseConfig.target == "right" and self.rightOwnerId == nil then
        if id == self.leftOwnerId then
            self:setError("그건 이미 왼손으로 등록된 마우스입니다!")
            return
        end

        if button ~= phaseConfig.requiredButton then
            self:setError(phaseConfig.invalidMessage)
            return
        end

        self.rightOwnerId = id
        if phaseConfig.nextPhase then
            self:setPhase(phaseConfig.nextPhase)
        end
        print("Right hand registered: " .. id)
    end
end

function HandManager:onMouseMove(id, dx, dy)
    local hand = self:getPhaseHandForInput(id)
    if hand then
        local ownerId = id
        if hand == self.leftHand then
            ownerId = self.leftOwnerId or id
        elseif hand == self.rightHand then
            ownerId = self.rightOwnerId or id
        end

        hand:move(dx, dy, self.bounds, ownerId)
    end
end

function HandManager:onMouseUp(button, id)
    local hand = self:getPhaseHandForInput(id)
    if hand then
        hand:onMouseUp(button)
    end
end

function HandManager:tryConsumeBattlePunchHit(targetRect)
    if self:getCurrentMode() ~= "battle" then
        return nil
    end

    if not targetRect then
        return nil
    end

    local tx1 = targetRect.x
    local ty1 = targetRect.y
    local tx2 = targetRect.x + targetRect.w
    local ty2 = targetRect.y + targetRect.h

    for _, hand in pairs(self.hands) do
        if hand:canDealPunchHit() then
            local rect = hand:getWorldHitRect()
            local rx1 = rect.x
            local ry1 = rect.y
            local rx2 = rect.x + rect.w
            local ry2 = rect.y + rect.h

            local overlap = rx1 < tx2 and rx2 > tx1 and ry1 < ty2 and ry2 > ty1
            if overlap then
                hand:consumePunchHit()
                hand:applyImpactFeedback(hand:getPunchLevel())
                return {
                    side = hand.side,
                    level = hand:getPunchLevel(),
                }
            end
        end
    end

    return nil
end

return HandManager