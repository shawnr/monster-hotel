-- Monster Hotel - Pause Scene
-- Pause overlay with menu options

import "scenes/sceneManager"

local gfx <const> = playdate.graphics

PauseScene = {}

local MENU_OPTIONS = {
    "Resume",
    "Save Game",
    "Main Menu",
    "Quit Game"
}

function PauseScene:enter(options)
    options = options or {}
    self.selectedIndex = 1
    self.action = options.action  -- Pre-selected action from system menu

    -- If action was specified, handle it
    if self.action == "mainMenu" then
        self.selectedIndex = 3
    end

    -- Store reference to game scene for resuming
    self.gameScene = SceneManager.previousScene
end

function PauseScene:exit()
    -- Nothing to clean up
end

function PauseScene:update()
    -- Menu logic in button callbacks
end

function PauseScene:draw()
    -- Draw semi-transparent overlay (using dithered pattern)
    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(0.5)
    gfx.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    gfx.setDitherPattern(0)

    -- Draw menu box
    local boxWidth = 200
    local boxHeight = 160
    local boxX = (SCREEN_WIDTH - boxWidth) / 2
    local boxY = (SCREEN_HEIGHT - boxHeight) / 2

    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(boxX, boxY, boxWidth, boxHeight, 8)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(boxX, boxY, boxWidth, boxHeight, 8)

    -- Draw title
    gfx.setFont(gfx.getSystemFont(gfx.font.kVariantBold))
    gfx.drawTextAligned("PAUSED", SCREEN_WIDTH / 2, boxY + 15, kTextAlignment.center)

    -- Draw menu options
    gfx.setFont(gfx.getSystemFont())
    local startY = boxY + 45
    local spacing = 28

    for i, option in ipairs(MENU_OPTIONS) do
        local y = startY + (i - 1) * spacing

        -- Draw selection indicator
        if i == self.selectedIndex then
            gfx.fillTriangle(
                boxX + 20, y + 6,
                boxX + 30, y + 2,
                boxX + 30, y + 10
            )
        end

        gfx.drawText(option, boxX + 40, y)
    end
end

function PauseScene:upButtonDown()
    self.selectedIndex = self.selectedIndex - 1
    if self.selectedIndex < 1 then
        self.selectedIndex = #MENU_OPTIONS
    end
end

function PauseScene:downButtonDown()
    self.selectedIndex = self.selectedIndex + 1
    if self.selectedIndex > #MENU_OPTIONS then
        self.selectedIndex = 1
    end
end

function PauseScene:AButtonDown()
    self:selectOption()
end

function PauseScene:BButtonDown()
    -- B to resume
    self:resume()
end

function PauseScene:selectOption()
    local option = MENU_OPTIONS[self.selectedIndex]

    if option == "Resume" then
        self:resume()
    elseif option == "Save Game" then
        if self.gameScene and self.gameScene.saveGame then
            self.gameScene:saveGame()
        end
        -- Show save confirmation briefly then resume
        self:resume()
    elseif option == "Main Menu" then
        -- Save before leaving
        if self.gameScene and self.gameScene.saveGame then
            self.gameScene:saveGame()
        end
        SceneManager:switch(MenuScene)
    elseif option == "Quit Game" then
        -- Save before quitting
        if self.gameScene and self.gameScene.saveGame then
            self.gameScene:saveGame()
        end
        -- Note: On actual Playdate, you might want to use a different exit method
        SceneManager:switch(TitleScene)
    end
end

function PauseScene:resume()
    if self.gameScene then
        SceneManager:switch(self.gameScene)
    else
        SceneManager:switch(MenuScene)
    end
end

return PauseScene
