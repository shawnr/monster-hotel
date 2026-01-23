-- Monster Hotel - Day End Scene
-- Shows day summary and continues to next day

import "scenes/sceneManager"

local gfx <const> = playdate.graphics

DayEndScene = {}

function DayEndScene:enter(options)
    options = options or {}

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
    -- Force white background
    gfx.clear(gfx.kColorWhite)
    gfx.setDrawOffset(0, 0)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    gfx.setColor(gfx.kColorBlack)

    -- Always draw something visible
    gfx.drawRect(10, 10, SCREEN_WIDTH - 20, SCREEN_HEIGHT - 20)

    if self.showingUnlock and self.currentUnlockIndex <= #self.newUnlocks then
        self:drawUnlockScreen()
    else
        self:drawSummaryScreen()
    end
end

function DayEndScene:drawSummaryScreen()
    -- Draw header
    local dayCount = self.hotel and self.hotel.dayCount or 1
    Fonts.set(gfx.font.kVariantBold)
    gfx.drawTextAligned("Day " .. dayCount .. " Complete!", SCREEN_WIDTH / 2, 15, kTextAlignment.center)

    -- Draw separator line
    gfx.drawLine(20, 35, SCREEN_WIDTH - 20, 35)

    -- Draw stats
    Fonts.reset()
    local y = 45
    local lineHeight = 18

    -- Guests checked in (use hotel's daily stats)
    local checkIns = self.hotel and self.hotel.dailyCheckIns or 0
    gfx.drawText("Guests Checked In:", 25, y)
    gfx.drawTextAligned(tostring(checkIns), SCREEN_WIDTH - 35, y, kTextAlignment.right)
    y = y + lineHeight

    -- Guests checked out
    local checkOuts = self.hotel and self.hotel.dailyCheckOuts or 0
    gfx.drawText("Guests Checked Out:", 25, y)
    gfx.drawTextAligned(tostring(checkOuts), SCREEN_WIDTH - 35, y, kTextAlignment.right)
    y = y + lineHeight

    -- Monsters raged
    gfx.drawText("Monsters Raged:", 25, y)
    gfx.drawTextAligned(tostring(self.summary.rages or 0), SCREEN_WIDTH - 35, y, kTextAlignment.right)
    y = y + lineHeight

    -- Separator
    y = y + 3
    gfx.drawLine(20, y, SCREEN_WIDTH - 20, y)
    y = y + 10

    -- Financial summary
    Fonts.set(gfx.font.kVariantBold)
    gfx.drawText("Finances", 25, y)
    y = y + lineHeight

    Fonts.reset()

    -- Earnings
    gfx.drawText("  Room Earnings:", 25, y)
    gfx.drawTextAligned("+" .. Utils.formatMoney(self.summary.earnings or 0), SCREEN_WIDTH - 35, y, kTextAlignment.right)
    y = y + lineHeight

    -- Operating costs
    gfx.drawText("  Operating Costs:", 25, y)
    gfx.drawTextAligned("-" .. Utils.formatMoney(self.summary.operatingCost or 0), SCREEN_WIDTH - 35, y, kTextAlignment.right)
    y = y + lineHeight

    -- Damage (only show if > 0)
    if (self.summary.damage or 0) > 0 then
        gfx.drawText("  Rage Damage:", 25, y)
        gfx.drawTextAligned("-" .. Utils.formatMoney(self.summary.damage), SCREEN_WIDTH - 35, y, kTextAlignment.right)
        y = y + lineHeight
    end

    -- Net change line
    gfx.drawLine(25, y, SCREEN_WIDTH - 25, y)
    y = y + 4

    -- Net change
    local netChange = self.summary.net or 0
    local netText = netChange >= 0 and ("+" .. Utils.formatMoney(netChange)) or ("-" .. Utils.formatMoney(math.abs(netChange)))
    Fonts.set(gfx.font.kVariantBold)
    gfx.drawText("Net Change:", 25, y)
    gfx.drawTextAligned(netText, SCREEN_WIDTH - 35, y, kTextAlignment.right)
    y = y + lineHeight + 2

    -- Current balance
    gfx.drawText("Balance:", 25, y)
    gfx.drawTextAligned(Utils.formatMoney(self.hotel.money), SCREEN_WIDTH - 35, y, kTextAlignment.right)

    -- Draw continue prompt at bottom
    Fonts.set(gfx.font.kVariantItalic)
    if #self.newUnlocks > 0 then
        gfx.drawTextAligned("Press A to see unlocks", SCREEN_WIDTH / 2, SCREEN_HEIGHT - 20, kTextAlignment.center)
    else
        gfx.drawTextAligned("Press A to start next day", SCREEN_WIDTH / 2, SCREEN_HEIGHT - 20, kTextAlignment.center)
    end
end

function DayEndScene:drawUnlockScreen()
    local unlock = self.newUnlocks[self.currentUnlockIndex]

    -- Draw header
    Fonts.set(gfx.font.kVariantBold)
    gfx.drawTextAligned("NEW UNLOCK!", SCREEN_WIDTH / 2, 40, kTextAlignment.center)

    -- Draw unlock box
    local boxWidth = 300
    local boxHeight = 100
    local boxX = (SCREEN_WIDTH - boxWidth) / 2
    local boxY = 70

    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(boxX, boxY, boxWidth, boxHeight, 8)
    gfx.drawRoundRect(boxX + 1, boxY + 1, boxWidth - 2, boxHeight - 2, 7)

    -- Draw unlock info
    Fonts.set(gfx.font.kVariantBold)
    gfx.drawTextAligned(unlock.name or "Unknown", SCREEN_WIDTH / 2, boxY + 20, kTextAlignment.center)

    Fonts.reset()
    local description = unlock.description or ""
    gfx.drawTextAligned(description, SCREEN_WIDTH / 2, boxY + 45, kTextAlignment.center)

    Fonts.set(gfx.font.kVariantItalic)
    local effectText = (unlock.type or "Bonus") .. ": +" .. (unlock.effect or "?")
    gfx.drawTextAligned(effectText, SCREEN_WIDTH / 2, boxY + 70, kTextAlignment.center)

    -- Draw progress indicator
    local progressText = "Unlock " .. self.currentUnlockIndex .. " of " .. #self.newUnlocks
    gfx.drawTextAligned(progressText, SCREEN_WIDTH / 2, SCREEN_HEIGHT - 45, kTextAlignment.center)

    -- Draw continue prompt
    if self.currentUnlockIndex < #self.newUnlocks then
        gfx.drawTextAligned("Press A for next unlock", SCREEN_WIDTH / 2, SCREEN_HEIGHT - 20, kTextAlignment.center)
    else
        gfx.drawTextAligned("Press A to start next day", SCREEN_WIDTH / 2, SCREEN_HEIGHT - 20, kTextAlignment.center)
    end
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
