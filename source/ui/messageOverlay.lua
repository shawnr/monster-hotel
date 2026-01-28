-- Monster Hotel - Message Overlay System
-- Shows game messages with bold black text and white stroke

local gfx <const> = playdate.graphics

MessageOverlay = {}

-- Message types
MessageOverlay.MESSAGES = {
    GAME_START = "gameStart",
    ELEVATOR_DOORS = "elevatorDoors",
    SERVICE_FLOOR = "serviceFloor",
    MONSTER_RAGE = "monsterRage"
}

-- Message text content
local MESSAGE_TEXT = {
    [MessageOverlay.MESSAGES.GAME_START] = "Get the monsters\nto their rooms!",
    [MessageOverlay.MESSAGES.ELEVATOR_DOORS] = "Use A,B,L or R\nto open/close doors.",
    [MessageOverlay.MESSAGES.SERVICE_FLOOR] = "Service Floor Added!\nMonsters can relax here.",
    [MessageOverlay.MESSAGES.MONSTER_RAGE] = "Monster Rage!"
}

-- Messages that should use smaller text (50% screen max)
local SMALL_MESSAGES = {
    [MessageOverlay.MESSAGES.SERVICE_FLOOR] = true
}

-- Timing constants
local SHOW_DURATION = 3.0  -- seconds to show at full opacity
local FADE_DURATION = 1.0  -- seconds to fade out
local RAGE_SHOW_DURATION = 1.5  -- shorter display for rage messages
local RAGE_FADE_DURATION = 1.0  -- fade duration for rage
local RAGE_FLOAT_SPEED = 30  -- pixels to float up during fade

-- State for center messages
local centerMessage = nil
local centerMessageId = nil  -- Track message type for special rendering
local centerTimer = 0
local centerPhase = "none"  -- "showing", "fading", "none"

-- State for right-side messages (stacking)
local rightMessages = {}  -- Array of {text, timer, phase}

-- Persistence for doors message (only shows first time)
local doorsShown = false

function MessageOverlay:init()
    -- Load persistence for doors message
    local data = playdate.datastore.read("messages")
    if data then
        doorsShown = data.doorsShown or false
    else
        doorsShown = false
    end

    centerMessage = nil
    centerMessageId = nil
    centerTimer = 0
    centerPhase = "none"
    rightMessages = {}
end

function MessageOverlay:saveState()
    playdate.datastore.write({ doorsShown = doorsShown }, "messages")
end

function MessageOverlay:show(messageId)
    local text = MESSAGE_TEXT[messageId]
    if not text then
        return false
    end

    -- Handle doors message - only show first time
    if messageId == MessageOverlay.MESSAGES.ELEVATOR_DOORS then
        if doorsShown then
            return false
        end
        doorsShown = true
        self:saveState()
    end

    -- Monster rage goes to right side stack with float effect
    if messageId == MessageOverlay.MESSAGES.MONSTER_RAGE then
        table.insert(rightMessages, {
            text = text,
            timer = 0,
            phase = "showing",
            yOffset = 0  -- Will increase as it fades (floats up)
        })
        return true
    end

    -- All other messages go to center
    -- Don't interrupt if already showing
    if centerPhase ~= "none" then
        return false
    end

    centerMessage = text
    centerMessageId = messageId
    centerTimer = 0
    centerPhase = "showing"

    return true
end

function MessageOverlay:isShowingCenter()
    return centerPhase ~= "none"
end

