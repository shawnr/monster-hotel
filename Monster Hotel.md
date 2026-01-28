# Monster Hotel

## Play.date game

This is a rogue-like hotel elevator game.

# Concept

Players control the elevator that goes through the middle of the Monster hotel. They use the crank to move the elevator up and down and the button to open/close the doors. As monsters come into the hotel, they are assigned a room in the hotel. An icon that matches the monster’s icon appears on the door of one of the rooms. The player must pick the monsters up in the elevator, then crank to the level with their room and let them out. The player can pick up more than one monster (number depending on level of game), and must strategize to get all the monsters to their rooms before they get angry and freak out. When they freak out they do go into a rage and storm out. Enraged Monsters cause damage to the hotel and that costs money. The goal is to keep the Hotel running.

# Graphics

Play.date graphics are 1 bit.

The game will be 2D like a side-scroller, tho it will scroll up and down instead of left and right.

# Base Gameplay loop

* The game initializes with a view of a two floor monster hotel: the lobby at the bottom and one guest floor above. The elevator goes up the middle of it. The lobby is a holding area for new monsters, and it has a max limit. The player starts with a sum of $1000
* The game plays out on day long loops: Day 1 starts at noon for faster action; subsequent days start at 8am and end at 2am.
  * At the beginning of each loop, the cost of running the hotel is removed from the hotel's money (this amount scales with the gameplay)
* New monsters come spawn according to this formula:: CHANCE\_TO\_SPAWN\_NEW\_MONSTER \= 50 \+ current time of day (hours)
  * If it is around noon in the game day, there would be a (50+12)% chance of a monster spawning. At 5pm the chance of a monster spawning would be (50+17)%
  * After the game day equivalent of 9pm (21:00) all monster spawning will be cut in half
  * The spawn chance is rolled once every 5 seconds of real time (equivalent to ~1 game hour)
  * Each roll that succeeds spawns exactly one monster
* Different monsters have different levels of patience, which means some need to get to their rooms faster than others.
* When a new monster comes in, an empty room is tagged with that monster's icon.
  * Monsters ONLY spawn when there is at least one available room
* The player opens the door to the elevator
* The monsters waiting get on (up to the current elevator limit) board the elevator
* The player closes the door and cranks the elevator to the floor matching where the monster needs to go
* The player opens the door and lets the monster out
* The player repeats the pattern of opening/closing the door and cranking to floors where monsters need to go, picking up new monsters from the lobby as often as possible
* Monsters make their way to their room and disappear for a period of time, then they exit the room and move to the elevator where they wait for a ride down to the lobby
  * The Monster will always stay in their room until the next Day cycle
  * The Monster will check out at a random time between 8am and noon in the game day
  * The first monster to check out each day always exits at 8am sharp to ensure early morning activity
* If a monster runs out of patience before they have gotten to their room, they will go into a rage and storm out of the hotel. This will do damage to the hotel in an amount based on the monster and level of the hotel. The damage will result in money being subtracted from the Hotel's account.
* Once a monster returns to the lobby and exits the hotel, the cost of their room is added to the hotel's sum of money
* As the player succeeds and moves up in the the gameplay additional floors are added to the hotel, and specialty floors such as conference and ballrooms are added
  * When the Hotel levels up, the game pauses and shows a congratulatory notification displaying the new level and any upgrades (elevator, lobby capacity, new floors)
  * New floors fade in at the TOP of the hotel with a visual animation
* There is no top end to the game; the player can keep playing and adding new floors to the hotel as long as they can satisfy the monsters
* At the end of each day, the Hotel Operating Costs are calculated. The formula for this is under Hotel Game System section
* The Hotel Operating Costs are subtracted from the amount of money in the Hotel Account (the player sees this happen on-screen and can see the results)
* If the hotel has no money left, the game is over
* If the hotel still has money, the player can press any button to start the next day (that should be indicated on the screen)

# Meta Gameplay Loop

The gameplay could go on forever to endless levels. Achieving different goals in the game will unlock different permanent game upgrades. These are known as Unlockable Items. When the game starts, these items are not a part of it. Each item unlocks based on a different challenge or achievement.

1. No unlockables available  
2. Player plays game and completes one of the challenges  
3. Unlockable becomes unlocked

# Hotel Design

The hotel starts out with a two floor design: the lobby at the bottom and one guest floor above. 

