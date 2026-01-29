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

-- Static assets
MenuScene.backgroundImage = nil
MenuScene.titleImage = nil
MenuScene.buttonNormal = nil
MenuScene.buttonHighlight = nil
MenuScene.menuBgNormal = nil
MenuScene.menuBgHighlight = nil

-- Layout constants
local TITLE_Y = 15
local MENU_START_Y = 105  -- More space after title
local MENU_SPACING = 45
local BUTTON_GAP = 8  -- Gap between button and menu bg
local TEXT_LEFT_PADDING = 12  -- Padding for left-aligned text
local INSTRUCTIONS_Y = 218

-- Helper function to draw text with outline/stroke for better readability
local function drawTextWithOutline(text, x, y, textColor, outlineColor, thick)
    -- Draw outline by drawing text at 8 offset positions
    if outlineColor == gfx.kColorWhite then
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    else
        gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    end

    -- Draw outline in all 8 directions (or more for thick outline)
    local radius = thick and 2 or 1
    for dx = -radius, radius do
        for dy = -radius, radius do
            if dx ~= 0 or dy ~= 0 then
                gfx.drawText(text, x + dx, y + dy)
            end
        end
    end

    -- Draw main text on top
    if textColor == gfx.kColorWhite then
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    else
        gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    end
    gfx.drawText(text, x, y)

    -- Reset draw mode
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function MenuScene.loadAssets()
    if MenuScene.backgroundImage == nil then
        MenuScene.backgroundImage = gfx.image.new("images/ui/menu/background")
        MenuScene.titleImage = gfx.image.new("images/ui/menu/title")
        MenuScene.buttonNormal = gfx.image.new("images/ui/menu/button-normal")
        MenuScene.buttonHighlight = gfx.image.new("images/ui/menu/button-highlight")
        MenuScene.menuBgNormal = gfx.image.new("images/ui/menu/menuitem-bg-normal")
        MenuScene.menuBgHighlight = gfx.image.new("images/ui/menu/menuitem-bg-highlight")
    end
end

function MenuScene:enter()
    -- Load assets
    MenuScene.loadAssets()

    self.selectedIndex = 1
    self.showingSaveSlots = false
    self.saveSlotIndex = 1
    self.saveSlots = {}

    -- Check for existing saves
    self:loadSaveSlotInfo()

    -- If no saves exist, start at "New Game"
    if not self:hasSaveData() then
        self.selectedIndex = 2
    end

    -- Music plays continuously from init, no action needed
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
    -- No animation needed currently
end

function MenuScene:draw()
    if self.showingSaveSlots then
        self:drawSaveSlots()
    else
        self:drawMainMenu()
    end
end

function MenuScene:drawMainMenu()
    -- Draw background
    if MenuScene.backgroundImage then
        MenuScene.backgroundImage:draw(0, 0)
    else
        gfx.clear(gfx.kColorWhite)
    end

    -- Draw title image centered
    if MenuScene.titleImage then
        local titleW, titleH = MenuScene.titleImage:getSize()
        MenuScene.titleImage:draw((SCREEN_WIDTH - titleW) / 2, TITLE_Y)
    end

    -- Draw menu options with bold font
    Fonts.set(gfx.font.kVariantBold)

    for i, option in ipairs(MENU_OPTIONS) do
        local y = MENU_START_Y + (i - 1) * MENU_SPACING
        local isSelected = (i == self.selectedIndex)
        local isDisabled = (i == 1 and not self:hasSaveData())

        -- Get the appropriate assets based on selection state
        local buttonImg = isSelected and MenuScene.buttonHighlight or MenuScene.buttonNormal
        local menuBgImg = isSelected and MenuScene.menuBgHighlight or MenuScene.menuBgNormal

        if buttonImg and menuBgImg then
            local buttonW, buttonH = buttonImg:getSize()
            local bgW, bgH = menuBgImg:getSize()

            -- Calculate total width for centering: button + gap + bg
            local totalWidth = buttonW + BUTTON_GAP + bgW
            local startX = (SCREEN_WIDTH - totalWidth) / 2

            -- Center the item vertically within its row
            local rowCenterY = y

            -- Draw button (vertically centered in row)
            local buttonY = rowCenterY - buttonH / 2
            buttonImg:draw(startX, buttonY)

            -- Draw menu background (vertically centered in row)
            local bgX = startX + buttonW + BUTTON_GAP
            local bgY = rowCenterY - bgH / 2
            menuBgImg:draw(bgX, bgY)

            -- Draw text on the menu background (left-aligned with padding)
            local text = option
            local textX = bgX + TEXT_LEFT_PADDING
            local textY = bgY + (bgH / 2) - 8  -- Adjust for font height

            if isSelected then
                -- Selected: black text on light background (no outline needed)
                gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
                gfx.drawText(text, textX, textY)
                gfx.setImageDrawMode(gfx.kDrawModeCopy)
            else
                -- Unselected: white text with black outline on dark background
                if isDisabled then
                    -- Dimmed appearance for disabled items
                    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
                    gfx.drawText(text, textX, textY)
                    gfx.setImageDrawMode(gfx.kDrawModeCopy)
                else
                    drawTextWithOutline(text, textX, textY, gfx.kColorWhite, gfx.kColorBlack)
                end
            end
        end
    end

    -- Draw instructions at bottom (white text with thick black outline for readability)
    Fonts.reset()
    Fonts.set(gfx.font.kVariantBold)
    drawTextWithOutline("up/down to select, A to confirm",
        SCREEN_WIDTH / 2 - gfx.getTextSize("up/down to select, A to confirm") / 2,
        INSTRUCTIONS_Y, gfx.kColorWhite, gfx.kColorBlack, true)
