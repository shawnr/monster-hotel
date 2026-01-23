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
├── Floors[] (contain Rooms, support fade-in animation for new floors)
│   └── Rooms[] (SINGLE/DOUBLE/SUITE or service types)
└── Monsters[] (NPCs with state machine, manually drawn - NOT sprites)
```

**Important**: Elevator and Monster classes do NOT extend gfx.sprite. They use `class('Name').extends()` and are drawn manually by Hotel:draw(). This avoids coordinate system confusion between sprite positions and manual drawing.

### Coordinate System

- Y=0 is at the TOP of the hotel (highest floor)
- Y increases downward; lobby is at the bottom (highest Y value)
- Camera follows elevator with `gfx.setDrawOffset(0, -cameraY)`
- Each floor is 91 pixels tall (`FLOOR_HEIGHT`) - shows 2 floors at a time on screen
- Floor numbering: Floor 1 is just above lobby, higher numbers are higher floors

### Monster State Machine

Monsters progress through states defined in `globals.lua` (`MONSTER_STATE`):
```
CHECK-IN FLOW:
WAITING_IN_LOBBY → ENTERING_ELEVATOR → RIDING_ELEVATOR → EXITING_TO_ROOM → IN_ROOM

CHECK-OUT FLOW:
IN_ROOM → WAITING_TO_CHECKOUT → CHECKING_OUT → RIDING_ELEVATOR → EXITING_HOTEL
     ↑
RAGING (branches from any state when patience <= 0)
```

**Important State Tracking**:
- `monster.isCheckingOut` flag is set when monster exits room for checkout
- This flag distinguishes checkout monsters from check-in monsters in the elevator
- Check-in monsters: `room.assignedMonster == monster`
- Checkout monsters: `room.status == OCCUPIED` or `monster.isCheckingOut == true`

**State transitions are controlled by `GameScene:handleElevatorInteractions()`**, NOT by monster's own update methods. The monster update functions are mostly empty - gameScene coordinates movement and boarding.

### Elevator Behavior

- Elevator can only open doors when aligned with a floor (within 1 pixel)
- When stopped within 5 pixels of a floor for ~0.33 seconds, elevator auto-snaps to alignment
- Cannot move while doors are open or animating
- Passengers (monsters) move with elevator via `Elevator:moveByDelta()`
- `elevator.currentFloor`: 0 = lobby, 1+ = guest floors

### Room Status Flow

```
AVAILABLE (empty) → monster assigned → AVAILABLE + assignedMonster set
    ↓ (monster checks in)
OCCUPIED + occupant set + assignedMonster cleared
    ↓ (monster checks out)
AVAILABLE + occupant cleared
```

### Game Systems

- **TimeSystem**: Day/night cycle
  - Day 1 starts at noon for faster action
  - Subsequent days start at 8am (`DAY_START_HOUR`)
  - Morning checkout period: 8am-noon
  - Day ends at 2am (hour 26 internally)
  - 5 real minutes ≈ 18 game hours
- **SpawnSystem**: Monster spawning based on time-of-day probability
- **EconomySystem**: Money management, damage costs, room payments
- **SaveSystem**: Uses `playdate.datastore` for 3 save slots + persistent unlockables
- **UnlockSystem**: Tracks achievements that persist across games

### Daily Stats Tracking

Hotel tracks daily statistics reset each day:
- `hotel.dailyCheckIns` - monsters that entered their rooms
- `hotel.dailyCheckOuts` - monsters that completed checkout
- `hotel:recordCheckIn()` / `hotel:recordCheckOut()` - increment counters
- `hotel:resetDailyStats()` - called at start of each day

### Level-Up System

When hotel levels up:
1. Game pauses and shows level-up notification
2. Notification displays: new level, floors added, elevator/lobby upgrades
3. Player presses any button to continue
4. New floors are added to TOP of hotel with fade-in animation
5. `Floor.fadeAlpha` animates from 0 to 1 over ~1.5 seconds

### Data-Driven Design

Game constants in `globals.lua`. Entity stats defined in `source/data/`:
- `monsterData.lua` - Monster types with patience, damage, speed
- `roomData.lua` - Room costs and patience modifiers
- `elevatorData.lua` / `lobbyData.lua` - Level-based upgrades
- `unlockableData.lua` - Achievement definitions

### Key Global Constants

```lua
DAY_START_HOUR = 8          -- Morning starts at 8am
MORNING_END_HOUR = 12       -- Checkout period ends at noon
FLOOR_HEIGHT = 91           -- Pixels per floor (shows 2 floors at a time)
ELEVATOR_WIDTH = 61         -- Width of elevator door sprite
ELEVATOR_HEIGHT = 91        -- Height matches floor height
ELEVATOR_SHAFT_WIDTH = 56   -- Width of elevator shaft sprite
```

### Sprite Assets

Hotel-specific assets in `source/images/hotel/`:
- `floor-bg-1.png` / `floor-bg-2.png` - Guest floor backgrounds (alternate between floors)
- `lobby-bg.png` - Lobby background
- `elevator-doors-table-61-91.png` - 4-frame elevator door animation
- `elevator-shaft.png` - Elevator shaft background
- `room-door.png` - Room door sprite

Original assets in `available-assets/`. Use Playdate image table naming: `name-table-WW-HH.png` for animated sprites.

ImageMagick conversion command for 1-bit Playdate assets:
```bash
magick [input] -colorspace Gray -threshold 50% -depth 1 -type Bilevel [output]
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
- Use `gfx.setDitherPattern(alpha)` for fade effects (0 = solid, 1 = invisible)

## Common Debugging Issues

### Monsters not exiting elevator
- Check `monster.isCheckingOut` flag is set in `exitRoom()`
- Verify `elevator.currentFloor == 0` at lobby
- Ensure lobby detection: `isAtLobby` check in `handleElevatorInteractions()`

### Rooms staying occupied after checkout
- `room.status` must be set to `BOOKING_STATUS.AVAILABLE`
- `room.occupant` must be set to `nil`
- Both happen in checkout processing in `handleElevatorInteractions()`

### Level-up notification crashes
- Validate `levelUpInfo` exists and has `newLevel` before drawing
- Auto-dismiss if data is invalid

## Game Design Reference

Full GDD in `Monster Hotel.md` includes:
- Hotel leveling thresholds and floor generation tables
- Monster/Room/Elevator data tables
- Operating cost formulas
- Unlockable challenges and effects
