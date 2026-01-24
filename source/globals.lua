-- Monster Hotel - Global Constants and Base Values
-- All values from the Game Design Document

-- Screen dimensions
SCREEN_WIDTH = 400
SCREEN_HEIGHT = 240

-- Gameplay base values
HOTEL_START_LEVEL = 1
HOTEL_START_MONEY = 1000
BASE_MONSTER_SPEED = 4
BASE_ELEVATOR_SPEED = 4

-- Time system
TIME_SCALE = 7.15           -- Real seconds per game hour (~2.5 min day cycle)
GAME_TICK_RATE = 30         -- Game updates per real second (Playdate refresh rate)
TICKS_PER_HOUR = TIME_SCALE * GAME_TICK_RATE
DAY_START_HOUR = 8          -- 8am (start of morning checkout period)
DAY_END_HOUR = 26           -- 2am next day
MORNING_END_HOUR = 12       -- Noon - checkout time ends

-- Spawning
SPAWN_CHECK_INTERVAL = 5000 -- 5 seconds in milliseconds
BASE_SPAWN_CHANCE = 50      -- Base percentage chance
NIGHT_SPAWN_REDUCTION = 0.5 -- After 9pm, spawn rate halved
NIGHT_START_HOUR = 21       -- 9pm
MORNING_SPAWN_RATE = 0.1    -- 10% spawn rate in morning

-- Floor dimensions
FLOOR_HEIGHT = 91           -- Pixels per floor (91px to show 2 floors at a time)
ROOMS_PER_FLOOR = 4         -- Standard guest floor has 4 rooms

-- Elevator
ELEVATOR_WIDTH = 61         -- Width of elevator door sprite
ELEVATOR_HEIGHT = 91        -- Height matches floor height
ELEVATOR_SHAFT_WIDTH = 56   -- Width of elevator shaft sprite
ELEVATOR_X = (SCREEN_WIDTH - ELEVATOR_WIDTH) / 2  -- Centered

-- Monster movement
MONSTER_TILE_SIZE = 8       -- Base movement speed in pixels (reduced from 16)
MONSTER_MOVE_TICKS = 3      -- Move every 3 game ticks (slower)

-- Z-Index layers for sprite ordering
Z_BACKGROUND = 0
Z_FLOOR_DECOR = 100
Z_DOORS = 150
Z_MONSTERS = 200
Z_ELEVATOR = 300
Z_UI_OVERLAY = 400
Z_ROOM_MARKERS = 500

-- Room types
ROOM_TYPE = {
    SINGLE = "SINGLE",
    DOUBLE = "DOUBLE",
    SUITE = "SUITE",
    CAFE = "CAFE",
    CONFERENCE = "CONFERENCE",
    BALLROOM = "BALLROOM"
}

-- Room categories
ROOM_CATEGORY = {
    GUEST = "GUEST",
    SERVICE = "SERVICE"
}

-- Floor types
FLOOR_TYPE = {
    LOBBY = "LOBBY",
    GUEST = "GUEST",
    CONFERENCE = "CONFERENCE",
    BALLROOM = "BALLROOM",
    CAFE = "CAFE"
}

-- Booking status
BOOKING_STATUS = {
    AVAILABLE = "AVAILABLE",
    OCCUPIED = "OCCUPIED"
}

-- Monster states
MONSTER_STATE = {
    WAITING_IN_LOBBY = 1,
    ENTERING_ELEVATOR = 2,
    RIDING_ELEVATOR = 3,
    EXITING_TO_ROOM = 4,
    IN_ROOM = 5,
    WAITING_TO_CHECKOUT = 6,
    CHECKING_OUT = 7,
    RAGING = 8,
    EXITING_HOTEL = 9
}

-- Patience indicator thresholds (percentage of base patience consumed)
PATIENCE_WARN_1 = 0.50      -- Show 1 exclamation point
PATIENCE_WARN_2 = 0.70      -- Show 2 exclamation points
PATIENCE_WARN_3 = 0.90      -- Show 3 exclamation points

-- Hotel leveling thresholds (from GDD)
HOTEL_LEVEL_THRESHOLDS = {
    [1] = 1000,
    [2] = 1500,
    [3] = 2500,
    [4] = 4000,
    [5] = 5500,
    [6] = 7000,
    [7] = 10000,
    [8] = 12000,
    [9] = 15000,
    [10] = 19000,
    [11] = 25000,
    [12] = 30000,
    [13] = 35000,
    [14] = 40000,
    [15] = 50000
}

-- Level 15+ formula: MoneyRequiredToLevelUp = Level x 5000
LEVEL_UP_MULTIPLIER = 5000

-- Unlockable effect types
UNLOCKABLE_TYPE = {
    PATIENCE = "PATIENCE",
    COST = "COST"
}
