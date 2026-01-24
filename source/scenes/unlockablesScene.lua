-- Monster Hotel - Unlockables Scene
-- Shows all unlockables and their status

import "scenes/sceneManager"
import "systems/unlockSystem"

local gfx <const> = playdate.graphics

UnlockablesScene = {}

-- Static assets
UnlockablesScene.backgroundPattern = nil

function UnlockablesScene.loadAssets()
    if UnlockablesScene.backgroundPattern == nil then
        UnlockablesScene.backgroundPattern = gfx.image.new("images/ui/backgrounds/pattern-dots")
    end
end

-- Layout constants
local HEADER_HEIGHT = 45  -- Fixed header area
local ITEM_START_Y = HEADER_HEIGHT + 2
local ITEM_HEIGHT = 50  -- Taller boxes for better spacing
local VISIBLE_ITEMS = 4

function UnlockablesScene:enter()
    -- Load assets
    UnlockablesScene.loadAssets()

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
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- Draw tiled background pattern
    if UnlockablesScene.backgroundPattern then
        for x = 0, SCREEN_WIDTH, 8 do
            for y = 0, SCREEN_HEIGHT, 8 do
                UnlockablesScene.backgroundPattern:draw(x, y)
            end
        end
    else
        gfx.clear(gfx.kColorWhite)
    end

    -- Draw unlockables list items (before header so header covers them)
    for i, item in ipairs(self.unlockables) do
        local y = ITEM_START_Y + (i - 1 - self.scrollOffset) * ITEM_HEIGHT

        -- Skip if completely above content area or below screen
        if y < ITEM_START_Y - ITEM_HEIGHT or y > SCREEN_HEIGHT then
            goto continue
        end

        -- Draw white item background box
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(10, y, SCREEN_WIDTH - 20, ITEM_HEIGHT - 5, 4)
        gfx.setColor(gfx.kColorBlack)

        -- Draw item border (thicker for selected)
        if i == self.selectedIndex then
            gfx.drawRoundRect(10, y, SCREEN_WIDTH - 20, ITEM_HEIGHT - 5, 4)
            gfx.drawRoundRect(11, y + 1, SCREEN_WIDTH - 22, ITEM_HEIGHT - 7, 3)
            gfx.drawRoundRect(12, y + 2, SCREEN_WIDTH - 24, ITEM_HEIGHT - 9, 3)
        else
            gfx.drawRoundRect(10, y, SCREEN_WIDTH - 20, ITEM_HEIGHT - 5, 4)
        end

        -- Draw item content with better margins
        Fonts.set(gfx.font.kVariantBold)
        local nameText = item.data.name
        if item.unlocked then
            nameText = nameText .. " [UNLOCKED]"
        end
        gfx.drawText(nameText, 20, y + 8)

        Fonts.reset()
        if item.unlocked then
            -- Show effect
            local effectText = item.data.type .. " +" .. item.data.effect
            gfx.drawText(effectText, 20, y + 26)
        else
            -- Show challenge (hint)
            Fonts.set(gfx.font.kVariantItalic)
            gfx.drawText(item.data.challenge, 20, y + 26)
        end

        ::continue::
    end

    -- Draw fixed header area (white box that covers any scrolled content)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, SCREEN_WIDTH, HEADER_HEIGHT)
    gfx.setColor(gfx.kColorBlack)

    -- Draw header with two columns: back button on left, title/progress on right
    -- Left column: back instruction
    Fonts.reset()
    gfx.drawText("< B", 12, 18)

    -- Center/right: title and progress
    Fonts.set(gfx.font.kVariantBold)
    gfx.drawTextAligned("UNLOCKABLES", SCREEN_WIDTH / 2 + 20, 10, kTextAlignment.center)

    -- Draw progress
    local unlockedCount = UnlockSystem:getUnlockedCount()
    local totalCount = UnlockSystem:getTotalCount()
    Fonts.reset()
    gfx.drawTextAligned(unlockedCount .. "/" .. totalCount .. " Unlocked", SCREEN_WIDTH / 2 + 20, 26, kTextAlignment.center)

    -- Draw header bottom border
    gfx.drawLine(0, HEADER_HEIGHT - 1, SCREEN_WIDTH, HEADER_HEIGHT - 1)
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
    if self.selectedIndex > self.scrollOffset + VISIBLE_ITEMS then
        self.scrollOffset = self.selectedIndex - VISIBLE_ITEMS
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
