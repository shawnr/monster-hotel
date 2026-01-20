-- Monster Hotel - Scene Manager
-- Simple state machine for managing game scenes

SceneManager = {}
SceneManager.currentScene = nil
SceneManager.previousScene = nil

-- Switch to a new scene
-- @param newScene: The scene object to switch to
-- @param ...: Optional arguments to pass to the scene's enter function
function SceneManager:switch(newScene, ...)
    -- Exit current scene if it exists
    if self.currentScene and self.currentScene.exit then
        self.currentScene:exit()
    end

    -- Store previous scene reference (useful for pause overlay)
    self.previousScene = self.currentScene

    -- Set and enter new scene
    self.currentScene = newScene
    if self.currentScene and self.currentScene.enter then
        self.currentScene:enter(...)
    end
end

-- Return to the previous scene (useful for pause menu)
function SceneManager:back()
    if self.previousScene then
        self:switch(self.previousScene)
    end
end

-- Update the current scene
function SceneManager:update()
    if self.currentScene and self.currentScene.update then
        self.currentScene:update()
    end
end

-- Draw the current scene
function SceneManager:draw()
    if self.currentScene and self.currentScene.draw then
        self.currentScene:draw()
    end
end

-- Handle A button press
function SceneManager:AButtonDown()
    if self.currentScene and self.currentScene.AButtonDown then
        self.currentScene:AButtonDown()
    end
end

-- Handle A button release
function SceneManager:AButtonUp()
    if self.currentScene and self.currentScene.AButtonUp then
        self.currentScene:AButtonUp()
    end
end

-- Handle B button press
function SceneManager:BButtonDown()
    if self.currentScene and self.currentScene.BButtonDown then
        self.currentScene:BButtonDown()
    end
end

-- Handle B button release
function SceneManager:BButtonUp()
    if self.currentScene and self.currentScene.BButtonUp then
        self.currentScene:BButtonUp()
    end
end

-- Handle D-pad
function SceneManager:upButtonDown()
    if self.currentScene and self.currentScene.upButtonDown then
        self.currentScene:upButtonDown()
    end
end

function SceneManager:downButtonDown()
    if self.currentScene and self.currentScene.downButtonDown then
        self.currentScene:downButtonDown()
    end
end

function SceneManager:leftButtonDown()
    if self.currentScene and self.currentScene.leftButtonDown then
        self.currentScene:leftButtonDown()
    end
end

function SceneManager:rightButtonDown()
    if self.currentScene and self.currentScene.rightButtonDown then
        self.currentScene:rightButtonDown()
    end
end

-- Handle crank
function SceneManager:cranked(change, acceleratedChange)
    if self.currentScene and self.currentScene.cranked then
        self.currentScene:cranked(change, acceleratedChange)
    end
end

return SceneManager
