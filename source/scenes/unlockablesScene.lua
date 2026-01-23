-- Monster Hotel - Unlockables Scene
-- Shows all unlockables and their status

import "scenes/sceneManager"
import "systems/unlockSystem"

local gfx <const> = playdate.graphics

UnlockablesScene = {}

function UnlockablesScene:enter()
    self.scrollOffset = 0
    self.selectedIndex = 1
    self.unlockables = UnlockSystem:getAllUnlockables()
end

function UnlockablesScene:exit()
    -- Nothing to clean up
end

function UnlockablesScene:update()
    -- Handle scrolling
end

function UnlockablesScene:draw()
    gfx.clear(gfx.kColorWhite)

    -- Draw header
    Fonts.set(gfx.font.kVariantBold)
    gfx.drawTextAligned("UNLOCKABLES", SCREEN_WIDTH / 2, 10, kTextAlignment.center)

    -- Draw progress
    local unlockedCount = UnlockSystem:getUnlockedCount()
    local totalCount = UnlockSystem:getTotalCount()
    Fonts.reset()
    gfx.drawTextAligned(unlockedCount .. "/" .. totalCount .. " Unlocked", SCREEN_WIDTH / 2, 28, kTextAlignment.center)

    -- Draw unlockables list
    local startY = 50
    local itemHeight = 45
    local visibleItems = 4

    for i, item in ipairs(self.unlockables) do
        local y = startY + (i - 1 - self.scrollOffset) * itemHeight

        -- Skip if off-screen
        if y < startY - itemHeight or y > SCREEN_HEIGHT then
            goto continue
        end

        -- Draw item background
        if i == self.selectedIndex then
            gfx.fillRoundRect(10, y, SCREEN_WIDTH - 20, itemHeight - 5, 4)
            gfx.setImageDrawMode(gfx.kDrawModeInverted)
        else
            gfx.drawRoundRect(10, y, SCREEN_WIDTH - 20, itemHeight - 5, 4)
        end

        -- Draw item content
        Fonts.set(gfx.font.kVariantBold)
        local nameText = item.data.name
        if item.unlocked then
            nameText = nameText .. " [UNLOCKED]"
        end
        gfx.drawText(nameText, 20, y + 5)

        Fonts.reset()
        if item.unlocked then
            -- Show effect
            local effectText = item.data.type .. " +" .. item.data.effect
            gfx.drawText(effectText, 20, y + 22)
        else
            -- Show challenge (hint)
            Fonts.set(gfx.font.kVariantItalic)
            gfx.drawText(item.data.challenge, 20, y + 22)
        end

        gfx.setImageDrawMode(gfx.kDrawModeCopy)

        ::continue::
    end

    -- Draw scroll indicators
    if self.scrollOffset > 0 then
        gfx.fillTriangle(SCREEN_WIDTH / 2, 45, SCREEN_WIDTH / 2 - 5, 50, SCREEN_WIDTH / 2 + 5, 50)
    end
    if self.scrollOffset < #self.unlockables - visibleItems then
        gfx.fillTriangle(SCREEN_WIDTH / 2, SCREEN_HEIGHT - 10, SCREEN_WIDTH / 2 - 5, SCREEN_HEIGHT - 15, SCREEN_WIDTH / 2 + 5, SCREEN_HEIGHT - 15)
    end

    -- Draw back instruction
    Fonts.set(gfx.font.kVariantItalic)
    gfx.drawText("B: Back", 10, SCREEN_HEIGHT - 15)
end

function UnlockablesScene:upButtonDown()
    self.selectedIndex = self.selectedIndex - 1
    if self.selectedIndex < 1 then
        self.selectedIndex = 1
    end

    -- Adjust scroll
    if self.selectedIndex <= self.scrollOffset then
        self.scrollOffset = self.selectedIndex - 1
    end
end

function UnlockablesScene:downButtonDown()
    self.selectedIndex = self.selectedIndex + 1
    if self.selectedIndex > #self.unlockables then
        self.selectedIndex = #self.unlockables
    end

    -- Adjust scroll
    local visibleItems = 4
    if self.selectedIndex > self.scrollOffset + visibleItems then
        self.scrollOffset = self.selectedIndex - visibleItems
    end
end

function UnlockablesScene:BButtonDown()
    SceneManager:switch(MenuScene)
end

function UnlockablesScene:cranked(change, acceleratedChange)
    if change > 0 then
        self:downButtonDown()
    elseif change < 0 then
        self:upButtonDown()
    end
end

return UnlockablesScene