The bottom floor is always the Lobby. The Lobby can contain LOBBY\_MONSTER\_CAPACITY number of monsters, where LOBBY\_MONSTER\_CAPACITY  is part of the Lobby object data defined in the game.

The floors above are created semi-randomly as the game progresses. First, the floors above the Lobby are simply Guest Floors. There are 4 doors on each Floor, indicating 4 rooms. The floors are decorated with Accessories between the doors to make them look more interesting.

The Elevator is a column in the center of the screen. The Elevator can hold ELEVATOR\_MONSTER\_CAPACITY, which comes from the data properties that define each specific type of Elevator.

The Lobby and Elevator are leveled up in the game according to how much money is earned. Each type of Lobby and Elevator are defined as data objects with a set of properties that describe them including: name, description, monster capacity, and background image, etc.

# Game Data

Monster Hotel will make use of several core game data objects.

1. Hotel (Object)  
   1. Lobby (Object)  
   2. Elevator (Object)  
   3. Floors (object)  
   4. Money (object)  
   5. Day (Object)  
   6. Money  
   7. Level  
   8. DayCount  
2. Monster (Object)  
   1. Name  
   2. Description  
   3. Icon  
   4. TimeSpent \# How much time this monster has spent commuting to its room  
   5. Speed \# How fast this monster moves (multiplier)  
   6. CurrentPatience \# The current patience level of this monster at this time  
   7. BasePatience modifier \# How naturally patient or impatient they are (this is an integer that will be modified by the Patience modifiers)  
   8. BaseDamage \# The base cost of damage caused when this monster rages out  
   9. Minimum hotel level \# The lowest level of hotel they will stay at  
3. Floor (Object)  
   1. Level  
   2. Type (GUEST, CONFERENCE, BALLROOM, CAFE)  
   3. Number of Rooms  
4. Room (Object)  
   1. Number  
   2. Type (SINGLE, DOUBLE, SUITE, CONFERENCE, BALLROOM)  
   3. Capacity  
   4. Booking status (Available, Occupied)  
   5. Cost \# How much money this room earns when it is booked  
   6. Patience modifier \# How does this room affect the Monster’s patience (this is a multiplier)  
5. Elevator (Object)  
   1. Name  
   2. Capacity  
   3. Speed \# How fast does the elevator move up and down (this is a multiplier)  
   4. Patience modifier \# How does this elevator affect the Monster’s patience (this is a multiplier)  
6. Lobby (Object)  
   1. Name  
   2. Capacity  
   3. Patience modifier \# How does this lobby affect the Monster’s patience (this is a multiplier)  
7. GameSave (Object)  
   1. Hotel  
   2. Array of floor objects  
   3. Array of existing monster objects  
   4. Array of room objects  
   5. Elevator  
   6. Lobby  
   7. All other game data not stored in these objects represented as JSON  
   8. savedAt \# timestamp of last time gamedata was saved to storage  
8. UnlockablesSave (Object) \# Saved across all games, only one data object per Play.date  
   1. List of Unlockables that have been earned on this Play.date

# Game Systems

## Base Values

1. HOTEL\_START\_LEVEL=1
2. HOTEL\_START\_MONEY=1000
3. BASE\_MONSTER\_SPEED=4
4. BASE\_ELEVATOR\_SPEED=4
5. TIME\_SCALE=7.15 # Real seconds per game hour (~2.5 real min day cycle)
6. GAME\_TICK\_RATE=30 # Game updates per real second (matches Playdate refresh rate)
7. DAY\_START\_HOUR=8 # 8am - start of morning checkout period
8. DAY\_END\_HOUR=26 # 2am next day (expressed as 24+2)
9. MORNING\_END\_HOUR=12 # Noon - checkout time ends
10. BASE\_SPAWN\_CHANCE=50 # Base percentage chance to spawn
11. MORNING\_SPAWN\_RATE=0.1 # 10% spawn rate in morning

## Hotel

The hotel manages the game loop of time and events. These are the rules and requirements:

1. One day in the game equals approximately 2.5 min of real time.
2. Day 1 starts at noon to get into the action faster. Subsequent days start at 8am and end at 2am.
3. At the beginning of the day, these things happen:
   1. Starts on a black screen that has the day count (eg "Day 1")
   2. Fades in to hotel
4. Morning period (8am to noon):
   1. All monsters currently in rooms will check out during this period
   2. The first monster always checks out at exactly 8am to ensure early activity
   3. Other monsters check out at random times between 8am and 11am
   4. Monster spawn rate is reduced to 10% during morning
