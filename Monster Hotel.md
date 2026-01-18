# Monster Hotel

## Play.date game

This is a rogue-like hotel elevator game.

# Concept

Players control the elevator that goes through the middle of the Monster hotel. They use the crank to move the elevator up and down and the button to open/close the doors. As monsters come into the hotel, they are assigned a room in the hotel. An icon that matches the monster’s icon appears on the door of one of the rooms. The player must pick the monsters up in the elevator, then crank to the level with their room and let them out. The player can pick up more than one monster (number depending on level of game), and must strategize to get all the monsters to their rooms before they get angry and freak out. When they freak out they do go into a rage and storm out. Enraged Monsters cause damage to the hotel and that costs money. The goal is to keep the Hotel running.

# Graphics

Play.date graphics are 1 bit.

The game will be 2D like a side-scroller, tho it will scroll up and down instead of left and right.

# Base Gameplay loop

* The game initializes with a view of a two floor monster hotel. The elevator goes up the middle of it. On the first floor are the front desk and lobby. It is a holding area for new monsters, and it has a max limit. The player starts with a sum of $1000  
* The game plays out on day long loops: Starting at sunrise and going into late night.  
  * At the beginning of each loop, the cost of running the hotel is removed from the hotel’s money (this amount scales with the gameplay)  
* New monsters come spawn according to this formula:: CHANCE\_TO\_SPAWN\_NEW\_MONSTER \= 50 \+ current time of day (hours)  
  * If it is around noon in the game day, there would be a (50+12)% chance of a monster spawning. At 5pm the chance of a monster spawning would be (50+17)%  
  * After the game day equivalent of 9pm (21:00) all monster spawning will be cut in half
  * The spawn chance is rolled once every 5 seconds of real time (equivalent to ~1 game hour)
  * Each roll that succeeds spawns exactly one monster
* Different monsters have different levels of patience, which means some need to get to their rooms faster than others.  
* When a new monster comes in, an empty room is tagged with that monster’s icon.  
  * Monsters ONLY spawn when there is at least one available room  
* The player opens the door to the elevator  
* The monsters waiting get on (up to the current elevator limit) board the elevator  
* The player closes the door and cranks the elevator to the floor matching where the monster needs to go  
* The player opens the door and lets the monster out  
* The player repeats the pattern of opening/closing the door and cranking to floors where monsters need to go, picking up new monsters from the lobby as often as possible  
* Monsters make their way to their room and disappear for a period of time, then they exit the room and move to the elevator where they wait for a ride down to the lobby  
  * The Monster will always stay in their room until the next Day cycle  
  * The Monster will check out at a random time between 5am and noon in the game day  
* If a monster runs out of patience before they have gotten to their room, they will go into a rage and storm out of the hotel. This will do damage to the hotel in an amount based on the monster and level of the hotel. The damage will result in money being subtracted from the Hotel’s account.  
* Once a monster returns to the lobby and exits the hotel, the cost of their room is added to the hotel’s sum of money  
* As the player succeeds and moves up in the the gameplay additional floors are added to the hotel, and specialty floors such as conference and ballrooms are added  
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

The hotel starts out with a two floor design. 

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
2. BASE\_MONSTER\_SPEED=4
3. BASE\_ELEVATOR\_SPEED=4
4. TIME\_SCALE=14.3 # Real seconds per game hour (5 real min = 21 game hours from 5am to 2am)
5. GAME\_TICK\_RATE=30 # Game updates per real second (matches Playdate refresh rate)

## Hotel

The hotel manages the game loop of time and events. These are the rules and requirements:

1. One day in the game equals 5 min of real time.  
2. In the game, the day starts at 5am and ends at 2am.   
3. At the beginning of the day, these things happen:  
   1. Starts on a black screen that has the day count (eg “Day 1”)  
   2. Fades in to hotel  
4. In the first half of the day, all of the Monsters currently in rooms will exit the hotel before noon and the rate of Monster generation will only be 10% for Monsters coming in to get rooms  
5. In the second half of the day, Monsters are all coming to stay at the normal spawn rate  
   1. If there are no monsters in the Lobby, a monster will spawn if there are any available Rooms  
   2. If the Lobby is at Capacity, or ALL of the rooms are occupied, then no new monsters will spawn  
6. At the end of the day these things happen:  
   1. The screen fades to black  
   2. The Hotel’s Account balance is updated based on that day’s earnings  
   3. The game offers a “press any button to continue” for the player so they don’t miss the information presented  
   4. After pressing a button the day cycle starts again.  
   5. If the Hotel’s Account balance is zero or a negative number at the end of a day, then the game is over

## Elevator

The elevator is the only object the user directly interacts with in the game. It follows these rules:

1. The Elevator moves along a vertical axis based on the player’s input  
   1. The Crank is the primary way the player controls the elevator  
   2. Up and down on the D-Pad are provided as alternative inputs to control the elevator  
2. The elevator moves according to the direction the user cranks/presses  
3. The elevator speed is derived:  BASE\_ELEVATOR\_SPEED x Elevator.speed \= Actual elevator speed  
4. The user can press A or B button to open the elevator doors  
   1. Monsters will not enter/exit the elevator unless the door is open  
5. The elevator capacity is the total number of monsters who can ride the elevator at once
   1. When the elevator hits capacity no more Monsters will enter

## Camera and Scrolling