function MessageOverlay:update()
    -- Update center message
    if centerPhase ~= "none" then
        centerTimer = centerTimer + (1 / GAME_TICK_RATE)

        if centerPhase == "showing" then
            if centerTimer >= SHOW_DURATION then
                centerPhase = "fading"
                centerTimer = 0
            end
        elseif centerPhase == "fading" then
            if centerTimer >= FADE_DURATION then
                centerPhase = "none"
                centerMessage = nil
                centerMessageId = nil
                centerTimer = 0
            end
        end
    end

    -- Update right-side messages (process in order)
    for i = #rightMessages, 1, -1 do
        local msg = rightMessages[i]
        msg.timer = msg.timer + (1 / GAME_TICK_RATE)

        if msg.phase == "showing" then
            if msg.timer >= RAGE_SHOW_DURATION then
                msg.phase = "fading"
                msg.timer = 0
            end
        elseif msg.phase == "fading" then
            -- Float upward as it fades
            local fadeProgress = msg.timer / RAGE_FADE_DURATION
            msg.yOffset = fadeProgress * RAGE_FLOAT_SPEED

            if msg.timer >= RAGE_FADE_DURATION then
                table.remove(rightMessages, i)
            end
        end
    end
end

function MessageOverlay:draw()
    -- Draw center message
    if centerPhase ~= "none" and centerMessage then
        local alpha = 1.0
        if centerPhase == "fading" then
            alpha = 1.0 - (centerTimer / FADE_DURATION)
        end
        -- Check if this is a small message (service floor)
        local isSmall = centerMessageId and SMALL_MESSAGES[centerMessageId]
        self:drawMessage(centerMessage, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, alpha, "center", isSmall)
    end

    -- Draw right-side messages (stacked from top, float up as they fade)
    local rightY = 80
    for i, msg in ipairs(rightMessages) do
        local alpha = 1.0
        if msg.phase == "fading" then
            alpha = 1.0 - (msg.timer / RAGE_FADE_DURATION)
        end
        -- Position on right side, apply float offset
        local floatY = rightY - (msg.yOffset or 0)
        self:drawMessage(msg.text, SCREEN_WIDTH - 140, floatY, alpha, "right", false)
        rightY = rightY + 50
    end
end

function MessageOverlay:drawMessage(text, x, y, alpha, align, isSmall)
    -- Apply dither for fade effect
    if alpha < 1.0 then
        gfx.setDitherPattern(1.0 - alpha)
    end

    -- Use game's bold font, scaled based on message type
    Fonts.set(gfx.font.kVariantBold)

    -- Get text dimensions
    local textWidth, textHeight = gfx.getTextSize(text)

    -- Create an image to draw text into, then scale it up
    -- Small messages (service floor) use 1x scale to fit in 50% of screen
    local scale = isSmall and 1 or 2
    local img = gfx.image.new(textWidth + 8, textHeight + 8)

    gfx.pushContext(img)
    gfx.clear(gfx.kColorClear)

    -- Draw white stroke (outline) by drawing in 8 directions
    local strokeOffsets = {
        {-1, -1}, {0, -1}, {1, -1},
        {-1, 0},          {1, 0},
        {-1, 1},  {0, 1},  {1, 1}
    }

    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    for _, offset in ipairs(strokeOffsets) do
        gfx.drawText(text, 4 + offset[1], 4 + offset[2])
    end

    -- Draw main black text
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    gfx.drawText(text, 4, 4)

    gfx.popContext()

    -- Calculate draw position based on alignment
    local scaledWidth = (textWidth + 8) * scale
    local scaledHeight = (textHeight + 8) * scale
    local drawX, drawY

    if align == "center" then
        drawX = x - scaledWidth / 2
        drawY = y - scaledHeight / 2
    else  -- right align
        drawX = x - scaledWidth / 2
        drawY = y - scaledHeight / 2
    end

    -- Draw scaled image
    img:drawScaled(drawX, drawY, scale)

    -- Reset draw mode
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- Reset dither
    if alpha < 1.0 then
        gfx.setDitherPattern(0)
    end

    -- Reset font
    Fonts.reset()
end

-- Reset all state (for testing)
function MessageOverlay:resetAll()
    doorsShown = false
    centerMessage = nil
    centerMessageId = nil
    centerTimer = 0
    centerPhase = "none"
    rightMessages = {}
    self:saveState()
end

return MessageOverlay
