# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
# Build the game (requires Playdate SDK)
pdc source monster-hotel.pdx

# Clean rebuild (recommended after major changes)
rm -rf monster-hotel.pdx && pdc source monster-hotel.pdx

# Run in Playdate Simulator
open monster-hotel.pdx
```

## Architecture Overview

Monster Hotel is a Playdate elevator management rogue-like built in Lua using only the standard Playdate SDK.

### Scene-Based State Machine

The game uses a simple scene manager pattern (`source/scenes/sceneManager.lua`) that routes all input and update/draw calls to the current scene. Scenes implement optional lifecycle methods:
- `enter(options)` / `exit()` - scene transitions
- `update()` / `draw()` - game loop
- `AButtonDown()`, `BButtonDown()`, `cranked(change)`, etc. - input handling

Scene flow: TitleScene → MenuScene → GameScene ↔ PauseScene/DayEndScene → GameOverScene

**Scene Transition Gotchas**:
- GameScene uses `gfx.setDrawOffset(0, -cameraY)` for camera scrolling
- When switching to other scenes, MUST call `gfx.setDrawOffset(0, 0)` in enter() to reset
- Also call `gfx.sprite.removeAll()` and `gfx.setImageDrawMode(gfx.kDrawModeCopy)` to reset state

### Core Entity Hierarchy

```
Hotel (container, manually draws all children)
├── Lobby (special floor at bottom, holds waiting monsters)
├── Elevator (crank-controlled, manually drawn - NOT a sprite)
├── Floors[] (contain Rooms)
│   └── Rooms[] (SINGLE/DOUBLE/SUITE or service types)
└── Monsters[] (NPCs with state machine, manually drawn - NOT sprites)
```

**Important**: Elevator and Monster classes do NOT extend gfx.sprite. They use `class('Name').extends()` and are drawn manually by Hotel:draw(). This avoids coordinate system confusion between sprite positions and manual drawing.

### Coordinate System

- Y=0 is at the TOP of the hotel (highest floor)
- Y increases downward; lobby is at the bottom (highest Y value)
- Camera follows elevator with `gfx.setDrawOffset(0, -cameraY)`
- Each floor is 60 pixels tall (`FLOOR_HEIGHT`)

### Monster State Machine

Monsters progress through states defined in `globals.lua` (`MONSTER_STATE`):
```
WAITING_IN_LOBBY → ENTERING_ELEVATOR → RIDING_ELEVATOR → EXITING_TO_ROOM → IN_ROOM
                                                                              ↓
EXITING_HOTEL ← CHECKING_OUT ← WAITING_TO_CHECKOUT ←─────────────────────────┘
     ↑
RAGING (branches from any state when patience <= 0)
```

**Important**: State transitions are controlled by `GameScene:handleElevatorInteractions()`, NOT by monster's own update methods. The monster update functions (updateEnteringElevator, updateCheckingOut, etc.) are mostly empty - they let gameScene coordinate movement and boarding.

### Elevator Behavior

- Elevator can only open doors when aligned with a floor (within 1 pixel)
- When stopped within 5 pixels of a floor for ~0.33 seconds, elevator auto-snaps to alignment
- Cannot move while doors are open or animating
- Passengers (monsters) move with elevator via `Elevator:moveByDelta()`

### Game Systems

- **TimeSystem**: Day/night cycle (5 real minutes = 21 game hours, 5am-2am)
- **SpawnSystem**: Monster spawning based on time-of-day probability
- **EconomySystem**: Money management, damage costs, room payments
- **SaveSystem**: Uses `playdate.datastore` for 3 save slots + persistent unlockables
- **UnlockSystem**: Tracks achievements that persist across games

### Data-Driven Design

Game constants in `globals.lua`. Entity stats defined in `source/data/`:
- `monsterData.lua` - Monster types with patience, damage, speed
- `roomData.lua` - Room costs and patience modifiers
- `elevatorData.lua` / `lobbyData.lua` - Level-based upgrades

### Sprite Assets

Assets sourced from HauntedHotel pack in `available-assets/`. Converted to 1-bit for Playdate in `source/images/`. Use Playdate image table naming: `name-table-WW-HH.png` for animated sprites.

ImageMagick conversion command:
```bash
magick [input] -fuzz 30% -fill white -opaque "#1a1a2e" -fuzz 30% -fill white -opaque "#16213e" \
  -fuzz 30% -fill white -opaque "#0f0f23" -colorspace Gray -threshold 80% -depth 1 -type Bilevel [output]
```

## Key Playdate SDK Notes (v3.0.2)

- Use `gfx.fillCircleAtPoint()` / `gfx.drawCircleAtPoint()` (not `fillCircle`)
- No standard Lua `os` library - use `playdate.getTime()` for timestamps
- Crank input via `playdate.getCrankChange()` in `playdate.cranked(change, acceleratedChange)` callback
- Save data via `playdate.datastore.write(data, filename)` / `playdate.datastore.read(filename)`
- Use `local gfx <const> = playdate.graphics` pattern for performance (avoids repeated table lookups)
- Implement `playdate.gameWillTerminate()` and `playdate.deviceWillSleep()` to auto-save
- **Simulator runs faster than hardware** - test on actual Playdate device frequently
- `gfx.setDrawOffset()` persists across frames - always reset when switching scenes
- This game uses manual drawing, not the sprite system (simpler coordinate handling)

## Game Design Reference

Full GDD in `Monster Hotel.md` includes:
- Hotel leveling thresholds and floor generation tables
- Monster/Room/Elevator data tables
- Operating cost formulas
- Unlockable challenges and effects