5. Afternoon/Evening period (noon to 2am):
   1. Monsters spawn at normal rate (reduced by 50% after 9pm)
   2. If there are no monsters in the Lobby, a monster will spawn if there are any available Rooms
   3. If the Lobby is at Capacity, or ALL of the rooms are occupied, then no new monsters will spawn
6. At the end of the day these things happen:
   1. The screen transitions to the Day End summary screen
   2. The summary shows: guests checked in, guests checked out, monsters raged
   3. Financial summary shows: room earnings, operating costs, rage damage, net change, and final balance
   4. The game offers a "press A to continue" for the player so they don't miss the information presented
   5. After pressing a button the day cycle starts again
   6. If the Hotel's Account balance is zero or a negative number at the end of a day, then the game is over

## Elevator

The elevator is the only object the user directly interacts with in the game. It follows these rules:

1. The Elevator moves along a vertical axis based on the player’s input  
   1. The Crank is the primary way the player controls the elevator  
   2. Up and down on the D-Pad are provided as alternative inputs to control the elevator  
2. The elevator moves according to the direction the user cranks/presses  
3. The elevator speed is derived:  BASE\_ELEVATOR\_SPEED x Elevator.speed \= Actual elevator speed  
4. The user can press A, B, L (left), or R (right) buttons to open/close the elevator doors
   1. Monsters will not enter/exit the elevator unless the door is open  
5. The elevator capacity is the total number of monsters who can ride the elevator at once
   1. When the elevator hits capacity no more Monsters will enter

## Camera and Scrolling

The camera follows these rules:

1. The camera is vertically centered on the Elevator at all times
2. The camera scrolls smoothly as the elevator moves up and down
3. The Lobby floor is always visible at the bottom when the elevator is on floors 1-2
4. When the elevator is at the top floor, the camera stops scrolling and the top of the hotel is visible
5. The Playdate screen is 400x240 pixels. Each floor is 91 pixels tall, allowing approximately 2 floors to be visible at once
6. The elevator shaft runs vertically through the center of the screen (X position fixed)

## Monster Behavior

Monsters are the NPCs in the game. They move on their own and mimic a schedule of their own following these rules and requirements:

1. An instance of a Monster is spawned at the entrance of the hotel lobby  
   1. The spawning logic will randomly choose from Monsters with Minimum Hotel Level values at or below the current Hotel Level  
   2. The Monster will be assigned a room  
   3. The room the Monster has been assigned will be labeled with the monster's icon placed over the door
      1. If the floor is not fully visible (less than 80% on screen), a pointer bubble appears at the edge of the screen
         1. The bubble points up or down depending on whether the floor is above or below the current view
         2. Bubbles appear even when a small part of the floor is visible, helping players track off-screen activity
         3. Bubbles show for: monsters in elevator (pointing to destination), monsters waiting in lobby, monsters waiting to checkout, monsters on service floors
2. The Monster will walk to the Elevator and wait for doors to open.
   1. The monster moves (MONSTER\_TILE\_SIZE + Monster.speed) pixels per 3 game ticks (MONSTER\_MOVE\_TICKS)  
3. The Monster will ride the elevator up to the floor with its room  
4. The Monster will exit when the doors are open and move towards its assigned room  
5. When the Monster arrives at the door of the room, they will enter the room.  
6. The monster icon on the Room door will be replaced with a Hotel standard “Occupied” label  
7. On the next day cycle, Monsters that have stayed in rooms will exit at random times between 8am and noon. The first monster always checks out at exactly 8am. When they exit their room, they will make their way to the elevator doors on their floor.   
8. When the elevator arrives and the player opens the doors, the Monsters will enter, ride down to the Lobby, then exit the elevator and exit the hotel lobby, completing their stay  
9. When a monster has left the Hotel the amount of money their room cost is added to the Hotel Account immediately  
10. A Monster's Calculated Amount of Patience is derived: Calculated Patience = Monster.BasePatience + Lobby.patienceModifier + Elevator.patienceModifier + Room.patienceModifier + UnlockablePatience - timeSpent
    1. This is an ADDITIVE formula - each point of modifier adds 1 second of patience  
11. Monster.timeSpent follows these rules and requirements:  
    1. timeSpent is reset when the monster enters the Hotel AND when the monster exits its room  
    2. timeSpent is counted in seconds of game time  