The camera follows these rules:

1. The camera is vertically centered on the Elevator at all times
2. The camera scrolls smoothly as the elevator moves up and down
3. The Lobby floor is always visible at the bottom when the elevator is on floors 1-2
4. When the elevator is at the top floor, the camera stops scrolling and the top of the hotel is visible
5. The Playdate screen is 400x240 pixels. Each floor is 60 pixels tall, allowing approximately 4 floors to be visible at once
6. The elevator shaft runs vertically through the center of the screen (X position fixed)

## Monster Behavior

Monsters are the NPCs in the game. They move on their own and mimic a schedule of their own following these rules and requirements:

1. An instance of a Monster is spawned at the entrance of the hotel lobby  
   1. The spawning logic will randomly choose from Monsters with Minimum Hotel Level values at or below the current Hotel Level  
   2. The Monster will be assigned a room  
   3. The room the Monster has been assigned will be labeled with the monster’s icon placed over the door  
      1. If the floor with the Monster’s room is not currently visible, the Monster icon will hover at the top of the screen.   
         1. The Monster icon will be placed at the same X value as the room door  
         2. The Y value of the Monster icon will keep it in view at the top or bottom of the screen, depending on the location of their room relative to the current screen’s vertical scroll location  
2. The Monster will walk to the Elevator and wait for doors to open.  
   1. The monster moves (one tile+Monster.speed) per 2 game ticks  
3. The Monster will ride the elevator up to the floor with its room  
4. The Monster will exit when the doors are open and move towards its assigned room  
5. When the Monster arrives at the door of the room, they will enter the room.  
6. The monster icon on the Room door will be replaced with a Hotel standard “Occupied” label  
7. On the next day cycle, Monsters that have stayed in rooms will exit at random times between 5am and noon. When they exit their room, they will make their way to the elevator doors on their floor.   
8. When the elevator arrives and the player opens the doors, the Monsters will enter, ride down to the Lobby, then exit the elevator and exit the hotel lobby, completing their stay  
9. When a monster has left the Hotel the amount of money their room cost is added to the Hotel Account immediately  
10. A Monster’s Calculated Amount of Patience is derived: Calculated Patience \= (Room.patience \+ Lobby.patience \+ Elevator.patience) x Monster.BasePatience \- Monster.timeSpent  
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
| 0 | 1 |
| 100 | 2 |
| 400 | 3 |
| 1000 | 4 |
| 1500 | 5 |
| 2100 | 6 |
| 2700 | 7 |
| 3600 | 8 |
| 5000 | 9 |
| 7000 | 10 |
| 10000 | 11 |
| 15000 | 12 |
| 20000 | 13 |
| 24000 | 14 |
| 30000 | 15 |

When the Hotel hits level 15 it will gain levels using this formula:

MoneyRequiredToLevelUp \= Level x 2000

The Hotel can continue leveling infinitely until the game hits an end condition (Hotel runs out of money).

When the Hotel levels up a new floor is added to top of the hotel according to the Floor Generation Chart.

Floor Generation Table

| Level | Number of floors to spawn | Available Types |
| :---- | :---- | :---- |
| 1 | 1 | SINGLE, DOUBLE |
| 2 | 1 | SINGLE, DOUBLE |
| 3 | 1 | SINGLE, DOUBLE |
| 4 | 1 | SINGLE, DOUBLE |
| 5 | 2 | SINGLE, DOUBLE, SUITE |
| 6 | 1 | SINGLE, DOUBLE, SUITE |
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
   5. Rooms are assigned a number:  
      1. The first number of the room is the floor number  
      2. The following number(s) of the room is randomly selected from (10-20)   
   6. Rooms are placed in order of their room number with the highest number being the furthest Left door and spreading out from there.

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
| 3 | Basic Elevator | 3 | 1.2 | 2 |
| 6 | Modern Elevator | 4 | 1.5 | 5 |
| 9 | Express Elevator | 5 | 2 | 8 |
| 12 | Luxury Elevator | 6 | 2.5 | 12 |
| 15 | Haunted Express | 8 | 3 | 15 |

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
| CAFE | 20 | CurrentHotelLevel | 100 |
| CONFERENCE | 40 | 2\*CurrentHotelLevel | 200 |
| BALLROOM | 100 | 4\*CurrentHotelLevel | 500 |

### Services Behavior (v1.0)

In the initial release, SERVICE floors (CAFE, CONFERENCE, BALLROOM) are decorative only. They:
1. Take up an entire floor (no guest rooms can be placed alongside them)
2. Contribute to the hotel's visual progression and prestige
3. Add to operating costs per the Hotel Operating Costs Formula

Future versions may allow monsters to visit services for patience boosts or bonus income.

### Monster Data Table

| Name | Description | Icon | Speed | Base Patience | Base Damage Cost | Min Hotel Level |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| Ghoul | A fiend from beyond time and space. | Boss | 2 | 200 | 10 | 1 |
| Giant Eyeball | The terrifying guardian of the dungeon. | EyeGuy | 1 | 400 | 20 | 1 |
| Creeper | An unpredictable and frantic baddie. | Glitcher | 3 | 200 | 30 | 5 |
| Zombie | Undead and proud of it. | Zombie | 1 | 500 | 10 | 10 |
| Undercover Alien | Alien spy still with the fake human skin on. | Player | 2 | 500 | 50 | 15 |

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

