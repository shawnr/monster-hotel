-- Monster Hotel - Menu Scene
-- Continue/New Game/Unlockables menu

import "scenes/sceneManager"
import "systems/saveSystem"

local gfx <const> = playdate.graphics

MenuScene = {}

-- Menu options
local MENU_OPTIONS = {
    "Continue",
    "New Game",
    "Unlockables"
}

-- Animation frame sequence from animation.txt: 1x2,2x2,3x2,...
local HIGHLIGHT_ANIMATION = {
    {frame=1, duration=2}, {frame=2, duration=2}, {frame=3, duration=2}, {frame=4, duration=2},
    {frame=5, duration=2}, {frame=6, duration=2}, {frame=7, duration=2}, {frame=8, duration=2},
    {frame=9, duration=2}, {frame=10, duration=2}, {frame=11, duration=2}, {frame=12, duration=2},
    {frame=13, duration=1}, {frame=14, duration=1}, {frame=15, duration=1}, {frame=16, duration=1},
    {frame=12, duration=1}, {frame=11, duration=1}, {frame=16, duration=1}
}

-- Static assets
MenuScene.highlightImages = nil

function MenuScene.loadAssets()
    if MenuScene.highlightImages == nil then
        MenuScene.highlightImages = gfx.imagetable.new("images/ui/card-highlighted/card-highlighted")
    end
end

function MenuScene:enter()
    -- Load assets
    MenuScene.loadAssets()

    self.selectedIndex = 1
    self.showingSaveSlots = false
    self.saveSlotIndex = 1
    self.saveSlots = {}

    -- Animation state
    self.animFrame = 1
    self.animTick = 0

    -- Check for existing saves
    self:loadSaveSlotInfo()

    -- If no saves exist, start at "New Game"
    if not self:hasSaveData() then
        self.selectedIndex = 2
    end
end

function MenuScene:exit()
    -- Clean up
end

function MenuScene:loadSaveSlotInfo()
    self.saveSlots = {}
    for i = 1, 3 do
        local saveData = SaveSystem:load(i)
        if saveData then
            self.saveSlots[i] = {
                exists = true,
                savedAt = saveData.savedAt or "Unknown",
                day = saveData.hotel and saveData.hotel.dayCount or 1,
                money = saveData.hotel and saveData.hotel.money or 0,
                level = saveData.hotel and saveData.hotel.level or 1
            }
        else
            self.saveSlots[i] = { exists = false }
        end
    end
end

function MenuScene:hasSaveData()
    for i = 1, 3 do
        if self.saveSlots[i] and self.saveSlots[i].exists then
            return true
        end
    end
    return false
end

function MenuScene:update()
    -- Update animation
    if self.showingSaveSlots and MenuScene.highlightImages then
        self.animTick = self.animTick + 1
        local currentAnim = HIGHLIGHT_ANIMATION[self.animFrame]
        if self.animTick >= currentAnim.duration then
            self.animTick = 0
            self.animFrame = self.animFrame + 1
            if self.animFrame > #HIGHLIGHT_ANIMATION then
                self.animFrame = 1
            end
        end
    end
end

function MenuScene:draw()
    gfx.clear(gfx.kColorWhite)

    if self.showingSaveSlots then
        self:drawSaveSlots()
    else
        self:drawMainMenu()
    end
end

function MenuScene:drawMainMenu()
    -- Draw title
    gfx.setFont(gfx.getSystemFont(gfx.font.kVariantBold))
    gfx.drawTextAligned("MONSTER HOTEL", SCREEN_WIDTH / 2, 30, kTextAlignment.center)

    -- Draw menu options
    gfx.setFont(gfx.getSystemFont())
    local startY = 80
    local spacing = 40

    for i, option in ipairs(MENU_OPTIONS) do
        local y = startY + (i - 1) * spacing
        local text = option
        local isDisabled = (i == 1 and not self:hasSaveData())

        -- Disable "Continue" if no saves
        if isDisabled then
            text = option .. " (No saves)"
        end

        -- Draw selection indicator
        if i == self.selectedIndex then
            gfx.fillTriangle(
                SCREEN_WIDTH / 2 - 80, y + 8,
                SCREEN_WIDTH / 2 - 70, y + 4,
                SCREEN_WIDTH / 2 - 70, y + 12
            )
        end

        gfx.drawTextAligned(text, SCREEN_WIDTH / 2, y, kTextAlignment.center)
    end

    -- Draw instructions
    gfx.setFont(gfx.getSystemFont(gfx.font.kVariantItalic))
    gfx.drawTextAligned("Up/Down to select, A to confirm", SCREEN_WIDTH / 2, 210, kTextAlignment.center)
end

