-- Monster Hotel - Game Over Scene
-- Shows final stats and returns to menu

import "scenes/sceneManager"

local gfx <const> = playdate.graphics

GameOverScene = {}

function GameOverScene:enter(options)
    options = options or {}

    self.hotel = options.hotel
    self.summary = options.summary or {}

    -- Animation
    self.fadeIn = 0

    -- Update lifetime stats
    local gameStats = {
        maxMoney = self.hotel.maxMoneyReached,
        guestsServed = self.hotel.guestsServed,
        maxLevel = self.hotel.level,
        daysCompleted = self.hotel.dayCount,
        totalRages = self.hotel.totalRages
    }
    UnlockSystem:updateLifetimeStats(gameStats)

    -- Check for any final unlocks
    UnlockSystem:checkForUnlocks(gameStats)
end

function GameOverScene:exit()
    -- Nothing to clean up
end

function GameOverScene:update()
    -- Fade in
    if self.fadeIn < 1 then
        self.fadeIn = self.fadeIn + 0.02
    end
end

function GameOverScene:draw()
    -- Black background
    gfx.clear(gfx.kColorBlack)

    if self.fadeIn < 0.3 then return end

    -- Draw title
    gfx.setImageDrawMode(gfx.kDrawModeInverted)
    Fonts.set(gfx.font.kVariantBold)
    gfx.drawTextAligned("GAME OVER", SCREEN_WIDTH / 2, 30, kTextAlignment.center)

    -- Draw hotel closed message
    Fonts.reset()
    gfx.drawTextAligned("The Monster Hotel has closed its doors.", SCREEN_WIDTH / 2, 60, kTextAlignment.center)

    -- Draw final stats
    local startY = 95
    local spacing = 22

    local stats = {
        { label = "Days Survived", value = tostring(self.hotel.dayCount) },
        { label = "Guests Served", value = tostring(self.hotel.guestsServed) },
        { label = "Max Level", value = tostring(self.hotel.level) },
        { label = "Peak Balance", value = Utils.formatMoney(self.hotel.maxMoneyReached) },
        { label = "Monsters Raged", value = tostring(self.hotel.totalRages) }
    }

    for i, stat in ipairs(stats) do
        local y = startY + (i - 1) * spacing
        gfx.drawText(stat.label .. ":", 60, y)
        gfx.drawTextAligned(stat.value, SCREEN_WIDTH - 60, y, kTextAlignment.right)
    end

    -- Draw continue prompt
    Fonts.set(gfx.font.kVariantItalic)
    gfx.drawTextAligned("Press any button to return to menu", SCREEN_WIDTH / 2, SCREEN_HEIGHT - 30, kTextAlignment.center)

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function GameOverScene:AButtonDown()
    self:returnToMenu()
end

function GameOverScene:BButtonDown()
    self:returnToMenu()
end

function GameOverScene:cranked(change, acceleratedChange)
    if math.abs(change) > 5 then
        self:returnToMenu()
    end
end

function GameOverScene:returnToMenu()
    SceneManager:switch(MenuScene)
end

return GameOverScene
