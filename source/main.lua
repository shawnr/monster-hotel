-- Monster Hotel
-- An Elevator Management Rogue-like for Playdate
-- Main entry point

-- Import Playdate SDK libraries
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/crank"
import "CoreLibs/animation"

-- Import game modules
import "globals"
import "lib/utils"

-- Import scenes
import "scenes/sceneManager"
import "scenes/titleScene"
import "scenes/menuScene"
import "scenes/gameScene"
import "scenes/pauseScene"
import "scenes/dayEndScene"
import "scenes/gameOverScene"
import "scenes/unlockablesScene"

-- Import entities
import "entities/hotel"
import "entities/elevator"
import "entities/floor"
import "entities/room"
import "entities/lobby"
import "entities/monster"

-- Import systems
import "systems/timeSystem"
import "systems/spawnSystem"
import "systems/economySystem"
import "systems/saveSystem"
import "systems/unlockSystem"

-- Import UI
import "ui/hud"
import "ui/patienceIndicator"
import "ui/roomIndicator"

-- Import data
import "data/monsterData"
import "data/roomData"
import "data/elevatorData"
import "data/lobbyData"
import "data/unlockableData"

local gfx <const> = playdate.graphics

-- Initialize the game
function initialize()
    -- Set refresh rate
    playdate.display.setRefreshRate(GAME_TICK_RATE)

    -- Seed random number generator
    math.randomseed(playdate.getSecondsSinceEpoch())

    -- Set up system menu
    setupSystemMenu()

    -- Load unlockables (persistent across games)
    UnlockSystem:loadUnlockables()

    -- Start with title scene
    SceneManager:switch(TitleScene)
end

-- Set up the Playdate system menu
function setupSystemMenu()
    local menu = playdate.getSystemMenu()

    menu:addMenuItem("Save Game", function()
        if SceneManager.currentScene == GameScene then
            GameScene:saveGame()
        end
    end)

    menu:addMenuItem("Main Menu", function()
        if SceneManager.currentScene == GameScene then
            -- Confirm before leaving
            SceneManager:switch(PauseScene, { action = "mainMenu" })
        else
            SceneManager:switch(MenuScene)
        end
    end)
end

-- Main update function - called every frame
function playdate.update()
    -- Update all timers
    playdate.timer.updateTimers()

    -- Update current scene
    SceneManager:update()

    -- Update all sprites
    gfx.sprite.update()

    -- Draw current scene (for non-sprite elements)
    SceneManager:draw()
end

-- Input callbacks
function playdate.AButtonDown()
    SceneManager:AButtonDown()
end

function playdate.AButtonUp()
    SceneManager:AButtonUp()
end

function playdate.BButtonDown()
    SceneManager:BButtonDown()
end

function playdate.BButtonUp()
    SceneManager:BButtonUp()
end

function playdate.upButtonDown()
    SceneManager:upButtonDown()
end

function playdate.downButtonDown()
    SceneManager:downButtonDown()
end

function playdate.leftButtonDown()
    SceneManager:leftButtonDown()
end

function playdate.rightButtonDown()
    SceneManager:rightButtonDown()
end

function playdate.cranked(change, acceleratedChange)
    SceneManager:cranked(change, acceleratedChange)
end

-- Handle dock/undock for crank
function playdate.crankDocked()
    if SceneManager.currentScene and SceneManager.currentScene.crankDocked then
        SceneManager.currentScene:crankDocked()
    end
end

function playdate.crankUndocked()
    if SceneManager.currentScene and SceneManager.currentScene.crankUndocked then
        SceneManager.currentScene:crankUndocked()
    end
end

-- Game focus callbacks
function playdate.gameWillPause()
    -- Auto-save when going to background
    if SceneManager.currentScene == GameScene then
        GameScene:saveGame()
    end
end

-- Run initialization
initialize()