function MenuScene:drawSaveSlots()
    -- Draw animated background if available
    if MenuScene.highlightImages then
        local frameData = HIGHLIGHT_ANIMATION[self.animFrame]
        local img = MenuScene.highlightImages:getImage(frameData.frame)
        if img then
            img:draw(0, 0)
        end
    end

    -- Draw header with background for readability
    gfx.setFont(gfx.getSystemFont(gfx.font.kVariantBold))
    local headerText = "Select Save Slot"
    local headerWidth, headerHeight = gfx.getTextSize(headerText)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect((SCREEN_WIDTH - headerWidth) / 2 - 10, 15, headerWidth + 20, headerHeight + 10)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawTextAligned(headerText, SCREEN_WIDTH / 2, 20, kTextAlignment.center)

    -- Draw save slots
    gfx.setFont(gfx.getSystemFont())
    local startY = 60
    local slotHeight = 50

    for i = 1, 3 do
        local y = startY + (i - 1) * slotHeight
        local slot = self.saveSlots[i]

        -- Draw slot box with white background for readability
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(20, y, SCREEN_WIDTH - 40, slotHeight - 5, 4)
        gfx.setColor(gfx.kColorBlack)

        if i == self.saveSlotIndex then
            -- Draw thick border for selected slot
            gfx.drawRoundRect(20, y, SCREEN_WIDTH - 40, slotHeight - 5, 4)
            gfx.drawRoundRect(21, y + 1, SCREEN_WIDTH - 42, slotHeight - 7, 4)
            gfx.drawRoundRect(22, y + 2, SCREEN_WIDTH - 44, slotHeight - 9, 4)
        else
            gfx.drawRoundRect(20, y, SCREEN_WIDTH - 40, slotHeight - 5, 4)
        end

        -- Draw slot info
        if slot.exists then
            gfx.drawText("Slot " .. i .. " - Day " .. slot.day, 30, y + 5)
            gfx.drawText("Level " .. slot.level .. " | " .. Utils.formatMoney(slot.money), 30, y + 22)
        else
            gfx.drawText("Slot " .. i .. " - Empty", 30, y + 12)
        end
    end

    -- Draw instructions with background
    gfx.setFont(gfx.getSystemFont(gfx.font.kVariantItalic))
    local instrText = "A to select, B to go back"
    local instrWidth, instrHeight = gfx.getTextSize(instrText)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect((SCREEN_WIDTH - instrWidth) / 2 - 6, 212, instrWidth + 12, instrHeight + 6)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawTextAligned(instrText, SCREEN_WIDTH / 2, 215, kTextAlignment.center)
end

function MenuScene:upButtonDown()
    if self.showingSaveSlots then
        self.saveSlotIndex = self.saveSlotIndex - 1
        if self.saveSlotIndex < 1 then
            self.saveSlotIndex = 3
        end
    else
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then
            self.selectedIndex = #MENU_OPTIONS
        end
        -- Skip Continue if no saves
        if self.selectedIndex == 1 and not self:hasSaveData() then
            self.selectedIndex = #MENU_OPTIONS
        end
    end
end

function MenuScene:downButtonDown()
    if self.showingSaveSlots then
        self.saveSlotIndex = self.saveSlotIndex + 1
        if self.saveSlotIndex > 3 then
            self.saveSlotIndex = 1
        end
    else
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #MENU_OPTIONS then
            self.selectedIndex = 1
        end
        -- Skip Continue if no saves
        if self.selectedIndex == 1 and not self:hasSaveData() then
            self.selectedIndex = 2
        end
    end
end

function MenuScene:AButtonDown()
    if self.showingSaveSlots then
        self:selectSaveSlot()
    else
        self:selectMenuOption()
    end
end

function MenuScene:BButtonDown()
    if self.showingSaveSlots then
        self.showingSaveSlots = false
    else
        SceneManager:switch(TitleScene)
    end
end

function MenuScene:selectMenuOption()
    local option = MENU_OPTIONS[self.selectedIndex]

    if option == "Continue" then
        if self:hasSaveData() then
            self.showingSaveSlots = true
            self.isNewGame = false
        end
    elseif option == "New Game" then
        self.showingSaveSlots = true
        self.isNewGame = true
    elseif option == "Unlockables" then
        SceneManager:switch(UnlockablesScene)
    end
end

function MenuScene:selectSaveSlot()
    local slot = self.saveSlots[self.saveSlotIndex]

    if self.isNewGame then
        -- Start new game in this slot
        SceneManager:switch(GameScene, {
            isNewGame = true,
            saveSlot = self.saveSlotIndex
        })
    else
        -- Continue from this slot
        if slot.exists then
            SceneManager:switch(GameScene, {
                isNewGame = false,
                saveSlot = self.saveSlotIndex
            })
        end
    end
end

return MenuScene
