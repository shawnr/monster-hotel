-- Monster Hotel - Day End Scene
-- Shows day summary and continues to next day

import "scenes/sceneManager"

local gfx <const> = playdate.graphics

DayEndScene = {}

-- Static assets
DayEndScene.backgroundPattern = nil

function DayEndScene.loadAssets()
    if DayEndScene.backgroundPattern == nil then
        DayEndScene.backgroundPattern = gfx.image.new("images/ui/backgrounds/pattern-chevron")
    end
end

function DayEndScene:enter(options)
    options = options or {}

    -- Load assets
    DayEndScene.loadAssets()

    self.hotel = options.hotel
    self.summary = options.summary or {}
    self.newUnlocks = options.newUnlocks or {}
    self.saveSlot = options.saveSlot or 1

    -- State
    self.showingUnlock = false
    self.currentUnlockIndex = 0

    -- Clear any leftover sprites and reset draw state
    gfx.sprite.removeAll()
    gfx.setDrawOffset(0, 0)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    gfx.setColor(gfx.kColorBlack)

    -- Force an immediate redraw
    gfx.clear(gfx.kColorWhite)

    print("DayEndScene entered - hotel:", self.hotel, "summary:", self.summary)
end

function DayEndScene:exit()
    -- Nothing to clean up
end

function DayEndScene:update()
    -- Nothing to update - waiting for button press
end

function DayEndScene:draw()
    gfx.setDrawOffset(0, 0)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    gfx.setColor(gfx.kColorBlack)

    -- Draw tiled background pattern
    if DayEndScene.backgroundPattern then
        for x = 0, SCREEN_WIDTH, 8 do
            for y = 0, SCREEN_HEIGHT, 8 do
                DayEndScene.backgroundPattern:draw(x, y)
            end
        end
    else
        gfx.clear(gfx.kColorWhite)
    end

    if self.showingUnlock and self.currentUnlockIndex <= #self.newUnlocks then
        self:drawUnlockScreen()
    else
        self:drawSummaryScreen()
    end
end

function DayEndScene:drawSummaryScreen()
    -- Content box dimensions - leave room at bottom for button
    local boxMargin = 20
    local boxTop = 10
    local boxBottom = SCREEN_HEIGHT - 40  -- Leave room for button below
    local boxHeight = boxBottom - boxTop

    -- Draw white content box with border
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(boxMargin, boxTop, SCREEN_WIDTH - boxMargin * 2, boxHeight, 4)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(boxMargin, boxTop, SCREEN_WIDTH - boxMargin * 2, boxHeight, 4)

    -- Draw header title centered
    local dayCount = self.hotel and self.hotel.dayCount or 1
    Fonts.set(gfx.font.kVariantBold)
    local headerY = boxTop + 6
    gfx.drawTextAligned("Day " .. dayCount .. " Complete!", SCREEN_WIDTH / 2, headerY, kTextAlignment.center)

    -- Draw separator line
    Fonts.reset()
    local separatorY = boxTop + 24
    gfx.drawLine(boxMargin + 12, separatorY, SCREEN_WIDTH - boxMargin - 12, separatorY)

    -- Draw stats with compact layout
    local y = separatorY + 5
    local lineHeight = 14  -- Reduced line height
    local leftX = boxMargin + 15
    local rightX = SCREEN_WIDTH - boxMargin - 15

    -- Guest stats in a more compact format
    local checkIns = self.hotel and self.hotel.dailyCheckIns or 0
    local checkOuts = self.hotel and self.hotel.dailyCheckOuts or 0
    local rages = self.summary.rages or 0

    gfx.drawText("Check-ins: " .. checkIns, leftX, y)
    gfx.drawText("Check-outs: " .. checkOuts, leftX + 120, y)
    gfx.drawTextAligned("Rages: " .. rages, rightX, y, kTextAlignment.right)
    y = y + lineHeight

    -- Separator
    y = y + 2
    gfx.drawLine(boxMargin + 12, y, SCREEN_WIDTH - boxMargin - 12, y)
    y = y + 5

    -- Financial summary header
    Fonts.set(gfx.font.kVariantBold)
    gfx.drawText("Finances", leftX, y)
    Fonts.reset()
    y = y + lineHeight

    -- Earnings
    gfx.drawText("Room Earnings:", leftX, y)
    gfx.drawTextAligned("+" .. Utils.formatMoney(self.summary.earnings or 0), rightX, y, kTextAlignment.right)
    y = y + lineHeight

    -- Operating costs
    gfx.drawText("Operating Costs:", leftX, y)
    gfx.drawTextAligned("-" .. Utils.formatMoney(self.summary.operatingCost or 0), rightX, y, kTextAlignment.right)
    y = y + lineHeight

    -- Damage (only show if > 0)
    if (self.summary.damage or 0) > 0 then
        gfx.drawText("Rage Damage:", leftX, y)
        gfx.drawTextAligned("-" .. Utils.formatMoney(self.summary.damage), rightX, y, kTextAlignment.right)
        y = y + lineHeight
    end

    -- Net change line
    y = y + 2
    gfx.drawLine(leftX, y, rightX, y)
    y = y + 4

    -- Net change
    local netChange = self.summary.net or 0
    local netText = netChange >= 0 and ("+" .. Utils.formatMoney(netChange)) or ("-" .. Utils.formatMoney(math.abs(netChange)))
    Fonts.set(gfx.font.kVariantBold)
    gfx.drawText("Net:", leftX, y)
    gfx.drawTextAligned(netText, rightX, y, kTextAlignment.right)
    y = y + lineHeight

    -- Current balance
    gfx.drawText("Balance:", leftX, y)
    gfx.drawTextAligned(Utils.formatMoney(self.hotel.money), rightX, y, kTextAlignment.right)

    -- Draw button at bottom center
    local promptText = #self.newUnlocks > 0 and "A: See Unlocks" or "A: Start Next Day"
    Fonts.set(gfx.font.kVariantBold)
    local textWidth, textHeight = gfx.getTextSize(promptText)
    local buttonPadding = 10
    local buttonWidth = textWidth + buttonPadding * 2
    local buttonHeight = textHeight + 8
    local buttonX = (SCREEN_WIDTH - buttonWidth) / 2
    local buttonY = SCREEN_HEIGHT - buttonHeight - 8

    -- White background with black border
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(buttonX, buttonY, buttonWidth, buttonHeight, 4)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(buttonX, buttonY, buttonWidth, buttonHeight, 4)

    -- Draw button text
    gfx.drawTextAligned(promptText, SCREEN_WIDTH / 2, buttonY + 4, kTextAlignment.center)
