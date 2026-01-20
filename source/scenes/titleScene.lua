-- Monster Hotel - Title Scene
-- Starting screen with title graphic and "press any button" prompt

import "scenes/sceneManager"

local gfx <const> = playdate.graphics

TitleScene = {}

-- Static title card image
TitleScene.titleImage = nil

function TitleScene:enter()
    -- Load title card image
    if TitleScene.titleImage == nil then
        TitleScene.titleImage = gfx.image.new("images/title-card")
    end

    -- Reset any previous state
    self.blinkTimer = 0
    self.showPrompt = true
    self.blinkInterval = 30  -- Blink every 30 frames (1 second at 30fps)
end

function TitleScene:exit()
    -- Clean up if needed
end

function TitleScene:update()
    -- Blink the "press any button" text
    self.blinkTimer = self.blinkTimer + 1
    if self.blinkTimer >= self.blinkInterval then
        self.blinkTimer = 0
        self.showPrompt = not self.showPrompt
    end
end

function TitleScene:draw()
    gfx.clear(gfx.kColorWhite)

    -- Draw title card image
    if TitleScene.titleImage then
        TitleScene.titleImage:draw(0, 0)
    end

    -- Draw blinking prompt at bottom with background for readability
    if self.showPrompt then
        local promptText = "Press Any Button"
        gfx.setFont(gfx.getSystemFont(gfx.font.kVariantBold))
        local textWidth, textHeight = gfx.getTextSize(promptText)
        local textX = (SCREEN_WIDTH - textWidth) / 2
        local textY = 218

        -- Draw white background rectangle with padding
        local padding = 6
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(textX - padding, textY - padding/2, textWidth + padding*2, textHeight + padding)

        -- Draw black border
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(textX - padding, textY - padding/2, textWidth + padding*2, textHeight + padding)

        -- Draw text
        gfx.drawText(promptText, textX, textY)
    end
end

function TitleScene:AButtonDown()
    self:goToMenu()
end

function TitleScene:BButtonDown()
    self:goToMenu()
end

function TitleScene:upButtonDown()
    self:goToMenu()
end

function TitleScene:downButtonDown()
    self:goToMenu()
end

function TitleScene:leftButtonDown()
    self:goToMenu()
end

function TitleScene:rightButtonDown()
    self:goToMenu()
end

function TitleScene:cranked(change, acceleratedChange)
    if math.abs(change) > 5 then
        self:goToMenu()
    end
end

function TitleScene:goToMenu()
    SceneManager:switch(MenuScene)
end

return TitleScene