12. If Calculated Patience is less than 0, then the Monster goes into a rage  
    1. A raging monster storms out of the hotel with a rage indicator graphic around it  
    2. A raging monster will cause a damage cost equal to Monster.BaseDamageCost \+ Monster.timeSpent x Hotel.level  
    3. The damage cost is subtracted from the hotel’s Account immediately  
13. The player can see monsters that are becoming impatient. They will indicate three stages:  
    1. If Calculated Patience is 50% of BasePatience, show ONE exclamation point above the monster’s sprite  
    2. If Calculated Patience is 70% of BasePatience, show TWO exclamation points above the monster’s sprite  
    3. If Calculated Patience is 90% of BasePatience, show THREE exclamation point above the monster’s sprite  
14. When the lobby hits max capacity, or no Rooms are available, new monsters stop spawning

## Hotel Leveling

The Hotel levels up according to the Hotel Leveling Table.

Hotel level is determined by the Hotel's **current account balance** (not lifetime earnings). This means:
- If the player earns $1000, they hit Level 4 and a new floor spawns
- If damage costs reduce them to $900, they remain Level 4 (levels don't decrease)
- The hotel only levels UP, never down, even if money drops below previous thresholds

Hotel Leveling Table

| Money | Level |
| :---- | :---- |
| 1000 | 1 |
| 1500 | 2 |
| 2500 | 3 |
| 4000 | 4 |
| 5500 | 5 |
| 7000 | 6 |
| 10000 | 7 |
| 12000 | 8 |
| 15000 | 9 |
| 19000 | 10 |
| 25000 | 11 |
| 30000 | 12 |
| 35000 | 13 |
| 40000 | 14 |
| 50000 | 15 |

When the Hotel hits level 15 it will gain levels using this formula:

MoneyRequiredToLevelUp \= Level x 5000

The Hotel can continue leveling infinitely until the game hits an end condition (Hotel runs out of money).

When the Hotel levels up:
1. The game pauses and displays a Level Up notification
2. The notification shows the new level and any upgrades:
   - Elevator upgrade (name and new capacity) if applicable
   - Lobby capacity increase if applicable
   - Number of new floors being added
3. Player presses A or B to dismiss the notification and resume gameplay
4. New floors are added at the TOP of the hotel and fade in with a visual animation

Floor Generation Table

| Level | Number of floors to spawn | Available Types |
| :---- | :---- | :---- |
| 1 | 1 | SINGLE, DOUBLE |
| 2 | 1 | SINGLE, DOUBLE |
| 3 | 1 | SINGLE, DOUBLE, SUITE |
| 4 | 1 | SINGLE, DOUBLE, SUITE |
| 5 | 2 | SINGLE, DOUBLE, SUITE, CAFE  |
| 6 | 1 | SINGLE, DOUBLE, SUITE, CAFE  |
| 7 | 2 | SINGLE, DOUBLE, SUITE, CAFE |
| 8 | 1 | SINGLE, DOUBLE, SUITE, CAFE |
| 9 | 1 | SINGLE, DOUBLE, SUITE, CAFE |
| 10 | 2 | SINGLE, DOUBLE, SUITE, CAFE, CONFERENCE |
| 11 | 1 | SINGLE, DOUBLE, SUITE, CAFE, CONFERENCE |
| 12 | 1 | SINGLE, DOUBLE, SUITE, CAFE, CONFERENCE |
| 13 | 1 | SINGLE, DOUBLE, SUITE, CAFE, CONFERENCE |
| 14 | 1 | SINGLE, DOUBLE, SUITE, CAFE, CONFERENCE |
| 15 | 2 | SINGLE, DOUBLE, SUITE, CAFE, CONFERENCE, BALLROOM |

### Generation New Floor Process

1. When the Hotel hits a new level the Floor Generation Table is consulted to determine the number of Floors to spawn and what types of Rooms can be on the new Floor(s)  
   1. Each floor supports four rooms  
   2. Each room is assigned a type randomly selected from the list of available Floor types for that level  
   3. If the new level contains a new type of Room, then the first Room placed on that level will be that type. (eg. When the Hotel hits level 5, the new value SUITE is in the list of Available Room Types, so the first Room placed on that Floor will be a SUITE type)  
   4. If the new Floor contains a CAFE, CONFERENCE or BALLROOM, then no other Rooms can be placed on the Floor
   5. Rooms are assigned a number: floor number + "0" + room index (e.g., Floor 1 has rooms 101, 102, 103, 104)
   6. Rooms are positioned with 2 rooms on the left side of the elevator and 2 rooms on the right side

### Hotel Operating Costs Formula

DailyOperatingCost = (0.05 × TotalGuestRoomValue) + (50 × NumberOfServiceFloors) + (HotelLevel × 100)

Where:
- TotalGuestRoomValue = Sum of all Room.Cost values for GUEST rooms (SINGLE, DOUBLE, SUITE) currently in the hotel
- NumberOfServiceFloors = Count of floors that are CAFE, CONFERENCE, or BALLROOM
- HotelLevel = Current hotel level

Example at Level 5 with 8 guest rooms (4 SINGLE, 4 DOUBLE) and 0 services:
- TotalGuestRoomValue = (4 × 100) + (4 × 200) = 1200
- DailyOperatingCost = (0.05 × 1200) + (50 × 0) + (5 × 100) = 60 + 0 + 500 = $560

### Room Types Data

ROOM\_TYPES \= {  
	{name=”guestrooms”, types=\[‘SINGLE’, ‘DOUBLE’, ‘SUITE’\]},  
{name=”services”, types=\[‘CAFE’, ‘CONFERENCE’, ‘BALLROOM’\]},

### Lobby to Hotel Levels Table

| Hotel level | Patience modifier | Capacity | Operational Costs |
| :---- | :---- | :---- | :---- |
| 1 | 1 | 8 | 10 |
| 2 | 5 | 10 | 20 |
| 3 | 8 | 11 | 40 |
| 4 | 8 | 12 | 50 |
| 5 | 8 | 13 | 60 |
| 6 | 8 | 14 | 80 |
| 7 | 9 | 18 | 100 |
| 8 | 9 | 20 | 120 |
| 9 | 9 | 22 | 140 |
| 10 | 9 | 25 | 160 |
| 11 | 9 | 29 | 180 |
| 12 | 10 | 35 | 200 |
| 13 | 10 | 45 | 250 |
| 14 | 10 | 50 | 300 |
| 15 | 11 | 100 | 500 |

### Elevator to Hotel Levels Table

| Hotel Level | Name | Capacity | Speed | Patience Modifier |
| :---- | :---- | :---- | :---- | :---- |
| 1 | Rickety Lift | 2 | 1 | 0 |
| 3 | Basic Elevator | 6 | 1.2 | 2 |
| 6 | Modern Elevator | 10 | 1.5 | 5 |
| 9 | Express Elevator | 15 | 2 | 8 |
| 12 | Luxury Elevator | 20 | 2.5 | 12 |
| 15 | Haunted Express | 30 | 3 | 15 |

The Elevator automatically upgrades when the Hotel reaches the specified level. The player does not choose when to upgrade.

### Rooms Data Table

| Type | Capacity | Patience Modifier | Cost |
| :---- | :---- | :---- | :---- |
| SINGLE | 1 | CurrentHotelLevel | 100 |
| DOUBLE | 2 | 2\*CurrentHotelLevel | 200 |
| SUITE | 4 | 4\*CurrentHotelLevel | 500 |

Note: In v1.0, each room holds exactly 1 monster regardless of capacity value. Capacity is reserved for future group booking features.

### Services Data Table

| Type | Capacity | Patience Modifier | Cost |
| :---- | :---- | :---- | :---- |
| CAFE | LobbyCapacity / 2 | CurrentHotelLevel | 100 |
| CONFERENCE | LobbyCapacity / 2 | 2\*CurrentHotelLevel | 200 |
| BALLROOM | LobbyCapacity / 2 | 4\*CurrentHotelLevel | 500 |

Note: Service floor capacity scales with the lobby capacity, always at half the current lobby limit.

### Services Behavior

SERVICE floors (CAFE, CONFERENCE, BALLROOM) provide relaxation areas for monsters:

1. Take up an entire floor (no guest rooms can be placed alongside them)
2. Add to operating costs per the Hotel Operating Costs Formula
3. Have a capacity equal to half the current lobby capacity
4. Display a name label box on the left side (randomly generated names like "LoveCRAFT Beer & Grill")

**Monster Relaxation Mechanic:**
1. When the elevator doors open on a service floor, ALL non-checkout monsters exit to relax
2. Monsters walk to the right side of the floor and wait there
3. While on a service floor, monsters' patience RECHARGES (timeSpent decreases by 2 per tick)
4. Monsters must "settle" for ~2 seconds before they can reboard the elevator
5. When the elevator returns with doors open:
   - If more than 4 monsters on the floor: half will board
   - If 4 or fewer monsters: all will board
6. Monsters who have visited a service floor won't exit again on subsequent service floors during the same trip

**Day End Behavior:**
- Any monsters still on service floors at day end will rage out
- This prevents monsters from "hiding" on service floors indefinitely

### Monster Data Table

| Name | Description | Speed | Base Patience | Base Damage Cost | Min Hotel Level |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Evil Robot | A malicious android. | 2 | 10 | 10 | 1 |
| Flesheating Plant | A carnivorous vegetable. | 1 | 11 | 20 | 1 |
| Spider | An arachnid of concern. | 3 | 7 | 30 | 5 |
| Giant Slug | Slow but deadly. | 1 | 12 | 40 | 10 |
| Undercover Alien | Alien spy still wearing a human disguise. | 3 | 8 | 60 | 15 |

Note: Base Patience is measured in seconds of game time. Speed is added to the base tile movement.

## In-Game Messages

The game displays overlay messages at key moments to guide the player:

| Trigger | Message | Behavior |
| :---- | :---- | :---- |
| Game starts/restarts | "Get the monsters to their rooms!" | Shows every time, center screen |
| First time doors toggled | "Use A,B,L or R to open/close doors." | Shows only once (persisted) |
| Service floor added | "Service floor added - enhances monster relaxation!" | Shows every time, center screen |
| Monster rages | "Monster Rage!" | Shows on right side, floats up and fades, stacks if multiple |

Messages display as bold black text with white stroke outline for visibility. Center messages show for 3 seconds then fade for 1 second. Rage messages show for 1.5 seconds then float upward while fading.

# Meta Game Interaction Sequence

1. Starting screen shows title graphic, crank call to action (default play.date component), and says “press any button” to start playing  
2. If there is saved game data, the user is brought to the continue or new screen where they can choose to continue a saved game, view unlockables or start a new game.   
3. Unlockables are items that are unlocked during gameplay session, but which remain unlocked forever  
   1. These items affect the calculation of certain statistics in the game  
   2. Once earned, these items do not need to be purchased or earned in the game – their effect will be calculated during any subsequent gameplay sessions  
4. There are three game save slots. If the player decides to continue, then they will be shown the three saved game slots and can choose one to start again (game saves are labeled with the last timestamp they were updated)  
5. If the player selected New, a New game is started  
6. If they selected their game to continue, the saved game is reloaded using the saved data and the game continues from where they left off  
7. During the game, if the player presses start or select buttons a Pause menu will show up and the game will pause  
   1. Pause menu will offer these options:  
      1. Save game  
      2. Return to Main Screen  
      3. Quit Game  
8. Games will be automatically saved at the end of each Day cycle in the game

## Unlockable Item Challenges

| Item | Challenge | Type | Effect |
| :---- | :---- | :---- | :---- |
| Paintings in Lobby | Earn at least $1000 in one game | PATIENCE | +10 |
| Fountain | Earn at least $2000 in one game | COST | +40 |
| Nicer Showers | Earn at least $3000 in one game | COST | +50 |
| Elevator Muzak | Serve at least 30 guests in one game | PATIENCE | +20 |
| Bellhop Bot | Reach Hotel Level 5 | PATIENCE | +15 |
| Complimentary Mints | Survive 10 days | COST | +25 |
| Haunted Chandelier | Have 5 monsters rage out in one game | PATIENCE | +30 |
| Monster Loyalty Card | Serve 100 total guests (lifetime) | COST | +100 |
| Spooky Welcome Mat | Start a new game 3 times | PATIENCE | +5 |
| Coffin Beds | Reach Hotel Level 10 | COST | +75 |

Unlockable items are not like the other game objects. These are earned by completing a challenge and earning them persists across game sessions. They automatically affect the calculations during gameplay.

PATIENCE items provide a boost to all PATIENCE calculations. This boost always works in favor of the player by making monsters more patient. This Patience effect will be added to the Calculated Patience before timeSpent is subtracted.

COST items add to the earned cost of each Room at the time the Monster exits the hotel. These items make the hotel more luxurious so the player can charge a higher rate. The Cost amount is added to the amount the player earns when a Monster exits.