end

function MenuScene:drawSaveSlots()
    -- Draw background
    if MenuScene.backgroundImage then
        MenuScene.backgroundImage:draw(0, 0)
    else
        gfx.clear(gfx.kColorWhite)
    end

    -- Draw title image centered (same as main menu)
    if MenuScene.titleImage then
        local titleW, titleH = MenuScene.titleImage:getSize()
        MenuScene.titleImage:draw((SCREEN_WIDTH - titleW) / 2, TITLE_Y)
    end

    -- Draw save slots using the same button/bg style as main menu
    Fonts.set(gfx.font.kVariantBold)

    for i = 1, 3 do
        local y = MENU_START_Y + (i - 1) * MENU_SPACING
        local slot = self.saveSlots[i]
        local isSelected = (i == self.saveSlotIndex)

        -- Get the appropriate assets based on selection state
        local buttonImg = isSelected and MenuScene.buttonHighlight or MenuScene.buttonNormal
        local menuBgImg = isSelected and MenuScene.menuBgHighlight or MenuScene.menuBgNormal

        if buttonImg and menuBgImg then
            local buttonW, buttonH = buttonImg:getSize()
            local bgW, bgH = menuBgImg:getSize()

            -- Calculate total width for centering: button + gap + bg
            local totalWidth = buttonW + BUTTON_GAP + bgW
            local startX = (SCREEN_WIDTH - totalWidth) / 2

            -- Center the item vertically within its row
            local rowCenterY = y

            -- Draw button (vertically centered in row)
            local buttonY = rowCenterY - buttonH / 2
            buttonImg:draw(startX, buttonY)

            -- Draw menu background (vertically centered in row)
            local bgX = startX + buttonW + BUTTON_GAP
            local bgY = rowCenterY - bgH / 2
            menuBgImg:draw(bgX, bgY)

            -- Draw text on the menu background (left-aligned with padding)
            local text
            if slot.exists then
                text = "Slot " .. i .. " - Day " .. slot.day
            else
                text = "Slot " .. i .. " - Empty"
            end

            local textX = bgX + TEXT_LEFT_PADDING
            local textY = bgY + (bgH / 2) - 8  -- Adjust for font height

            if isSelected then
                -- Selected: black text with white outline for better visibility on light background
                drawTextWithOutline(text, textX, textY, gfx.kColorBlack, gfx.kColorWhite, true)
            else
                -- Unselected: white text with black outline on dark background
                drawTextWithOutline(text, textX, textY, gfx.kColorWhite, gfx.kColorBlack, true)
            end
        end
    end

    -- Draw instructions at bottom (white text with thick black outline for readability)
    Fonts.reset()
    Fonts.set(gfx.font.kVariantBold)
    drawTextWithOutline("A to select, B to go back",
        SCREEN_WIDTH / 2 - gfx.getTextSize("A to select, B to go back") / 2,
        INSTRUCTIONS_Y, gfx.kColorWhite, gfx.kColorBlack, true)
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