end

function DayEndScene:drawUnlockScreen()
    local unlock = self.newUnlocks[self.currentUnlockIndex]

    -- Content box dimensions - leave room at bottom for button
    local boxMargin = 20
    local boxTop = 15
    local boxBottom = SCREEN_HEIGHT - 45
    local boxHeight = boxBottom - boxTop

    -- Draw white content box with border
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(boxMargin, boxTop, SCREEN_WIDTH - boxMargin * 2, boxHeight, 4)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(boxMargin, boxTop, SCREEN_WIDTH - boxMargin * 2, boxHeight, 4)

    -- Draw header title centered
    local headerY = boxTop + 10
    Fonts.set(gfx.font.kVariantBold)
    gfx.drawTextAligned("NEW UNLOCK!", SCREEN_WIDTH / 2, headerY, kTextAlignment.center)

    -- Draw unlock info box (wider to fit challenge text)
    local infoBoxWidth = 340
    local infoBoxHeight = 90
    local infoBoxX = (SCREEN_WIDTH - infoBoxWidth) / 2
    local infoBoxY = boxTop + 40

    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(infoBoxX, infoBoxY, infoBoxWidth, infoBoxHeight, 6)

    -- Draw unlock name
    Fonts.set(gfx.font.kVariantBold)
    gfx.drawTextAligned(unlock.name or "Unknown", SCREEN_WIDTH / 2, infoBoxY + 12, kTextAlignment.center)

    -- Draw challenge description (use 'challenge' field from data)
    Fonts.reset()
    local challenge = unlock.challenge or ""
    gfx.drawTextAligned(challenge, SCREEN_WIDTH / 2, infoBoxY + 35, kTextAlignment.center)

    -- Draw effect with nicer formatting
    Fonts.set(gfx.font.kVariantItalic)
    local effectType = unlock.type == UNLOCKABLE_TYPE.PATIENCE and "Patience" or "Cost Reduction"
    local effectValue = unlock.effect or 0
    local effectText
    if unlock.type == UNLOCKABLE_TYPE.PATIENCE then
        effectText = effectType .. ": +" .. effectValue .. " sec"
    else
        effectText = effectType .. ": +$" .. effectValue
    end
    gfx.drawTextAligned(effectText, SCREEN_WIDTH / 2, infoBoxY + 58, kTextAlignment.center)

    -- Draw progress indicator
    Fonts.reset()
    local progressText = "Unlock " .. self.currentUnlockIndex .. " of " .. #self.newUnlocks
    gfx.drawTextAligned(progressText, SCREEN_WIDTH / 2, infoBoxY + 75, kTextAlignment.center)

    -- Draw button at bottom center
    local promptText = self.currentUnlockIndex < #self.newUnlocks and "A: Next Unlock" or "A: Start Next Day"
    Fonts.set(gfx.font.kVariantBold)
    local textWidth, textHeight = gfx.getTextSize(promptText)
    local buttonPadding = 10
    local buttonWidth = textWidth + buttonPadding * 2
    local buttonHeight = textHeight + 8
    local buttonX = (SCREEN_WIDTH - buttonWidth) / 2
    local buttonY = SCREEN_HEIGHT - buttonHeight - 8

    -- White background with black border
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(buttonX, buttonY, buttonWidth, buttonHeight, 4)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(buttonX, buttonY, buttonWidth, buttonHeight, 4)

    -- Draw button text
    gfx.drawTextAligned(promptText, SCREEN_WIDTH / 2, buttonY + 4, kTextAlignment.center)
end

function DayEndScene:AButtonDown()
    self:handleContinue()
end

function DayEndScene:BButtonDown()
    self:handleContinue()
end

function DayEndScene:cranked(change, acceleratedChange)
    if math.abs(change) > 10 then
        self:handleContinue()
    end
end

function DayEndScene:handleContinue()
    -- If we have unlocks to show, show them first
    if #self.newUnlocks > 0 and not self.showingUnlock then
        self.showingUnlock = true
        self.currentUnlockIndex = 1
        return
    end

    -- If showing unlocks, advance to next or finish
    if self.showingUnlock then
        if self.currentUnlockIndex < #self.newUnlocks then
            self.currentUnlockIndex = self.currentUnlockIndex + 1
            return
        end
    end

    -- Continue to next day
    SceneManager:switch(GameScene, {
        isNewGame = false,
        saveSlot = self.saveSlot
    })

    -- Start next day in game scene
    if GameScene.startNextDay then
        GameScene:startNextDay()
    end
end

return DayEndScene
